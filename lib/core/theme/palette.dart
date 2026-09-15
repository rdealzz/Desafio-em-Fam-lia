import 'package:flutter/material.dart';

/// Paleta do app, nos dois modos.
///
/// Três decisões que vieram da pesquisa de referências (Strava, WHOOP e os
/// painéis de 2026):
///
/// 1. **Base quase-preta, não preta.** `#0B0B0F` cansa menos a vista e deixa a
///    elevação visível — em preto puro, sombra não existe.
/// 2. **Um acento só**, reservado a progresso e ação principal. Interface que
///    pinta tudo de cor perde a hierarquia: se tudo grita, nada é ouvido.
/// 3. **Cores de estado são reservadas** e nunca viram decoração.
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
    required this.accentShadow,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// O único acento. Progresso, seleção e ação principal — mais nada.
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  /// Base sólida do botão 3D, um degrau mais escura que o acento.
  final Color accentShadow;

  final Color success;
  final Color warning;
  final Color danger;

  final Color shadow;
  final bool isDark;

  static const Palette dark = Palette(
    bg: Color(0xFF0B0B0F),
    surface: Color(0xFF14141A),
    surfaceRaised: Color(0xFF1C1C24),
    surfaceSunken: Color(0xFF08080B),
    border: Color(0xFF26262F),
    borderStrong: Color(0xFF3A3A47),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFFA1A1B0),
    textMuted: Color(0xFF6C6C7D),
    accent: Color(0xFFC6F24E),
    onAccent: Color(0xFF0B0B0F),
    accentSoft: Color(0x1FC6F24E),
    accentShadow: Color(0xFF8FB82E),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    shadow: Color(0xB3000000),
    isDark: true,
  );

  static const Palette light = Palette(
    bg: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFEFEC),
    border: Color(0xFFE4E4DF),
    borderStrong: Color(0xFFCFCFC8),
    textPrimary: Color(0xFF14141A),
    textSecondary: Color(0xFF5E5E6B),
    textMuted: Color(0xFF9A9AA5),
    // Um degrau mais fechado que no escuro: o mesmo lima sobre branco
    // chapava e sumia.
    accent: Color(0xFF9FD119),
    onAccent: Color(0xFF12180A),
    accentSoft: Color(0x1F9FD119),
    accentShadow: Color(0xFF7BA512),
    success: Color(0xFF109C6C),
    warning: Color(0xFFB77500),
    danger: Color(0xFFD03E3E),
    shadow: Color(0x14000000),
    isDark: false,
  );

  @override
  Palette copyWith({Color? accent}) => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    // Sem interpolação: a troca de tema é um corte, não uma transição de cor
    // a cor. Interpolar 18 cores a cada quadro custa caro e não se percebe.
    if (other is! Palette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Atalho: `context.palette.accent`.
extension PaletteAccess on BuildContext {
  Palette get palette =>
      Theme.of(this).extension<Palette>() ?? Palette.dark;
}
