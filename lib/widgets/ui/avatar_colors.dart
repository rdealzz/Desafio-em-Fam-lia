import 'package:flutter/material.dart';

/// Cores de perfil.
///
/// Decorativas de propósito: quem identifica a pessoa é a foto, a inicial e o
/// nome ao lado. A cor serve para dar personalidade e para bater o olho e
/// saber de quem é a linha.
class AvatarColors {
  const AvatarColors._();

  static const List<Color> opcoes = [
    Color(0xFF2E90FA), // azul
    Color(0xFFE5484D), // vermelho
    Color(0xFF12A366), // verde
    Color(0xFFB76E00), // âmbar
    Color(0xFF8B5CF6), // roxo
    Color(0xFF0E9BA8), // turquesa
    Color(0xFFDB2777), // rosa
    Color(0xFF64748B), // grafite
  ];

  /// Cor de quem ainda não escolheu: derivada do id, estável entre sessões.
  ///
  /// Sem isso a família inteira começaria com a mesma cor, e o avatar deixaria
  /// de ajudar a distinguir as linhas da lista.
  static Color paraId(String id) {
    if (id.isEmpty) return opcoes.first;
    final soma = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return opcoes[soma % opcoes.length];
  }

  static Color resolver(int valor, String id) =>
      valor == 0 ? paraId(id) : Color(valor);
}
