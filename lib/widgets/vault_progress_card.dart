import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/family.dart';

/// Cartão principal da Tela 1: o Cofre de Pontos da Família.
///
/// Mostra a barra de progresso da semana (ex.: 3.200 / 5.000) e o quanto
/// falta para o próximo prêmio.
class VaultProgressCard extends StatelessWidget {
  const VaultProgressCard({super.key, required this.family});

  final Family family;

  @override
  Widget build(BuildContext context) {
    final nextReward = family.nextReward;
    final goalReached = family.goalReached;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.vaultGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏦', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cofre da Semana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${(family.progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Formatters.points(family.vaultPoints),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${Formatters.points(family.weeklyGoal)} pts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: family.progress,
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            goalReached
                ? '🎉 Meta batida! Os prêmios do fim de semana estão liberados.'
                : nextReward != null
                    ? 'Faltam ${Formatters.points(nextReward.requiredPoints - family.vaultPoints)} pts '
                        'para ${nextReward.emoji} ${nextReward.title}'
                    : 'Faltam ${Formatters.points(family.pointsRemaining)} pts para a meta',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
