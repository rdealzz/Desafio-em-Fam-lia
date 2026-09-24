import 'dart:convert';
import 'dart:io';

import 'package:desafio_em_familia/core/theme/app_theme.dart';
import 'package:desafio_em_familia/models/feed_post.dart';
import 'package:desafio_em_familia/screens/feed/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _agora = DateTime.now();

List<FeedPost> postsDeExemplo({String? foto}) => [
      FeedPost(
        id: 'p1',
        familyId: 'f',
        authorId: 'ana',
        authorName: 'Ana',
        authorAvatar: '🐶',
        type: FeedPostType.activity,
        message: 'Caminhada no parque antes do trabalho!',
        points: 150,
        durationMinutes: 45,
        photoData: foto,
        reactions: const {
          'fire': ['bia', 'caio'],
          'clap': ['eu'],
        },
        metadata: const {'activityType': 'walk', 'steps': 5200, 'streak': 4},
        createdAt: _agora.subtract(const Duration(minutes: 5)),
      ),
      FeedPost(
        id: 'p2',
        familyId: 'f',
        authorId: 'system',
        authorName: 'Cofre',
        type: FeedPostType.rewardUnlocked,
        message: 'Noite da Pizza liberada! O cofre passou de 3.000 pts.',
        createdAt: _agora.subtract(const Duration(hours: 1)),
      ),
      FeedPost(
        id: 'p3',
        familyId: 'f',
        authorId: 'bia',
        authorName: 'Bia com um nome bem comprido para testar',
        type: FeedPostType.impossibleChallenge,
        message: 'Quem fizer 10 polichinelos em vídeo agora ganha +50 pontos',
        createdAt: _agora.subtract(const Duration(days: 1)),
      ),
      FeedPost(
        id: 'p4',
        familyId: 'f',
        authorId: 'caio',
        authorName: 'Caio',
        type: FeedPostType.activity,
        points: 1350,
        durationMinutes: 270,
        metadata: const {'activityType': 'martial_arts', 'offlineSync': true},
        createdAt: _agora.subtract(const Duration(days: 3)),
      ),
    ];

Widget app(Widget child, {bool escuro = false}) => MaterialApp(
      theme: escuro ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: child),
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
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final escuro in [false, true]) {
    testWidgets('mural desenha todos os tipos (${escuro ? 'escuro' : 'claro'})',
        (tester) async {
      await telaPequena(tester);
      await tester.pumpWidget(app(
        MuralLista(
          posts: postsDeExemplo(),
          userId: 'eu',
          onReaction: (_, __) {},
        ),
        escuro: escuro,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('HOJE'), findsOneWidget);
      expect(find.text('ONTEM'), findsOneWidget);
      expect(find.text('treino hoje'), findsOneWidget);
      expect(find.text('+150'), findsWidgets);
    });
  }

  testWidgets('filtro mostra só as cartas', (tester) async {
    await telaPequena(tester);
    await tester.pumpWidget(app(MuralLista(
      posts: postsDeExemplo(),
      userId: 'eu',
      onReaction: (_, __) {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartas'));
    await tester.pumpAndSettle();
    expect(find.text('DESAFIO IMPOSSÍVEL'), findsOneWidget);
    expect(find.textContaining('Caminhada no parque'), findsNothing);
  });

  testWidgets('dois toques na foto dão 🔥 uma vez só', (tester) async {
    await telaPequena(tester);
    final foto = base64Encode(
      File('web/icons/Icon-192.png').readAsBytesSync(),
    );
    final reacoes = <String>[];
    await tester.pumpWidget(app(MuralLista(
      posts: postsDeExemplo(foto: foto),
      userId: 'eu',
      onReaction: (post, r) => reacoes.add('${post.id}:$r'),
    )));
    await tester.pumpAndSettle();

    final alvo = find.byType(Image).first;
    await tester.tap(alvo);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(alvo);
    await tester.pumpAndSettle();
    expect(reacoes, ['p1:fire']);
  });
}
