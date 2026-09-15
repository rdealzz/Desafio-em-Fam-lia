/// Onde/como o treino acontece. Serve para agrupar a grade e dar cor.
///
/// A cor é do grupo, não da modalidade: sete cores distintas reprovam no teste
/// de daltonismo (rosa e verde ficam a ΔE 1,1 em deuteranopia). Três passam.
/// Quem identifica a modalidade é o emoji e o rótulo, que sempre aparecem.
enum ActivityGroup {
  /// Na rua, movimento contínuo.
  outdoor('outdoor', 'Ao ar livre'),

  /// Treino dirigido, geralmente em academia ou dojô.
  training('training', 'Treino'),

  /// Dá para fazer na sala de casa.
  home('home', 'Em casa');

  const ActivityGroup(this.id, this.label);

  final String id;
  final String label;
}

/// Modalidades aceitas pelo app e suas regras de pontuação.
///
/// A regra é sempre "X pontos a cada Y minutos". Só blocos completos pontuam —
/// isso mantém o cálculo previsível e fácil de explicar para a família.
/// Ex.: 45 min de caminhada = 1 bloco de 30 min = 100 pts (faltam 15 min
/// para o próximo bloco).
///
/// As quatro primeiras mantêm exatamente os números combinados no início.
/// Ciclismo e luta entraram na mesma taxa de Academia/Corrida (150 a cada 30
/// min), porque são sessões de esforço comparável.
enum ActivityType {
  walk(
    id: 'walk',
    label: 'Caminhada',
    emoji: '🚶',
    group: ActivityGroup.outdoor,
    blockMinutes: 30,
    blockPoints: 100,
    tracksSteps: true,
  ),
  running(
    id: 'running',
    label: 'Corrida',
    emoji: '🏃',
    group: ActivityGroup.outdoor,
    blockMinutes: 30,
    blockPoints: 150,
    tracksSteps: true,
  ),
  cycling(
    id: 'cycling',
    label: 'Ciclismo',
    emoji: '🚴',
    group: ActivityGroup.outdoor,
    blockMinutes: 30,
    blockPoints: 150,
  ),
  gym(
    id: 'gym',
    label: 'Academia',
    emoji: '🏋️',
    group: ActivityGroup.training,
    blockMinutes: 30,
    blockPoints: 150,
  ),
  martialArts(
    id: 'martial_arts',
    label: 'Luta',
    emoji: '🥋',
    group: ActivityGroup.training,
    blockMinutes: 30,
    blockPoints: 150,
  ),
  homeWorkout(
    id: 'home_workout',
    label: 'Exercício em Casa',
    emoji: '🏠',
    group: ActivityGroup.home,
    blockMinutes: 20,
    blockPoints: 100,
  ),
  stretching(
    id: 'stretching',
    label: 'Alongamento',
    emoji: '🧘',
    group: ActivityGroup.home,
    blockMinutes: 10,
    blockPoints: 50,
  );

  const ActivityType({
    required this.id,
    required this.label,
    required this.emoji,
    required this.group,
    required this.blockMinutes,
    required this.blockPoints,
    this.tracksSteps = false,
  });

  /// Identificador persistido no Firestore. Nunca mude sem migrar os dados.
  final String id;
  final String label;
  final String emoji;
  final ActivityGroup group;

  /// Tamanho do bloco de tempo que pontua.
  final int blockMinutes;

  /// Pontos concedidos por bloco completo.
  final int blockPoints;

  /// Se a modalidade aceita bônus por passos (HealthKit / Google Fit).
  /// Só faz sentido onde o pé bate no chão — pedalar não gera passo.
  final bool tracksSteps;

  /// Bônus de passos: +1 ponto a cada 100 passos.
  static const int stepsPerBonusPoint = 100;

  String get rule => '$blockPoints pts a cada $blockMinutes min';

  /// Modalidades de um grupo, na ordem em que aparecem na grade.
  static List<ActivityType> ofGroup(ActivityGroup group) =>
      ActivityType.values.where((type) => type.group == group).toList();

  static ActivityType fromId(String? id) {
    return ActivityType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => ActivityType.walk,
    );
  }
}
