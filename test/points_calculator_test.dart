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

    test('corrida: 150 pts a cada 30 min', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.running,
          minutes: 30,
        ).total,
        150,
      );
    });

    test('ciclismo: 150 pts a cada 30 min', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.cycling,
          minutes: 60,
        ).total,
        300,
      );
    });

    test('luta: 150 pts a cada 30 min', () {
      expect(
        PointsCalculator.calculate(
          type: ActivityType.martialArts,
          minutes: 90,
        ).total,
        450,
      );
    });

    test('passos contam onde o pé bate no chão', () {
      // Caminhada e corrida geram passo; pedalar e academia não.
      expect(ActivityType.walk.tracksSteps, isTrue);
      expect(ActivityType.running.tracksSteps, isTrue);
      expect(ActivityType.cycling.tracksSteps, isFalse);
      expect(ActivityType.gym.tracksSteps, isFalse);

      final pedalando = PointsCalculator.calculate(
        type: ActivityType.cycling,
        minutes: 30,
        steps: 5000,
      );
      expect(pedalando.stepsPoints, 0);
      expect(pedalando.total, 150);
    });
  });

  group('Grupos de atividade', () {
    test('toda modalidade pertence a um grupo', () {
      for (final type in ActivityType.values) {
        expect(type.group, isNotNull);
      }
    });

    test('os três grupos estão povoados', () {
      for (final group in ActivityGroup.values) {
        expect(ActivityType.ofGroup(group), isNotEmpty);
      }
    });

    test('ofGroup cobre todas as modalidades sem repetir', () {
      final agrupadas = ActivityGroup.values
          .expand(ActivityType.ofGroup)
          .toList();
      expect(agrupadas.length, ActivityType.values.length);
      expect(agrupadas.toSet().length, ActivityType.values.length);
    });

    test('ids persistidos são únicos', () {
      final ids = ActivityType.values.map((t) => t.id).toSet();
      expect(ids.length, ActivityType.values.length);
    });

    test('fromId sobrevive a valor desconhecido', () {
      expect(ActivityType.fromId('modalidade_que_nao_existe'),
          ActivityType.walk);
      expect(ActivityType.fromId('martial_arts'), ActivityType.martialArts);
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
