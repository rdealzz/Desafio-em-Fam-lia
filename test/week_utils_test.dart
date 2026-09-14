import 'package:desafio_em_familia/core/utils/week_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeekUtils', () {
    test('a semana começa na segunda-feira', () {
      // 2026-09-14 é uma segunda-feira.
      final quarta = DateTime(2026, 9, 16, 15, 30);
      expect(WeekUtils.startOfWeek(quarta), DateTime(2026, 9, 14));
    });

    test('domingo pertence à semana que começou na segunda anterior', () {
      final domingo = DateTime(2026, 9, 20, 22);
      expect(WeekUtils.startOfWeek(domingo), DateTime(2026, 9, 14));
    });

    test('dias da mesma semana compartilham o weekId', () {
      final segunda = DateTime(2026, 9, 14);
      final domingo = DateTime(2026, 9, 20);
      expect(WeekUtils.weekId(segunda), WeekUtils.weekId(domingo));
    });

    test('a semana seguinte tem outro weekId', () {
      expect(
        WeekUtils.weekId(DateTime(2026, 9, 20)) ==
            WeekUtils.weekId(DateTime(2026, 9, 21)),
        isFalse,
      );
    });

    test('isYesterday reconhece a virada do dia', () {
      final hoje = DateTime(2026, 9, 14, 9);
      final ontem = DateTime(2026, 9, 13, 23, 50);
      expect(WeekUtils.isYesterday(ontem, hoje), isTrue);
      expect(WeekUtils.isYesterday(hoje, hoje), isFalse);
    });
  });
}
