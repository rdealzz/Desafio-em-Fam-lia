import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:desafio_em_familia/models/feed_post.dart';
import 'package:desafio_em_familia/services/app_exception.dart';
import 'package:desafio_em_familia/services/photo_proof.dart';

FeedPost _post({String? dados, DateTime? vence}) => FeedPost(
      id: 'p1',
      familyId: 'f1',
      authorId: 'u1',
      authorName: 'Teste',
      type: FeedPostType.activity,
      message: 'Corrida',
      photoData: dados,
      photoExpiresAt: vence,
    );

void main() {
  final foto = base64Encode(Uint8List.fromList([1, 2, 3, 4]));
  final ontem = DateTime.now().subtract(const Duration(hours: 25));
  final daquiAPouco = DateTime.now().add(const Duration(hours: 3));

  group('Codificar', () {
    test('ida e volta devolve os mesmos bytes', () {
      final bytes = Uint8List.fromList([9, 8, 7, 255, 0]);
      expect(PhotoProof.decodificar(PhotoProof.codificar(bytes)), bytes);
    });

    test('recusa foto acima do teto do documento', () {
      final gorda = Uint8List(PhotoProof.bytesMaximos + 1);
      expect(() => PhotoProof.codificar(gorda), throwsA(isA<AppException>()));
    });

    test('recusa foto vazia', () {
      expect(() => PhotoProof.codificar(Uint8List(0)),
          throwsA(isA<AppException>()));
    });

    test('base64 estragado vira nulo em vez de derrubar o mural', () {
      expect(PhotoProof.decodificar('isto não é base64 %%%'), isNull);
    });
  });

  group('Prazo de um dia', () {
    test('foto de hoje aparece', () {
      expect(PhotoProof.venceu(daquiAPouco), isFalse);
      expect(_post(dados: foto, vence: daquiAPouco).photoData, isNotNull);
    });

    test('foto de ontem já venceu', () {
      expect(PhotoProof.venceu(ontem), isTrue);
    });

    test('sem prazo marcado, não vence (registro antigo)', () {
      expect(PhotoProof.venceu(null), isFalse);
    });

    test('o vencimento cai um dia à frente', () {
      final base = DateTime(2026, 3, 10, 8, 0);
      expect(PhotoProof.vencimento(base), DateTime(2026, 3, 11, 8, 0));
    });
  });
}
