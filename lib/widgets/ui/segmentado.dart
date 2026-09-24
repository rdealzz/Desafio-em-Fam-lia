import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// Controle segmentado do iOS: trilho cinza, a opção escolhida num bloco
/// branco que desliza entre as outras.
class Segmentado<T> extends StatelessWidget {
  const Segmentado({
    super.key,
    required this.opcoes,
    required this.atual,
    required this.onMudar,
  });

  /// Valor e rótulo de cada opção, na ordem em que aparecem.
  final Map<T, String> opcoes;
  final T atual;
  final ValueChanged<T> onMudar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final valores = opcoes.keys.toList();
    final indice = valores.indexOf(atual).clamp(0, valores.length - 1);

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // Cinza sobre o cinza do fundo: o trilho do segmentado do iOS.
        color: p.isDark ? p.surfaceRaised : const Color(0x1F767680),
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final largura = box.maxWidth / valores.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.enter,
                left: largura * indice,
                top: 0,
                bottom: 0,
                width: largura,
                child: Container(
                  decoration: BoxDecoration(
                    color: p.isDark ? const Color(0xFF636366) : p.surface,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in valores)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onMudar(v),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.fast,
                            style: t.labelLarge!.copyWith(
                              fontSize: 13.5,
                              color:
                                  v == atual ? p.textPrimary : p.textSecondary,
                            ),
                            child: Text(
                              opcoes[v]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
