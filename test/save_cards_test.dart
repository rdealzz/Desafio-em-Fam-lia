import 'package:flutter_test/flutter_test.dart';

import 'package:desafio_em_familia/core/utils/week_utils.dart';
import 'package:desafio_em_familia/models/app_user.dart';

AppUser _user({required int saveCards, required String semana}) => AppUser(
      id: 'u1',
      familyId: 'f1',
      displayName: 'Teste',
      saveCards: saveCards,
      saveCardsWeekId: semana,
    );

void main() {
  final estaSemana = WeekUtils.currentWeekId();
  final semanaPassada =
      WeekUtils.weekId(DateTime.now().subtract(const Duration(days: 7)));

  group('Cartas Salva-Mãe/Pai', () {
    test('gastou a carta desta semana, fica sem', () {
      expect(_user(saveCards: 0, semana: estaSemana).cartasDisponiveis, 0);
    });

    test('a carta volta sozinha na virada da semana', () {
      // O caso que motivou o campo: sem ele, saveCards ficava 0 para sempre e
      // a carta nunca mais aparecia.
      expect(_user(saveCards: 0, semana: semanaPassada).cartasDisponiveis,
          AppUser.cartasPorSemana);
    });

    test('quem ainda não usou tem a cota da semana', () {
      expect(_user(saveCards: 1, semana: estaSemana).cartasDisponiveis, 1);
    });

    test('perfil antigo, sem o campo, ganha a cota cheia', () {
      expect(_user(saveCards: 0, semana: '').cartasDisponiveis,
          AppUser.cartasPorSemana);
    });
  });
}
