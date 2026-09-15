import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/activity_log.dart';

/// Pontos por dia nos últimos 7 dias.
///
/// Uma série só — por isso hue único e sem legenda; o título já diz o que é.
/// O dia é identificado pela letra abaixo da barra, então a leitura nunca
/// depende só da cor. Dia sem treino vira um traço neutro rente à base: a
/// ausência precisa parecer "não treinou", não "dado faltando".
class WeeklyActivityStrip extends StatelessWidget {
  const WeeklyActivityStrip({
    super.key,
    required this.logs,
    this.onDaySelected,
  });

  final List<ActivityLog> logs;
  final ValueChanged<DateTime>? onDaySelected;

  static const List<String> _weekdayInitials = [
    'S', 'T', 'Q', 'Q', 'S', 'S', 'D', // segunda a domingo
  ];

  /// Soma dos pontos de cada um dos últimos 7 dias, do mais antigo ao de hoje.
  List<_DayTotal> _dailyTotals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final points = logs
          .where((log) {
            final at = log.createdAt;
            if (at == null) return false;
            return at.year == day.year &&
                at.month == day.month &&
                at.day == day.day;
          })
          .fold<int>(0, (sum, log) => sum + log.points);
      return _DayTotal(day: day, points: points);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totals = _dailyTotals();
    final peak = totals.fold<int>(0, (max, d) => d.points > max ? d.points : max);
    final weekTotal = totals.fold<int>(0, (sum, d) => sum + d.points);
    final activeDays = totals.where((d) => d.points > 0).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: const Color(0xFFEFEDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Últimos 7 dias',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$activeDays de 7 dias',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${Formatters.points(weekTotal)} pts no período',
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < totals.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _DayBar(
                      total: totals[i],
                      peak: peak,
                      label: _weekdayInitials[totals[i].day.weekday - 1],
                      isToday: i == totals.length - 1,
                      onTap: onDaySelected == null
                          ? null
                          : () => onDaySelected!(totals[i].day),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTotal {
  const _DayTotal({required this.day, required this.points});

  final DateTime day;
  final int points;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.total,
    required this.peak,
    required this.label,
    required this.isToday,
    this.onTap,
  });

  final _DayTotal total;
  final int peak;
  final String label;
  final bool isToday;
  final VoidCallback? onTap;

  /// Altura reservada para a coluna de barras (o resto é rótulo e valor).
  static const double _trackHeight = 68;

  @override
  Widget build(BuildContext context) {
    final hasActivity = total.points > 0;
    // Piso visível para um dia que pontuou pouco não sumir contra a base.
    final ratio = peak == 0 ? 0.0 : total.points / peak;
    final height = hasActivity ? (8 + ratio * (_trackHeight - 8)) : 3.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            hasActivity ? '${total.points}' : '',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: _trackHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: height,
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? AppColors.primary
                        : const Color(0xFFDDD9EC),
                    // Extremidade arredondada só no topo: a barra fica ancorada
                    // na base, que é a referência de leitura.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? AppColors.primary : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
