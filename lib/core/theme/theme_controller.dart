import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo claro, escuro ou o do sistema — lembrado entre sessões.
///
/// Começa no CLARO. O escuro continua disponível no menu e a escolha é
/// lembrada, mas quem abre o app pela primeira vez vê o modo claro.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _carregar();
  }

  static const String _key = 'theme_mode_v1';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.dark) return true;
    if (_mode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_key);
      if (salvo == null) return;
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == salvo,
        orElse: () => ThemeMode.light,
      );
      notifyListeners();
    } catch (_) {
      // Preferência é conforto, não requisito: falhar aqui não pode impedir
      // o app de abrir.
    }
  }

  Future<void> definir(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  /// Alterna entre claro e escuro a partir do que está valendo agora.
  Future<void> alternar(BuildContext context) =>
      definir(isDark(context) ? ThemeMode.light : ThemeMode.dark);
}
