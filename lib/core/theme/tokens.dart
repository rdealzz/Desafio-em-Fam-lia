import 'package:flutter/widgets.dart';

/// Medidas do sistema. Nada de número solto no meio da tela: espaçamento,
/// canto e duração saem daqui, e é isso que faz a interface parecer de uma
/// peça só em vez de montada aos pedaços.
class Space {
  const Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  /// Margem lateral das telas.
  static const double gutter = 20;
}

class Radii {
  const Radii._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  /// Raios na escala da Apple: botão um pouco mais fechado que o cartão.
  static const double button = 14;
  static const double card = 16;

  /// Grupo de lista embutida (estilo Ajustes do iOS).
  static const double group = 12;

  /// Folha deslizante — só o topo arredondado.
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(xl));
}

/// Durações curtas o bastante para não atrasar a interação.
///
/// Acima de ~250 ms a animação começa a parecer lentidão em vez de resposta.
class Motion {
  const Motion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 340);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

}
