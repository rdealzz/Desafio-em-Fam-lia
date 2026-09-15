import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/feed_post.dart';
import '../../state/session_controller.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/member_status_row.dart';
import '../../widgets/pending_sync_banner.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/rewards_section.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/primitives.dart';
import '../../widgets/vault_progress_card.dart';
import '../profile/member_profile_screen.dart';

/// TELA 1 — A Casa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onRegisterActivity});

  final VoidCallback? onRegisterActivity;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final family = session.family;
    final user = session.user;
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (family == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.huge,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(family.name.toUpperCase(), style: t.labelMedium),
                      const SizedBox(height: 2),
                      Text('Olá, ${user.firstName}', style: t.headlineMedium),
                    ],
                  ),
                ),
                if (user.currentStreak > 0) _Sequencia(dias: user.currentStreak),
                const SizedBox(width: Space.sm),
                _BotaoIcone(
                  icon: context.read<ThemeController>().isDark(context)
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: 'Alternar tema',
                  onTap: () =>
                      context.read<ThemeController>().alternar(context),
                ),
                const SizedBox(width: Space.sm),
                _BotaoIcone(
                  icon: Icons.more_horiz_rounded,
                  tooltip: 'Convite e conta',
                  onTap: () => _menu(context),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),

            const PendingSyncBanner(),
            VaultProgressCard(family: family),
            const SizedBox(height: Space.lg),

            Pressable(
              onPressed: onRegisterActivity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 21),
                  SizedBox(width: Space.sm),
                  Text(
                    'Registrar atividade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xxl),

            SectionLabel(
              'A turma esta semana',
              trailing: Text('${family.memberIds.length}/4', style: t.bodySmall),
            ),
            MemberStatusRow(
              members: session.members,
              onMemberTap: (m) => MemberProfileScreen.open(context, m.id),
            ),
            const SizedBox(height: Space.xxl),

            SectionLabel(
              'Prêmios',
              trailing: Text(
                '${family.unlockedRewards.length} liberados',
                style: t.bodySmall,
              ),
            ),
            RewardsSection(
              rewards: family.rewards,
              vaultPoints: family.vaultPoints,
            ),
            const SizedBox(height: Space.xxl),

            const SectionLabel('Cartas'),
            _Cartas(saveCards: user.saveCards),
            const SizedBox(height: Space.xl),

            Surface(
              child: Row(
                children: [
                  Expanded(
                    child: StatBlock(
                      value: Formatters.points(user.pointsThisWeek),
                      label: 'meus pontos',
                      accent: true,
                    ),
                  ),
                  Container(width: 1, height: 30, color: p.border),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: StatBlock(
                      value: family.vaultPoints == 0
                          ? '0%'
                          : '${((user.pointsThisWeek / family.vaultPoints) * 100).round()}%',
                      label: 'do cofre',
                    ),
                  ),
                  Container(width: 1, height: 30, color: p.border),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: StatBlock(
                      value: '${user.longestStreak}',
                      suffix: 'd',
                      label: 'melhor sequência',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _menu(BuildContext context) {
    final session = context.read<SessionController>();
    final tema = context.read<ThemeController>();
    final family = session.family;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Código do convite'),
              Pressable(
                tone: PressableTone.ghost,
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: family?.inviteCode ?? ''),
                  );
                  Navigator.of(sheet).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      family?.inviteCode ?? '------',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 5,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: Space.md),
                    const Icon(Icons.copy_rounded, size: 17),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              const SectionLabel('Aparência'),
              _SeletorTema(controller: tema),
              const SizedBox(height: Space.xl),
              Pressable(
                tone: PressableTone.ghost,
                onPressed: () {
                  final id = session.user?.id;
                  Navigator.of(sheet).pop();
                  if (id != null) MemberProfileScreen.open(context, id);
                },
                child: const Text('Meu progresso'),
              ),
              const SizedBox(height: Space.md),
              Pressable(
                tone: PressableTone.ghost,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  session.signOut();
                },
                child: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeletorTema extends StatelessWidget {
  const _SeletorTema({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined, size: 17),
            label: Text('Claro'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_outlined, size: 17),
            label: Text('Auto'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined, size: 17),
            label: Text('Escuro'),
          ),
        ],
        selected: {controller.mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => controller.definir(s.first),
      ),
    );
  }
}

class _BotaoIcone extends StatelessWidget {
  const _BotaoIcone({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: 18, color: p.textSecondary),
        ),
      ),
    );
  }
}

class _Sequencia extends StatelessWidget {
  const _Sequencia({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 15, color: p.accent),
          const SizedBox(width: 3),
          Text(
            '$dias',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: p.accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Cartas extends StatelessWidget {
  const _Cartas({required this.saveCards});

  final int saveCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Carta(
            icon: Icons.volunteer_activism_outlined,
            title: 'Salva-Mãe/Pai',
            sub: saveCards > 0 ? '$saveCards disponível' : 'usada',
            enabled: saveCards > 0,
            onTap: () => DonatePointsSheet.show(context),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _Carta(
            icon: Icons.local_fire_department_outlined,
            title: 'Desafio',
            sub: 'lançar',
            onTap: () => PublishCardSheet.show(
              context,
              FeedPostType.impossibleChallenge,
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _Carta(
            icon: Icons.theater_comedy_outlined,
            title: 'Punição',
            sub: 'mico',
            onTap: () =>
                PublishCardSheet.show(context, FeedPostType.punishment),
          ),
        ),
      ],
    );
  }
}

class _Carta extends StatelessWidget {
  const _Carta({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PressableCard(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: p.textSecondary),
            const SizedBox(height: Space.md),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall?.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 1),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
