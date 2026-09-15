import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/reward.dart';
import 'ui/primitives.dart';

/// Prêmios do fim de semana em lista compacta.
///
/// O emoji fica: aqui ele é conteúdo (a pizza, o açaí), não decoração de
/// interface. Liberado ganha o acento; bloqueado mostra só quanto falta.
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
    if (rewards.isEmpty) return const SizedBox.shrink();

    final ordenados = [...rewards]
      ..sort((a, b) => a.requiredPoints.compareTo(b.requiredPoints));

    return Surface(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        children: [
          for (var i = 0; i < ordenados.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: Space.lg, endIndent: Space.lg),
            _Item(reward: ordenados[i], vaultPoints: vaultPoints),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.reward, required this.vaultPoints});

  final Reward reward;
  final int vaultPoints;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final liberado = reward.unlocked;
    final falta = (reward.requiredPoints - vaultPoints).clamp(0, 1 << 30);
    final fracao = reward.requiredPoints == 0
        ? 1.0
        : (vaultPoints / reward.requiredPoints).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: liberado ? p.accentSoft : p.surfaceSunken,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            alignment: Alignment.center,
            child: Text(reward.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reward.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelLarge,
                      ),
                    ),
                    if (reward.level == 2)
                      Text('mensal', style: t.bodySmall),
                  ],
                ),
                const SizedBox(height: 5),
                ProgressBarThin(
                  value: fracao,
                  height: 4,
                  color: liberado ? p.accent : p.borderStrong,
                ),
                const SizedBox(height: 5),
                Text(
                  liberado
                      ? 'liberado'
                      : 'faltam ${Formatters.points(falta)} pts',
                  style: t.bodySmall?.copyWith(
                    color: liberado ? p.accent : p.textMuted,
                    fontWeight: liberado ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
