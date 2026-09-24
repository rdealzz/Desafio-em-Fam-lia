import 'package:desafio_em_familia/models/activity_type.dart';
import 'package:desafio_em_familia/services/ultimo_treino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sem registro anterior não sugere nada', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await UltimoTreino.carregar(), isNull);
  });

  test('guarda e devolve modalidade e tempo', () async {
    SharedPreferences.setMockInitialValues({});
    await UltimoTreino.salvar(ActivityType.gym, 60);
    final u = await UltimoTreino.carregar();
    expect(u?.tipo, ActivityType.gym);
    expect(u?.minutos, 60);
  });

  test('ignora valor guardado que não vale mais', () async {
    SharedPreferences.setMockInitialValues({
      'ultimo_treino_tipo': 'paraquedas',
      'ultimo_treino_minutos': 30,
    });
    expect(await UltimoTreino.carregar(), isNull);

    SharedPreferences.setMockInitialValues({
      'ultimo_treino_tipo': 'walk',
      'ultimo_treino_minutos': 9999,
    });
    expect(await UltimoTreino.carregar(), isNull);
  });
}
