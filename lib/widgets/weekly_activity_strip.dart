import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/activity_log.dart';
import 'ui/primitives.dart';

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

    final t = Theme.of(context).textTheme;

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            'Últimos 7 dias',
            trailing: Text('$activeDays de 7 dias', style: t.bodySmall),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(Formatters.points(weekTotal), style: t.displayMedium),
              const SizedBox(width: Space.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('pts no período', style: t.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          RepaintBoundary(
            // Altura com folga para o valor e a letra do dia: com 104 a
            // coluna estourava 3 px depois que a escala de texto mudou.
            child: SizedBox(
              height: 112,
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
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final temAtividade = total.points > 0;
    final fracao = peak == 0 ? 0.0 : total.points / peak;
    // Piso visível: um dia de poucos pontos não pode sumir contra a base.
    final altura = temAtividade ? (10 + fracao * (_trackHeight - 10)) : 3.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            temAtividade ? '${total.points}' : '',
            maxLines: 1,
            style: t.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: _trackHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.enter,
                  height: altura,
                  decoration: BoxDecoration(
                    color: temAtividade ? p.accent : p.border,
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
            style: t.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? p.accent : p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
