import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/activity_type.dart';

/// Grade de ícones grandes para escolher a modalidade (Tela 2).
///
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: ActivityType.values.map((type) {
        final isSelected = selected == type;
        final color = AppColors.activity[type.id] ?? AppColors.primary;

        return InkWell(
          onTap: () => onSelected(type),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFEFEDF7),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 10),
                Text(
                  type.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected ? color : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type.rule,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
