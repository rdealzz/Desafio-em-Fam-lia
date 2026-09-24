import 'package:desafio_em_familia/core/theme/app_theme.dart';
import 'package:desafio_em_familia/core/utils/week_utils.dart';
import 'package:desafio_em_familia/models/app_user.dart';
import 'package:desafio_em_familia/models/family.dart';
import 'package:desafio_em_familia/models/reward.dart';
import 'package:desafio_em_familia/screens/scoreboard/scoreboard_screen.dart';
import 'package:desafio_em_familia/widgets/vault_progress_card.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

AppUser membro(String nome, int pontos, {int sequencia = 0}) => AppUser(
      id: nome,
      familyId: 'f',
      displayName: nome,
      weeklyPoints: pontos,
      weekId: WeekUtils.currentWeekId(),
      currentStreak: sequencia,
    );

Family familia(int cofre) => Family(
      id: 'f',
      name: 'Família Silva',
      inviteCode: 'ABC123',
      memberIds: const ['Ana', 'Bia', 'Caio', 'Duda'],
      weeklyGoal: 5000,
      vaultPoints: cofre,
      weekId: WeekUtils.currentWeekId(),
      rewards: Reward.defaults(5000),
    );

Widget app(Widget child, {bool escuro = false}) => MaterialApp(
      theme: escuro ? AppTheme.dark() : AppTheme.light(),
      home: child,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    // A fonte de teste padrão desenha cada letra como um quadrado largo e
    // acusaria estouro que não existe no aparelho. Com a Inter de verdade, o
    // estouro que aparecer aqui aparece no celular também.
    final inter = FontLoader('Inter');
    for (final peso in ['Regular', 'SemiBold', 'ExtraBold']) {
      final bytes = File('assets/fonts/Inter-$peso.ttf').readAsBytesSync();
      inter.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await inter.load();
  });

  // Largura de celular pequeno: é onde estouro de layout aparece primeiro.
  Future<void> telaPequena(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final escuro in [false, true]) {
    final modo = escuro ? 'escuro' : 'claro';

    testWidgets('cofre desenha sem estourar ($modo)', (tester) async {
      await telaPequena(tester);
      for (final cofre in [0, 3100, 5200]) {
        await tester.pumpWidget(app(
          Scaffold(body: VaultProgressCard(family: familia(cofre))),
          escuro: escuro,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('meta batida'), findsOneWidget);
    });

    testWidgets('placar monta pódio e lanterna ($modo)', (tester) async {
      await telaPequena(tester);
      await tester.pumpWidget(app(
        ScoreboardView(
          members: [
            membro('Ana', 1200, sequencia: 4),
            membro('Bia', 900),
            membro('Caio', 650),
            membro('Duda', 100),
          ],
          family: familia(2850),
          meuId: 'Bia',
          hoje: DateTime(2026, 9, 24),
        ),
        escuro: escuro,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // A lista é preguiçosa: o fim só existe depois de rolar até ele.
      await tester.scrollUntilVisible(find.text('Bia (você)'), 200);
      await tester.scrollUntilVisible(
        find.text('Duda está na lanterna'),
        200,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('placar vazio explica o que falta', (tester) async {
    await tester.pumpWidget(app(ScoreboardView(
      members: [membro('Ana', 0), membro('Bia', 0)],
      family: familia(0),
      meuId: 'Ana',
      hoje: DateTime(2026, 9, 21),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ninguém pontuou ainda'), findsOneWidget);
    expect(find.textContaining('lanterna'), findsNothing);
  });
}
