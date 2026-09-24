import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens.dart';

/// Tema do app nos dois modos.
///
/// A escala tipográfica tem poucos degraus e bastante contraste entre eles —
/// é o que separa uma interface que parece projetada de uma que parece
/// montada. Números de estatística usam figuras tabulares: sem isso, o total
/// do cofre "dança" a cada atualização porque cada dígito tem largura própria.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Inter';

  /// Dígitos de largura fixa. Essencial em número que muda ao vivo.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static ThemeData dark() => _build(Palette.dark);
  static ThemeData light() => _build(Palette.light);

  static ThemeData _build(Palette p) {
    final scheme = ColorScheme(
      brightness: p.isDark ? Brightness.dark : Brightness.light,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: p.isDark ? const Color(0xFF14141A) : Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
    );

    // A fonte vai em cada estilo, e não só em ThemeData.fontFamily: os temas
    // de botão e da barra de título recebem estes estilos direto, e sem a
    // família neles o texto caía na fonte padrão do sistema.
    final text = _textTheme(p).apply(fontFamily: fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      fontFamily: fontFamily,
      textTheme: text,
      extensions: [p],

      // Respingo de toque some: o retorno tátil vem do próprio botão afundando,
      // e a onda do Material por cima só suja a animação.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        titleTextStyle: text.titleMedium,
        systemOverlayStyle:
            p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Campo branco sobre o cinza, como nos formulários do iOS.
        fillColor: p.surface,
        hintStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.danger),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.accentSoft,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color:
                states.contains(WidgetState.selected) ? p.accent : p.textMuted,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor:
            p.isDark ? const Color(0xCC000000) : const Color(0x66000000),
        shape: const RoundedRectangleBorder(borderRadius: Radii.sheet),
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surfaceRaised,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.surfaceSunken,
        thumbColor: p.accent,
        overlayColor: p.accentSoft,
        trackHeight: 4,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          textStyle: text.labelLarge,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
      ),

      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
    );
  }

  /// Escala do iOS (Large Title, Title, Headline, Body, Footnote), com a
  /// Inter no lugar da SF. Bold no máximo: o ExtraBold de antes pesava e
  /// deixava os números com cara de placar de fliperama.
  static TextTheme _textTheme(Palette p) {
    return TextTheme(
      // Número de estatística: o dado é o herói da tela.
      displayLarge: TextStyle(
        fontSize: 48,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
        color: p.textPrimary,
        fontFeatures: tabular,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: p.textPrimary,
        fontFeatures: tabular,
      ),
      // Large Title.
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        color: p.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.45,
        color: p.textPrimary,
      ),
      // Headline.
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: p.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        color: p.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: p.textSecondary,
      ),
      // Footnote.
      bodySmall: TextStyle(
        fontSize: 13,
        height: 1.35,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        color: p.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 15.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: p.textPrimary,
      ),
      // Cabeçalho de grupo do iOS: caixa alta pequena, peso normal, cinza.
      // Estrutura a tela sem gritar.
      labelMedium: TextStyle(
        fontSize: 12.5,
        height: 1.2,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: p.textMuted,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: p.textSecondary,
      ),
    );
  }
}
