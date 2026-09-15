import 'package:flutter/material.dart';

/// Identidade visual do app: cores quentes de família, cantos bem arredondados
/// e alvos de toque grandes (a mãe e o pai precisam acertar de primeira).
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF6C4DF6); // roxo do cofre
  static const Color secondary = Color(0xFFFF8A3D); // laranja do incentivo
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFC542);
  static const Color danger = Color(0xFFE85C5C);
  static const Color surface = Color(0xFFF6F5FB);
  static const Color ink = Color(0xFF1C1B2E);
  static const Color inkSoft = Color(0xFF6E6B8A);

  /// Cor por GRUPO de atividade, não por modalidade.
  ///
  /// Com sete modalidades, sete cores de identidade reprovam no validador de
  /// daltonismo: a pior dupla fica a ΔE 1,1 em deuteranopia — indistinguível.
  /// Três cores de grupo passam em todos os pares (pior: ΔE 7,7 CVD e 15,1
  /// visão normal), e a cor passa a dizer algo útil — onde o treino acontece.
  ///
  /// O 7,7 está na faixa que só vale com codificação secundária, e ela existe:
  /// toda modalidade aparece sempre com emoji e rótulo, nunca cor sozinha.
  ///
  /// Validado com scripts/validate_palette.js da skill dataviz, critério
  /// --pairs all (as modalidades aparecem todas juntas na grade).
  static const Map<String, Color> activityGroup = {
    'outdoor': Color(0xFF3DA5FF), // azul
    'training': Color(0xFFF08C00), // laranja
    'home': Color(0xFFB15BD8), // roxo
  };

  static const LinearGradient vaultGradient = LinearGradient(
    colors: [Color(0xFF6C4DF6), Color(0xFF9B6BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  const AppTheme._();

  static const double radius = 24;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE7E5F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 13, color: AppColors.inkSoft),
      ),
    );
  }
}
