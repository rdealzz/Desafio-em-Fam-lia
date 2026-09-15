import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/feed_post.dart';
import '../../state/session_controller.dart';
import '../profile/member_profile_screen.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/member_status_row.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/rewards_section.dart';
import '../../widgets/vault_progress_card.dart';

/// TELA 1 — Dashboard "A Casa".
///
/// Tudo que a família precisa ver de relance: o cofre da semana, quem já
/// treinou hoje, o botão grande de registrar e os prêmios desbloqueados.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onRegisterActivity});

  /// Leva para a Tela 2 (a casca controla a navegação).
  final VoidCallback? onRegisterActivity;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final family = session.family;
    final user = session.user;

    if (family == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          // Os dados já chegam por stream; o gesto serve de conforto visual.
          onRefresh: () async =>
              Future<void>.delayed(const Duration(milliseconds: 400)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Cabeçalho
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${user.firstName}! 👋',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          family.name,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StreakBadge(streak: user.currentStreak),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Convite e configurações',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _openMenu(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              VaultProgressCard(family: family),
              const SizedBox(height: 24),

              // Botão principal — grande e impossível de não ver.
              FilledButton.icon(
                onPressed: onRegisterActivity,
                icon: const Icon(Icons.add_circle_outline, size: 26),
                label: const Text('Registrar Atividade'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(66),
                  backgroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 26),

              _SectionTitle(
                title: 'A turma hoje',
                trailing: '${family.memberIds.length}/4',
              ),
              const SizedBox(height: 12),
              MemberStatusRow(
                members: session.members,
                onMemberTap: (member) =>
                    MemberProfileScreen.open(context, member.id),
              ),
              const SizedBox(height: 26),

              _SectionTitle(
                title: 'Prêmios do fim de semana',
                trailing: '${family.unlockedRewards.length} liberados',
              ),
              const SizedBox(height: 12),
              RewardsSection(
                rewards: family.rewards,
                vaultPoints: family.vaultPoints,
              ),
              const SizedBox(height: 26),

              const _SectionTitle(title: 'Cartas de brincadeira'),
              const SizedBox(height: 12),
              _CardsRow(saveCards: user.saveCards),
              const SizedBox(height: 20),

              _WeekSummary(
                myPoints: user.pointsThisWeek,
                vaultPoints: family.vaultPoints,
                longestStreak: user.longestStreak,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final session = context.read<SessionController>();
    final family = session.family;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Convide a família',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quem tiver este código entra no mesmo cofre (até 4 pessoas).',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: family?.inviteCode ?? ''),
                );
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      family?.inviteCode ?? '------',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.copy_rounded,
                        color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () {
                final myId = session.user?.id;
                Navigator.of(sheetContext).pop();
                if (myId != null) MemberProfileScreen.open(context, myId);
              },
              icon: const Icon(Icons.timeline),
              label: const Text('Meu progresso'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                session.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              color: AppColors.secondary, size: 18),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalhos para as três cartas de gamificação.
class _CardsRow extends StatelessWidget {
  const _CardsRow({required this.saveCards});

  final int saveCards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GameCard(
            emoji: '🦸',
            title: 'Salva-Mãe/Pai',
            subtitle: saveCards > 0
                ? '$saveCards disponível'
                : 'usada nesta semana',
            color: AppColors.primary,
            enabled: saveCards > 0,
            onTap: () => DonatePointsSheet.show(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GameCard(
            emoji: '🔥',
            title: 'Desafio',
            subtitle: 'lançar agora',
            color: AppColors.danger,
            onTap: () => PublishCardSheet.show(
              context,
              FeedPostType.impossibleChallenge,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GameCard(
            emoji: '🤡',
            title: 'Punição',
            subtitle: 'mico de domingo',
            color: AppColors.warning,
            onTap: () =>
                PublishCardSheet.show(context, FeedPostType.punishment),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.myPoints,
    required this.vaultPoints,
    required this.longestStreak,
  });

  final int myPoints;
  final int vaultPoints;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final share = vaultPoints == 0 ? 0 : ((myPoints / vaultPoints) * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'Meus pontos',
            value: Formatters.points(myPoints),
          ),
          const _Divider(),
          _Stat(label: 'Do cofre', value: '$share%'),
          const _Divider(),
          _Stat(label: 'Melhor sequência', value: '$longestStreak d'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFEFEDF7),
    );
  }
}
