import '../models/activity_type.dart';

/// Resultado detalhado do cálculo — a Tela 2 mostra cada parcela ao vivo.
class PointsBreakdown {
  const PointsBreakdown({
    required this.basePoints,
    required this.stepsPoints,
    required this.completedBlocks,
    required this.minutesToNextBlock,
  });

  /// Pontos vindos do tempo de exercício.
  final int basePoints;

  /// Bônus de passos (+1 pt a cada 100 passos), só para caminhada.
  final int stepsPoints;

  /// Quantos blocos completos o tempo rendeu.
  final int completedBlocks;

  /// Minutos que faltam para o próximo bloco — vira dica na interface.
  final int minutesToNextBlock;

  int get total => basePoints + stepsPoints;

  static const PointsBreakdown zero = PointsBreakdown(
    basePoints: 0,
    stepsPoints: 0,
    completedBlocks: 0,
    minutesToNextBlock: 0,
  );
}

/// Regras de pontuação do "Desafio em Família".
///
/// Fonte única da verdade: a interface usa para o preview instantâneo e o
/// [ActivityService] usa dentro da transação. Nunca duplique esta conta.
///
/// - Caminhada:          100 pts a cada 30 min (+1 pt a cada 100 passos)
/// - Alongamento:         50 pts a cada 10 min
/// - Academia / Corrida: 150 pts a cada 30 min
/// - Exercício em Casa:  100 pts a cada 20 min
class PointsCalculator {
  const PointsCalculator._();

  /// Teto de segurança: evita que um erro de digitação (ex.: 5000 min)
  /// estoure o cofre da semana inteira.
  static const int maxMinutesPerLog = 300;
  static const int maxStepsPerLog = 100000;

  static PointsBreakdown calculate({
    required ActivityType type,
    required int minutes,
    int steps = 0,
  }) {
    final safeMinutes = minutes.clamp(0, maxMinutesPerLog);
    final safeSteps = type.tracksSteps ? steps.clamp(0, maxStepsPerLog) : 0;

    final blocks = safeMinutes ~/ type.blockMinutes;
    final basePoints = blocks * type.blockPoints;
    final stepsPoints = safeSteps ~/ ActivityType.stepsPerBonusPoint;

    final remainder = safeMinutes % type.blockMinutes;
    final minutesToNextBlock =
        safeMinutes >= maxMinutesPerLog ? 0 : type.blockMinutes - remainder;

    return PointsBreakdown(
      basePoints: basePoints,
      stepsPoints: stepsPoints,
      completedBlocks: blocks,
      minutesToNextBlock: minutesToNextBlock,
    );
  }

  /// Pontos que a Carta "Salva-Mãe/Pai" entrega: a doação vale em dobro.
  static int donationValue(int donatedPoints) => donatedPoints * 2;
}
