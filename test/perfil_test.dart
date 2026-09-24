import 'dart:io';

import 'package:desafio_em_familia/core/theme/app_theme.dart';
import 'package:desafio_em_familia/core/utils/week_utils.dart';
import 'package:desafio_em_familia/models/activity_log.dart';
import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/models/app_user.dart';
import 'package:desafio_em_familia/screens/profile/member_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _agora = DateTime.now();

AppUser membroDeExemplo({int sequencia = 3, int recorde = 7}) => AppUser(
      id: 'bia',
      familyId: 'f',
      displayName: 'Beatriz Silva',
      role: 'mae',
      avatarEmoji: '🐧',
      weeklyPoints: 900,
      weekId: WeekUtils.currentWeekId(),
      totalPoints: 12450,
      currentStreak: sequencia,
      longestStreak: recorde,
      lastActivityAt: _agora,
      statusMessage: 'Caminhada feita!',
    );

List<ActivityLog> logsDeExemplo() => [
      for (final (i, tipo, min, pts) in [
        (0, ActivityType.walk, 45, 150),
        (0, ActivityType.stretching, 20, 100),
        (1, ActivityType.gym, 60, 300),
        (3, ActivityType.walk, 30, 100),
      ])
        ActivityLog(
          id: '$i$tipo',
          familyId: 'f',
          userId: 'bia',
          userName: 'Bia',
          type: tipo,
          durationMinutes: min,
          points: pts,
          steps: tipo == ActivityType.walk ? 5200 : 0,
          createdAt: _agora.subtract(Duration(days: i, minutes: min)),
        ),
    ];

Widget app(Widget child, {bool escuro = false}) => MaterialApp(
      theme: escuro ? AppTheme.dark() : AppTheme.light(),
      home: child,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    // Inter de verdade: a fonte padrão de teste acusaria estouro falso.
    final inter = FontLoader('Inter');
    for (final peso in ['Regular', 'SemiBold', 'Bold']) {
      final bytes = File('assets/fonts/Inter-$peso.ttf').readAsBytesSync();
      inter.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await inter.load();
  });

  Future<void> telaPequena(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final escuro in [false, true]) {
    testWidgets('perfil próprio desenha (${escuro ? 'escuro' : 'claro'})',
        (tester) async {
      await telaPequena(tester);
      await tester.pumpWidget(app(
        PerfilView(
          member: membroDeExemplo(),
          souEu: true,
          cofre: 3000,
          logs: logsDeExemplo(),
        ),
        escuro: escuro,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Meu perfil'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Mãe'), findsOneWidget);
      expect(find.text('recorde: 7 dias'), findsOneWidget);
      expect(find.text('30'), findsOneWidget); // 900 de 3000 = 30%
      expect(find.text('Seus treinos'.toUpperCase()), findsOneWidget);
      expect(find.text('HOJE'), findsOneWidget);
    });
  }

  testWidgets('perfil de outra pessoa sem registros', (tester) async {
    await telaPequena(tester);
    await tester.pumpWidget(app(PerfilView(
      member: membroDeExemplo(sequencia: 0, recorde: 0),
      souEu: false,
      cofre: 0,
      logs: const [],
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Beatriz ainda não registrou nada'), findsOneWidget);
    expect(find.text('treine hoje para começar'), findsOneWidget);
  });
}
