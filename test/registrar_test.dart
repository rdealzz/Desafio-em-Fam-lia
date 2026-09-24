import 'dart:io';

import 'package:desafio_em_familia/core/theme/app_theme.dart';
import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/models/reward.dart';
import 'package:desafio_em_familia/screens/activity/register_activity_screen.dart';
import 'package:desafio_em_familia/services/activity_service.dart';
import 'package:desafio_em_familia/services/auth_service.dart';
import 'package:desafio_em_familia/services/family_service.dart';
import 'package:desafio_em_familia/state/session_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sessão sem Firebase: ninguém logado, sem família. Basta para desenhar a
/// tela; o envio de verdade é coberto pelas regras e pelo serviço.
class _AuthFalso implements AuthService {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FamiliaFalsa implements FamilyService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget app(Widget child, {bool escuro = false}) =>
    ChangeNotifierProvider<SessionController>(
      create: (_) => SessionController(
        authService: _AuthFalso(),
        familyService: _FamiliaFalsa(),
      ),
      child: MaterialApp(
        theme: escuro ? AppTheme.dark() : AppTheme.light(),
        home: child,
      ),
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
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final escuro in [false, true]) {
    testWidgets('tela de registro desenha (${escuro ? 'escuro' : 'claro'})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await telaPequena(tester);
      await tester.pumpWidget(
        app(const RegisterActivityScreen(), escuro: escuro),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Barra fixa visível sem rolar, dizendo o que falta.
      expect(find.text('Depositar'), findsOneWidget);
      expect(find.text('falta a foto comprovante'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Galeria'),
        200,
        // Os campos de texto também têm rolagem própria: a da lista é a
        // primeira.
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('abre no último treino e oferece repetir', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ultimo_treino_tipo': 'gym',
      'ultimo_treino_minutos': 60,
    });
    await telaPequena(tester);
    await tester.pumpWidget(app(const RegisterActivityScreen()));
    await tester.pumpAndSettle();

    // Já abriu em Academia 60 min: 2 blocos de 150.
    expect(find.text('+300'), findsOneWidget);
    expect(find.textContaining('Repetir:'), findsNothing);

    // Mudou de modalidade: aparece o atalho para voltar.
    await tester.tap(find.text('Alongamento'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Repetir:'), findsOneWidget);

    await tester.tap(find.textContaining('Repetir:'));
    await tester.pumpAndSettle();
    expect(find.text('+300'), findsOneWidget);
  });

  testWidgets('comemoração mostra pontos, cofre e prêmio', (tester) async {
    await telaPequena(tester);
    await tester.pumpWidget(app(Scaffold(
      body: Comemoracao(
        tipo: ActivityType.walk,
        rewards: Reward.defaults(5000),
        resultado: const ActivityRegistrationResult(
          pointsEarned: 150,
          vaultPoints: 3100,
          weeklyGoal: 5000,
          currentStreak: 4,
          unlockedRewards: [
            Reward(id: 'pizza', title: 'Noite da Pizza', requiredPoints: 3000),
          ],
        ),
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('+150'), findsOneWidget);
    expect(find.text('Noite da Pizza liberado!'), findsOneWidget);
    expect(find.text('4 dias seguidos'), findsOneWidget);
  });
}
