import '../core/utils/week_utils.dart';
import '../models/family.dart';

/// O ritmo que falta para bater a meta da semana.
///
/// "Faltam 2.400 pts" não diz se está tranquilo ou apertado. "Faltam 3 dias,
/// 800 pts por dia" diz — e dividido pela turma vira uma conta que cada um
/// consegue fazer de cabeça: é uma caminhada de 30 min ou são duas?
class WeeklyPace {
  const WeeklyPace({
    required this.daysLeft,
    required this.pointsRemaining,
    required this.members,
  });

  factory WeeklyPace.of(Family family, DateTime now) => WeeklyPace(
        daysLeft: WeekUtils.daysLeftInWeek(now),
        pointsRemaining: family.pointsRemaining,
        members: family.memberIds.length,
      );

  /// Dias que restam, contando hoje (1 a 7).
  final int daysLeft;
  final int pointsRemaining;
  final int members;

  bool get done => pointsRemaining <= 0;

  /// Domingo: o que faltar tem que sair hoje.
  bool get lastDay => daysLeft <= 1;

  /// Pontos por dia para fechar a meta, arredondado para cima — arredondar
  /// para baixo prometeria uma meta que não fecha.
  int get perDay => done ? 0 : _ceilDiv(pointsRemaining, daysLeft.clamp(1, 7));

  /// A parte de cada integrante no [perDay].
  int get perPersonPerDay => members <= 1 ? perDay : _ceilDiv(perDay, members);

  static int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;
}
