import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/reward.dart';

/// Resumo dos prêmios do fim de semana: desbloqueados em destaque,
/// bloqueados com o quanto falta.
class RewardsSection extends StatelessWidget {
  const RewardsSection({
    super.key,
    required this.rewards,
    required this.vaultPoints,
  });

  final List<Reward> rewards;
  final int vaultPoints;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...rewards]
      ..sort((a, b) => a.requiredPoints.compareTo(b.requiredPoints));

    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _RewardCard(
          reward: sorted[index],
          vaultPoints: vaultPoints,
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.vaultPoints});

  final Reward reward;
  final int vaultPoints;

  @override
  Widget build(BuildContext context) {
    final unlocked = reward.unlocked;
    final missing = (reward.requiredPoints - vaultPoints).clamp(0, 1 << 30);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.success.withOpacity(0.10) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked
              ? AppColors.success.withOpacity(0.45)
              : const Color(0xFFEFEDF7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reward.emoji, style: const TextStyle(fontSize: 26)),
              const Spacer(),
              if (reward.level == 2)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'mensal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reward.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Text(
            unlocked
                ? '✅ Desbloqueado!'
                : 'faltam ${Formatters.points(missing)} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.success : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: reward.requiredPoints == 0
                  ? 1
                  : (vaultPoints / reward.requiredPoints).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFEFEDF7),
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
