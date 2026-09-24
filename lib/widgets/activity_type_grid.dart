import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../models/activity_type.dart';
import 'ui/activity_icons.dart';
import 'ui/pressable.dart';
import 'ui/primitives.dart';

/// Escolha da modalidade, agrupada por onde o treino acontece.
///
/// Sem cor por modalidade: só o selecionado recebe o acento. A identidade vem
/// do ícone e do nome, que é o que a pessoa lê de qualquer jeito — e resolve
/// de graça o problema de daltonismo que sete cores criariam.
class ActivityTypeGrid extends StatelessWidget {
  const ActivityTypeGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ActivityType? selected;
  final ValueChanged<ActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grupo in ActivityGroup.values) ...[
          SectionLabel(grupo.label),
          _Grade(
            tipos: ActivityType.ofGroup(grupo),
            selected: selected,
            onSelected: onSelected,
          ),
          if (grupo != ActivityGroup.values.last)
            const SizedBox(height: Space.xl),
        ],
      ],
    );
  }
}

class _Grade extends StatelessWidget {
  const _Grade({
    required this.tipos,
    required this.selected,
    required this.onSelected,
  });

  final List<ActivityType> tipos;
  final ActivityType? selected;
  final ValueChanged<ActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.75,
      children: [
        for (final tipo in tipos)
          _Cartao(
            tipo: tipo,
            selecionado: selected == tipo,
            onTap: () => onSelected(tipo),
          ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.tipo,
    required this.selecionado,
    required this.onTap,
  });

  final ActivityType tipo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final cor = selecionado ? p.accent : p.textSecondary;

    return PressableCard(
      onTap: onTap,
      selected: selecionado,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          // Ícone num selo: cinza em repouso, com o gradiente quando
          // escolhido. Dá peso ao selecionado sem colorir a grade inteira.
          AnimatedContainer(
            duration: Motion.base,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: selecionado ? null : p.surfaceSunken,
              gradient: selecionado ? p.accentGradient : null,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(
              iconForActivity(tipo),
              size: 17,
              color: selecionado ? p.onAccent : cor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encolhe um pouco em vez de cortar: "Alongame…" não diz
                // nada, e o nome é o que a pessoa procura na grade.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tipo.short,
                    maxLines: 1,
                    style: t.labelLarge?.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                // Duas linhas: em celular estreito a regra inteira não cabe
                // numa só, e cortada ela perdia justamente o tempo.
                Text(
                  '${tipo.blockPoints} pts a cada ${tipo.blockMinutes} min',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
