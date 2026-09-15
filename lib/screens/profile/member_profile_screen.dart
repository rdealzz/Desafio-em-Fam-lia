import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_log.dart';
import '../../models/app_user.dart';
import '../../services/activity_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/ui/activity_icons.dart';
import '../../widgets/ui/primitives.dart';
import '../../widgets/weekly_activity_strip.dart';

/// Progresso de um integrante: quanto fez, há quanto tempo, e o histórico.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  static Future<void> open(BuildContext context, String memberId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfileScreen(memberId: memberId),
      ),
    );
  }

  /// Busca explícita em vez de `firstOrNull`: essa extensão vem de
  /// `package:collection`, que o projeto não declara como dependência.
  AppUser? _achar(SessionController session) {
    for (final m in session.members) {
      if (m.id == memberId) return m;
    }
    final atual = session.user;
    return atual != null && atual.id == memberId ? atual : null;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final member = _achar(session);
    final t = Theme.of(context).textTheme;

    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Integrante não encontrado.')),
      );
    }

    final souEu = session.user?.id == member.id;
    final cofre = session.family?.vaultPoints ?? 0;
    final fatia =
        cofre == 0 ? 0 : ((member.pointsThisWeek / cofre) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(souEu ? 'Meu progresso' : member.firstName),
      ),
      body: StreamBuilder<List<ActivityLog>>(
        stream: context.read<ActivityService>().watchUserLogs(member.id),
        builder: (context, snap) {
          final logs = snap.data ?? const <ActivityLog>[];
          final carregando = !snap.hasData && !snap.hasError;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              Space.huge,
            ),
            children: [
              Row(
                children: [
                  AvatarBubble(user: member, size: 56),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.displayName, style: t.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          member.isActiveToday
                              ? 'treinou hoje'
                              : 'ainda não treinou hoje',
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),

              Surface(
                child: Row(
                  children: [
                    Expanded(
                      child: StatBlock(
                        value: Formatters.points(member.pointsThisWeek),
                        label: 'na semana',
                        accent: true,
                      ),
                    ),
                    Expanded(
                      child: StatBlock(value: '$fatia%', label: 'do cofre'),
                    ),
                    Expanded(
                      child: StatBlock(
                        value: '${member.currentStreak}',
                        suffix: 'd',
                        label: 'sequência',
                      ),
                    ),
                    Expanded(
                      child: StatBlock(
                        value: Formatters.points(member.totalPoints),
                        label: 'total',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),

              WeeklyActivityStrip(logs: logs),
              const SizedBox(height: Space.xxl),

              SectionLabel(
                'Histórico',
                trailing: logs.isEmpty
                    ? null
                    : Text('${logs.length} registros', style: t.bodySmall),
              ),

              if (carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Space.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (logs.isEmpty)
                Surface(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                  child: Center(
                    child: Text(
                      souEu
                          ? 'Nenhuma atividade ainda.'
                          : '${member.firstName} ainda não registrou nada.',
                      style: t.bodyMedium,
                    ),
                  ),
                )
              else
                Surface(
                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                  child: Column(
                    children: [
                      for (var i = 0; i < logs.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: Space.lg,
                            endIndent: Space.lg,
                          ),
                        _Registro(log: logs[i]),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Registro extends StatelessWidget {
  const _Registro({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Icon(iconForActivity(log.type), size: 19, color: p.textSecondary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.type.label, style: t.labelLarge),
                const SizedBox(height: 2),
                Text(
                  [
                    Formatters.duration(log.durationMinutes),
                    if (log.steps > 0)
                      '${Formatters.points(log.steps)} passos',
                    if (log.createdAt != null)
                      Formatters.timeAgo(log.createdAt!),
                    if (log.isOfflineSync) 'registrado offline',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          if (log.photoUrl != null && log.photoUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Image.network(
                log.photoUrl!,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                cacheWidth: 102,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: Space.md),
          ],
          Text(
            '+${Formatters.points(log.points)}',
            style: t.labelLarge?.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
