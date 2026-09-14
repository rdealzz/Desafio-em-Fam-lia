/// Modalidades de exercício aceitas pelo app e suas regras de pontuação.
///
/// A regra é sempre "X pontos a cada Y minutos". Só blocos completos pontuam —
/// isso mantém o cálculo previsível e fácil de explicar para a família.
/// Ex.: 45 min de caminhada = 1 bloco de 30 min = 100 pts (faltam 15 min
/// para o próximo bloco).
enum ActivityType {
  walk(
    id: 'walk',
    label: 'Caminhada',
    emoji: '🚶',
    blockMinutes: 30,
    blockPoints: 100,
    tracksSteps: true,
  ),
  stretching(
    id: 'stretching',
    label: 'Alongamento',
    emoji: '🧘',
    blockMinutes: 10,
    blockPoints: 50,
  ),
  gym(
    id: 'gym',
    label: 'Academia / Corrida',
    emoji: '🏋️',
    blockMinutes: 30,
    blockPoints: 150,
  ),
  homeWorkout(
    id: 'home_workout',
    label: 'Exercício em Casa',
    emoji: '🏠',
    blockMinutes: 20,
    blockPoints: 100,
  );

  const ActivityType({
    required this.id,
    required this.label,
    required this.emoji,
    required this.blockMinutes,
    required this.blockPoints,
    this.tracksSteps = false,
  });

  /// Identificador persistido no Firestore. Nunca mude sem migrar os dados.
  final String id;
  final String label;
  final String emoji;

  /// Tamanho do bloco de tempo que pontua.
  final int blockMinutes;

  /// Pontos concedidos por bloco completo.
  final int blockPoints;

  /// Se a modalidade aceita bônus por passos (HealthKit / Google Fit).
  final bool tracksSteps;

  /// Bônus de passos: +1 ponto a cada 100 passos.
  static const int stepsPerBonusPoint = 100;

  String get rule => '$blockPoints pts a cada $blockMinutes min';

  static ActivityType fromId(String? id) {
    return ActivityType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => ActivityType.walk,
    );
  }
}
