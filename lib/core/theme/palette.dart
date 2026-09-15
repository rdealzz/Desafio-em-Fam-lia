import 'package:flutter/material.dart';

/// Paleta do app, nos dois modos.
///
/// Claro e prateado, com azul claro como ação e vermelho como energia.
///
/// - **Fundo prata, cartão branco.** É a estrutura do iOS: o conteúdo flutua
///   em branco sobre um cinza levíssimo. Cartão branco sobre fundo branco não
///   tem separação nenhuma; o prata é o que faz o agrupamento aparecer sem
///   precisar de borda grossa nem sombra pesada.
/// - **Azul é ação, vermelho é energia.** Dois papéis distintos, nunca
///   trocados: azul em botão, progresso e seleção; vermelho em sequência,
///   alerta e no que precisa de atenção.
/// - **Cores de estado são reservadas** e nunca viram decoração.
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

  /// Base sólida do botão 3D, um degrau mais fechada que o azul.
  final Color accentShadow;

  /// Vermelho: sequência, energia, o que pede atenção.
  final Color energy;
  final Color energySoft;

  final Color success;
  final Color warning;
  final Color danger;

  final Color shadow;
  final bool isDark;

  static const Palette light = Palette(
    bg: Color(0xFFF2F3F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEDEEF3),
    border: Color(0xFFE1E3EA),
    borderStrong: Color(0xFFC7CAD4),
    textPrimary: Color(0xFF14161C),
    textSecondary: Color(0xFF61656F),
    textMuted: Color(0xFF9A9EA9),
    accent: Color(0xFF2E90FA),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1F2E90FA),
    accentShadow: Color(0xFF1B6FC9),
    energy: Color(0xFFE5484D),
    energySoft: Color(0x1FE5484D),
    success: Color(0xFF12A366),
    warning: Color(0xFFB76E00),
    danger: Color(0xFFE5484D),
    shadow: Color(0x12000000),
    isDark: false,
  );

  static const Palette dark = Palette(
    bg: Color(0xFF0E1015),
    surface: Color(0xFF181B22),
    surfaceRaised: Color(0xFF20242D),
    surfaceSunken: Color(0xFF0A0C10),
    border: Color(0xFF2A2F3A),
    borderStrong: Color(0xFF3D4351),
    textPrimary: Color(0xFFF3F4F7),
    textSecondary: Color(0xFFA3A8B4),
    textMuted: Color(0xFF6E7480),
    // Um degrau mais claro no escuro: o mesmo azul do modo claro
    // desaparecia contra o fundo.
    accent: Color(0xFF5AAAFF),
    onAccent: Color(0xFF07101C),
    accentSoft: Color(0x2E5AAAFF),
    accentShadow: Color(0xFF2E7CC9),
    energy: Color(0xFFFF6369),
    energySoft: Color(0x2EFF6369),
    success: Color(0xFF3DD68C),
    warning: Color(0xFFFFC14D),
    danger: Color(0xFFFF6369),
    shadow: Color(0x66000000),
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
