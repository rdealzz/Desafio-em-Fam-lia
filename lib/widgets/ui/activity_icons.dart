import 'package:flutter/material.dart';

import '../../models/activity_type.dart';

/// Ícone de cada modalidade.
///
/// Fica na camada de interface, não no modelo: `ActivityType` é persistido no
/// Firestore e não deve depender do Flutter. O emoji continua no modelo porque
/// entra no TEXTO do mural; na tela, ícone lê melhor e envelhece melhor.
IconData iconForActivity(ActivityType type) {
  switch (type) {
    case ActivityType.walk:
      return Icons.directions_walk_rounded;
    case ActivityType.running:
      return Icons.directions_run_rounded;
    case ActivityType.cycling:
      return Icons.directions_bike_rounded;
    case ActivityType.gym:
      return Icons.fitness_center_rounded;
    case ActivityType.martialArts:
      return Icons.sports_martial_arts_rounded;
    case ActivityType.homeWorkout:
      return Icons.home_work_outlined;
    case ActivityType.stretching:
      return Icons.self_improvement_rounded;
  }
}

IconData iconForGroup(ActivityGroup group) {
  switch (group) {
    case ActivityGroup.outdoor:
      return Icons.park_outlined;
    case ActivityGroup.training:
      return Icons.sports_gymnastics_rounded;
    case ActivityGroup.home:
      return Icons.chair_outlined;
  }
}
