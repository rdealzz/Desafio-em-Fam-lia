import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/family.dart';
import 'ui/primitives.dart';

/// O Cofre da Semana — bloco principal da Tela 1.
///
/// Antes era um cartão com gradiente roxo. Agora o número é o herói e a cor
/// aparece só no progresso: é a regra que as referências de 2026 repetem —
/// um acento, reservado ao que importa. Sem gradiente, sem sombra colorida,
/// sem competir com o resto da tela.
class VaultProgressCard extends StatelessWidget {
  const VaultProgressCard({super.key, required this.family});

  final Family family;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final proximo = family.nextReward;
    final bateu = family.goalReached;

    return Surface(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel('Cofre da semana')),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: bateu ? p.accentSoft : p.surfaceSunken,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  '${(family.progress * 100).round()}%',
                  style: t.labelSmall?.copyWith(
                    color: bateu ? p.accent : p.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Formatters.points(family.vaultPoints),
                style: t.displayLarge,
              ),
              const SizedBox(width: Space.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${Formatters.points(family.weeklyGoal)}',
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ProgressBarThin(value: family.progress, height: 10),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Icon(
                bateu ? Icons.check_circle_rounded : Icons.flag_outlined,
                size: 15,
                color: bateu ? p.accent : p.textMuted,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  bateu
                      ? 'Meta batida. Prêmios do fim de semana liberados.'
                      : proximo != null
                          ? 'Faltam ${Formatters.points(proximo.requiredPoints - family.vaultPoints)} pts para ${proximo.title}'
                          : 'Faltam ${Formatters.points(family.pointsRemaining)} pts para a meta',
                  style: t.bodySmall?.copyWith(
                    color: bateu ? p.accent : p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
