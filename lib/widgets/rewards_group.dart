import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/reward.dart';
import 'ui/inset_group.dart';
import 'ui/primitives.dart';
import 'ui/reaction_icons.dart';

/// Prêmios do fim de semana, em ordem de quanto falta.
class RewardsGroup extends StatelessWidget {
  const RewardsGroup({
    super.key,
    required this.rewards,
    required this.vaultPoints,
  });

  final List<Reward> rewards;
  final int vaultPoints;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) return const SizedBox.shrink();

    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final ordenados = [...rewards]
      ..sort((a, b) => a.requiredPoints.compareTo(b.requiredPoints));
    final liberados = ordenados.where((r) => r.unlocked).length;

    return InsetGroup(
      header: 'Prêmios',
      trailing: Text('$liberados liberados', style: t.bodySmall),
      footer: 'O cofre libera cada prêmio ao passar dos pontos indicados.',
      children: [
        for (final r in ordenados)
          InsetRow(
            showChevron: false,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: r.unlocked ? p.accentSoft : p.surfaceSunken,
                borderRadius: BorderRadius.circular(Radii.group),
              ),
              alignment: Alignment.center,
              child: Icon(
                iconForReward(r.emoji),
                size: 18,
                color: r.unlocked ? p.accent : p.textSecondary,
              ),
            ),
            title: r.title,
            subtitle: r.unlocked
                ? 'liberado'
                : 'faltam ${Formatters.points((r.requiredPoints - vaultPoints).clamp(0, 1 << 30))} pts',
            trailing: SizedBox(
              width: 56,
              child: ProgressBarThin(
                value: r.requiredPoints == 0
                    ? 1
                    : vaultPoints / r.requiredPoints,
                height: 4,
                color: r.unlocked ? p.accent : p.borderStrong,
              ),
            ),
          ),
      ],
    );
  }
}
