import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_type.dart';

/// O último treino registrado neste aparelho.
///
/// Quase todo mundo repete a mesma coisa: a caminhada de 40 min de sempre, a
/// academia de 1 h. Guardando a modalidade e o tempo, a tela de registro já
/// abre no que a pessoa costuma fazer, e o "repetir" vira um toque só.
class UltimoTreino {
  const UltimoTreino({required this.tipo, required this.minutos});

  final ActivityType tipo;
  final int minutos;

  static const String _chaveTipo = 'ultimo_treino_tipo';
  static const String _chaveMinutos = 'ultimo_treino_minutos';

  /// `null` quando nunca houve registro aqui, ou quando o guardado não vale
  /// mais (modalidade removida, tempo fora da faixa).
  static Future<UltimoTreino?> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_chaveTipo);
      final minutos = prefs.getInt(_chaveMinutos);
      if (id == null || minutos == null || minutos <= 0 || minutos > 300) {
        return null;
      }
      final tipo = ActivityType.values.where((t) => t.id == id);
      if (tipo.isEmpty) return null;
      return UltimoTreino(tipo: tipo.first, minutos: minutos);
    } catch (_) {
      // Sem armazenamento (aba anônima): só não lembra, o resto funciona.
      return null;
    }
  }

  static Future<void> salvar(ActivityType tipo, int minutos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveTipo, tipo.id);
      await prefs.setInt(_chaveMinutos, minutos);
    } catch (_) {
      // Lembrar é conforto; falhar aqui não pode atrapalhar o registro.
    }
  }
}
