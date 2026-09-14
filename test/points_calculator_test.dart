import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/services/points_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Estes testes travam as regras de negócio combinadas com a família.
/// Rode com: `flutter test`
void main() {
  group('Caminhada — 100 pts a cada 30 min', () {
    test('30 min rendem 100 pts', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.walk,
        minutes: 30,
      );
      expect(result.basePoints, 100);
      expect(result.total, 100);
      expect(result.completedBlocks, 1);
    });

    test('45 min ainda rendem 100 pts e avisam o que falta', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.walk,
        minutes: 45,
      );
      expect(result.total, 100);
      expect(result.minutesToNextBlock, 15);
    });

    test('60 min rendem 200 pts', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.walk,
        minutes: 60,
      );
      expect(result.total, 200);
      expect(result.completedBlocks, 2);
    });

    test('passos valem +1 pt a cada 100', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.walk,
        minutes: 30,
        steps: 4250,
      );
      expect(result.stepsPoints, 42);
      expect(result.total, 142);
    });

    test('menos de 30 min não pontua', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.walk,
        minutes: 29,
      );
      expect(result.total, 0);
    });
  });

  group('Demais modalidades', () {
    test('alongamento: 50 pts a cada 10 min', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.stretching,
          minutes: 25,
        ).total,
        100, // 2 blocos completos
      );
    });

    test('academia/corrida: 150 pts a cada 30 min', () {
      expect(
        PointsCalculator.calculate(type: ActivityType.gym, minutes: 60).total,
        300,
      );
    });

    test('exercício em casa: 100 pts a cada 20 min', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.homeWorkout,
          minutes: 40,
        ).total,
        200,
      );
    });

    test('passos só contam na caminhada', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.gym,
        minutes: 30,
        steps: 5000,
      );
      expect(result.stepsPoints, 0);
      expect(result.total, 150);
    });
  });

  group('Proteções', () {
    test('tempo absurdo é limitado pelo teto', () {
      final result = PointsCalculator.calculate(
        type: ActivityType.gym,
        minutes: 5000,
      );
      expect(result.basePoints, 1500); // 300 min / 30 * 150
    });

    test('valores negativos não geram pontos', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.walk,
          minutes: -10,
          steps: -500,
        ).total,
        0,
      );
    });
  });

  group('Carta Salva-Mãe/Pai', () {
    test('a doação vale o dobro', () {
      expect(PointsCalculator.donationValue(150), 300);
    });
  });
}
