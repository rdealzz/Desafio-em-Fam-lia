import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// Entrada em cascata: o bloco sobe alguns pixels enquanto aparece.
///
/// Cada bloco da tela recebe um [ordem] e entra um pouco depois do anterior.
/// É a diferença entre a tela "piscar" pronta e ela se montar diante da
/// pessoa. Roda uma vez só, na primeira construção — rolar a lista ou chegar
/// dado novo não repete a animação.
class Entrada extends StatelessWidget {
  const Entrada({super.key, required this.child, this.ordem = 0});

  final Widget child;
  final int ordem;

  /// Intervalo entre um bloco e o próximo.
  static const Duration _passo = Duration(milliseconds: 45);

  @override
  Widget build(BuildContext context) {
    // Quem pediu menos movimento no sistema recebe a tela pronta.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final atraso = _passo * ordem;
    final total = Motion.slow + atraso;
    final inicio = atraso.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(inicio, 1, curve: Motion.enter),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 14),
          child: child,
        ),
      ),
    );
  }
}

/// Número que corre até o valor novo em vez de trocar de repente.
///
/// Quando o cofre recebe pontos, ver o total subir é metade da recompensa.
/// Na primeira vez sobe do zero; depois, parte do valor anterior quando o
/// dado muda ao vivo.
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado({
    super.key,
    required this.valor,
    required this.formatar,
    this.style,
  });

  final int valor;
  final String Function(int) formatar;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formatar(v.round()), style: style),
    );
  }
}
