import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/models/pending_activity.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fila offline é o que segura o registro quando não há internet. Se a
/// serialização falhar, o exercício da pessoa some — por isso os testes aqui
/// cobrem também o caso de dado corrompido.
void main() {
  PendingActivity exemplo({DateTime? performedAt, String? photoPath}) {
    return PendingActivity(
      id: 'pend_123_abc',
      userId: 'uid1',
      familyId: 'fam1',
      typeId: ActivityType.cycling.id,
      durationMinutes: 45,
      steps: 0,
      note: 'pedal até a represa',
      photoPath: photoPath ?? '/dados/foto.jpg',
      performedAt: performedAt ?? DateTime(2026, 9, 15, 7, 30),
    );
  }

  group('Serialização', () {
    test('ida e volta preserva todos os campos', () {
      final original = exemplo();
      final voltou = PendingActivity.fromJson(original.toJson());

      expect(voltou.id, original.id);
      expect(voltou.userId, original.userId);
      expect(voltou.familyId, original.familyId);
      expect(voltou.typeId, original.typeId);
      expect(voltou.durationMinutes, original.durationMinutes);
      expect(voltou.note, original.note);
      expect(voltou.photoPath, original.photoPath);
      expect(voltou.performedAt, original.performedAt);
    });

    test('a modalidade volta certa do id persistido', () {
      final voltou = PendingActivity.fromJson(exemplo().toJson());
      expect(voltou.type, ActivityType.cycling);
    });

    test('lista completa sobrevive à codificação', () {
      final lista = [exemplo(), exemplo()];
      final decodificada =
          PendingActivity.decodeList(PendingActivity.encodeList(lista));
      expect(decodificada.length, 2);
      expect(decodificada.first.typeId, ActivityType.cycling.id);
    });
  });

  group('Robustez', () {
    test('fila vazia ou nula devolve lista vazia', () {
      expect(PendingActivity.decodeList(null), isEmpty);
      expect(PendingActivity.decodeList(''), isEmpty);
    });

    test('JSON corrompido não derruba o app', () {
      expect(PendingActivity.decodeList('{nao é json'), isEmpty);
      expect(PendingActivity.decodeList('"texto solto"'), isEmpty);
      expect(PendingActivity.decodeList('42'), isEmpty);
    });

    test('campos faltando caem em valores neutros', () {
      final parcial = PendingActivity.fromJson({'id': 'x'});
      expect(parcial.id, 'x');
      expect(parcial.durationMinutes, 0);
      expect(parcial.steps, 0);
      expect(parcial.photoPath, isNull);
    });
  });

  group('Validade', () {
    test('registro de agora não está vencido', () {
      expect(exemplo(performedAt: DateTime.now()).isExpired, isFalse);
    });

    test('registro de ontem ainda vale', () {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      expect(exemplo(performedAt: ontem).isExpired, isFalse);
    });

    test('registro de 3 dias atrás venceu', () {
      final antigo = DateTime.now().subtract(const Duration(days: 3));
      expect(exemplo(performedAt: antigo).isExpired, isTrue);
    });
  });

  group('copyWith', () {
    test('conta tentativas sem perder o resto', () {
      final tentado = exemplo().copyWith(attempts: 2, lastError: 'sem rede');
      expect(tentado.attempts, 2);
      expect(tentado.lastError, 'sem rede');
      expect(tentado.id, 'pend_123_abc');
      expect(tentado.durationMinutes, 45);
      expect(tentado.photoPath, '/dados/foto.jpg');
    });
  });
}
