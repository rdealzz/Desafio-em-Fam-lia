import 'package:flutter/material.dart';

/// Paleta do app, nos dois modos — as cores de sistema da Apple.
///
/// A primeira versão tinha azul, anil em gradiente, dourado e sombra em quase
/// tudo, e o conjunto ficou com cara de fliperama. Esta segue o iOS:
///
/// - **Cinza de agrupamento, cartão branco, sem borda.** O cartão se separa
///   do fundo pela cor, não por contorno nem sombra (systemGroupedBackground
///   e secondarySystemGroupedBackground). No escuro, preto puro e cinza
///   #1C1C1E, como no iPhone com tela OLED.
/// - **Um azul só (systemBlue), chapado.** Ação, progresso e seleção. Sem
///   gradiente.
/// - **Vermelho, laranja e verde de sistema** para sequência, alerta e
///   sucesso; o "dourado" vira o laranja-amarelo do sistema.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentAlt,
    required this.gold,
    required this.energy,
    required this.energySoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
    required this.isDark,
  });

  /// Fundo da tela — prata claro.
  final Color bg;

  /// Cartão e grupo de lista — branco.
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Azul claro: ação, progresso, seleção.
  final Color accent;
  final Color onAccent;
  final Color accentSoft;


  /// Anil (systemIndigo): cor de apoio para o terceiro lugar do pódio. Nunca
  /// vira cor de ação — isso é só o [accent].
  final Color accentAlt;

  /// Dourado do pódio. Decorativo e raro: primeiro lugar e prêmio liberado.
  final Color gold;


  /// Vermelho: sequência, energia, o que pede atenção.
  final Color energy;
  final Color energySoft;

  final Color success;
  final Color warning;
  final Color danger;

  final Color shadow;
  final bool isDark;

  static const Palette light = Palette(
    bg: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEEEEF0),
    border: Color(0xFFE3E3E8),
    borderStrong: Color(0xFFC6C6C8),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF6C6C70),
    textMuted: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1A007AFF),
    accentAlt: Color(0xFF5856D6),
    gold: Color(0xFFFF9F0A),
    energy: Color(0xFFFF3B30),
    energySoft: Color(0x1AFF3B30),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    danger: Color(0xFFFF3B30),
    shadow: Color(0x0A000000),
    isDark: false,
  );

  static const Palette dark = Palette(
    bg: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceRaised: Color(0xFF2C2C2E),
    surfaceSunken: Color(0xFF2C2C2E),
    border: Color(0xFF38383A),
    borderStrong: Color(0xFF48484A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFAEAEB2),
    textMuted: Color(0xFF8E8E93),
    accent: Color(0xFF0A84FF),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x290A84FF),
    accentAlt: Color(0xFF5E5CE6),
    gold: Color(0xFFFFB340),
    energy: Color(0xFFFF453A),
    energySoft: Color(0x29FF453A),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
    shadow: Color(0x00000000),
    isDark: true,
  );

  @override
  Palette copyWith({Color? accent}) => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    // Sem interpolação: trocar de tema é um corte, não uma transição cor a
    // cor. Interpolar vinte cores por quadro custa caro e não se percebe.
    if (other is! Palette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Atalho: `context.palette.accent`.
extension PaletteAccess on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>() ?? Palette.light;
}
