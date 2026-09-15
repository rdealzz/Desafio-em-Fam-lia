import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_log.dart';
import '../../models/app_user.dart';
import '../../services/activity_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/weekly_activity_strip.dart';

/// Progresso de um integrante: quanto fez, há quanto tempo, e o histórico.
///
/// Abre ao tocar num avatar do dashboard. Serve tanto para ver o próprio
/// progresso quanto para acompanhar o dos outros — o app é colaborativo, então
/// olhar o histórico do outro é incentivo, não vigilância.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  /// Lido da sessão a cada build, para o perfil acompanhar as mudanças ao vivo
  /// em vez de congelar no estado do momento em que a tela abriu.
  final String memberId;

  /// Busca explícita em vez de `firstOrNull`: essa extensão vem de
  /// `package:collection`, que o projeto não declara como dependência.
  AppUser? _findMember(SessionController session) {
    for (final member in session.members) {
      if (member.id == memberId) return member;
    }
    final current = session.user;
    return current != null && current.id == memberId ? current : null;
  }

  static Future<void> open(BuildContext context, String memberId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfileScreen(memberId: memberId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final family = session.family;

    final member = _findMember(session);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Integrante não encontrado.')),
      );
    }

    final isMe = session.user?.id == member.id;
    final vaultPoints = family?.vaultPoints ?? 0;
    final share = vaultPoints == 0
        ? 0
        : ((member.pointsThisWeek / vaultPoints) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(isMe ? 'Meu progresso' : 'Progresso de ${member.firstName}'),
      ),
      body: StreamBuilder<List<ActivityLog>>(
        stream: context.read<ActivityService>().watchUserLogs(member.id),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <ActivityLog>[];
          final loading = !snapshot.hasData && !snapshot.hasError;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ProfileHeader(member: member),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: Formatters.points(member.pointsThisWeek),
                      label: 'pontos na semana',
                      emphasis: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '$share%',
                      label: 'do cofre',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${member.currentStreak}',
                      label: 'dias seguidos',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${member.longestStreak}',
                      label: 'melhor sequência',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: Formatters.points(member.totalPoints),
                      label: 'no total',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              WeeklyActivityStrip(logs: logs),
              const SizedBox(height: 24),

              Row(
                children: [
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (logs.isNotEmpty)
                    Text(
                      '${logs.length} registros',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                const _EmptyHistory(
                  emoji: '⚠️',
                  message: 'Não consegui carregar o histórico agora.',
                )
              else if (logs.isEmpty)
                _EmptyHistory(
                  emoji: '🌱',
                  message: isMe
                      ? 'Nenhuma atividade ainda. A primeira é a mais difícil!'
                      : '${member.firstName} ainda não registrou nada.',
                )
              else
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LogTile(log: log),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.member});

  final AppUser member;

  static const Map<String, String> _roleLabels = {
    'mae': 'Mãe',
    'pai': 'Pai',
    'filho': 'Filho(a)',
    'membro': 'Integrante',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarBubble(user: member, size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                _roleLabels[member.role] ?? 'Integrante',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: member.isActiveToday
                      ? AppColors.success.withOpacity(0.12)
                      : const Color(0xFFF1EFFA),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  member.isActiveToday
                      ? '✅ já treinou hoje'
                      : '⏳ ainda não treinou hoje',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: member.isActiveToday
                        ? const Color(0xFF1B7F4C)
                        : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Número em destaque com o rótulo abaixo. Sem gráfico — é um valor só.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.icon,
    this.emphasis = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: emphasis ? AppColors.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasis
              ? AppColors.primary.withOpacity(0.25)
              : const Color(0xFFEFEDF7),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.activity[log.type.id] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEDF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            // Emoji junto da cor: a modalidade nunca é identificada só pelo tom.
            child: Text(log.type.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.type.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    Formatters.duration(log.durationMinutes),
                    if (log.steps > 0) '${Formatters.points(log.steps)} passos',
                    if (log.createdAt != null)
                      Formatters.timeAgo(log.createdAt!),
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (log.photoUrl != null && log.photoUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                log.photoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '+${Formatters.points(log.points)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.emoji, required this.message});

  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: const Color(0xFFEFEDF7)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}
