import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/activity_type.dart';

/// Grade de ícones grandes para escolher a modalidade (Tela 2).
///
/// Sete modalidades agrupadas por onde o treino acontece — com o título de
/// grupo, a busca fica curta: quem vai pedalar olha só "Ao ar livre".
/// Alvos de toque generosos: qualquer um da família acerta de primeira.
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
        for (final group in ActivityGroup.values) ...[
          _GroupHeader(group: group),
          const SizedBox(height: 10),
          _GroupGrid(
            types: ActivityType.ofGroup(group),
            selected: selected,
            onSelected: onSelected,
          ),
          if (group != ActivityGroup.values.last) const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final ActivityGroup group;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.activityGroup[group.id] ?? AppColors.primary;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          group.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<ActivityType> types;
  final ActivityType? selected;
  final ValueChanged<ActivityType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: types
          .map((type) => _TypeCard(
                type: type,
                isSelected: selected == type,
                onTap: () => onSelected(type),
              ))
          .toList(),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ActivityType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.activityGroup[type.group.id] ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFEFEDF7),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 26)),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check_circle, size: 18, color: color),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? color : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.rule,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
