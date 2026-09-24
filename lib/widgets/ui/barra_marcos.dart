import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// Barra de progresso com gradiente e marcos no caminho.
///
/// Os marcos são os prêmios: um pontinho em cada ponto da barra onde um
/// prêmio libera. Dá para ver de relance que a pizza está logo ali e o açaí
/// só no fim — o que a barra lisa não dizia.
class BarraMarcos extends StatelessWidget {
  const BarraMarcos({
    super.key,
    required this.valor,
    this.marcos = const [],
    this.altura = 12,
    this.inicio = 0,
  });

  /// 0.0 a 1.0.
  final double valor;

  /// Posições dos marcos, de 0.0 a 1.0.
  final List<double> marcos;
  final double altura;

  /// De onde a barra parte na primeira vez. Zero no painel; na comemoração
  /// do registro, o valor de antes — para ver o pedaço que acabou de entrar.
  final double inicio;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = valor.clamp(0.0, 1.0);

    // Largura cheia explícita: dentro de uma Column centralizada a barra
    // encolhia até o tamanho do preenchimento — sumia o trilho e ela ficava
    // no meio do cartão.
    return SizedBox(
      width: double.infinity,
      height: altura,
      child: LayoutBuilder(
        builder: (context, box) {
          final largura = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.surfaceSunken,
                    borderRadius: BorderRadius.circular(altura),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: inicio.clamp(0.0, 1.0), end: v),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animado, _) {
                  if (animado <= 0) return const SizedBox.shrink();
                  // Nunca menor que a altura: um progresso de 1% ainda
                  // aparece como uma pílula, não como um risco.
                  final w = (largura * animado).clamp(altura, largura);
                  return Container(
                    width: w,
                    height: altura,
                    decoration: BoxDecoration(
                      gradient: p.accentGradient,
                      borderRadius: BorderRadius.circular(altura),
                      boxShadow: [
                        BoxShadow(
                          color: p.accent
                              .withValues(alpha: p.isDark ? 0.35 : 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  );
                },
              ),
              for (final m in marcos)
                if (m > 0 && m < 1)
                  Positioned(
                    left: largura * m - 3,
                    top: altura / 2 - 3,
                    child: AnimatedContainer(
                      duration: Motion.base,
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: m <= v
                            ? Colors.white.withValues(alpha: 0.9)
                            : p.borderStrong,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
