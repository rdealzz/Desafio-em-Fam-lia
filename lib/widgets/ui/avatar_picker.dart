import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../avatar_bubble.dart' show AnimalGlyph;
import 'avatar_animals.dart';
import 'avatar_colors.dart';

/// Escolha do bicho do perfil.
///
/// Grade fixa em vez de lista que rola: são 22 bichos, cabem em quatro linhas,
/// e vendo todos de uma vez a escolha é imediata — rolar uma lista horizontal
/// esconde metade das opções e é o tipo de atrito que faz alguém desistir e
/// ficar com o primeiro.
class SeletorAnimal extends StatelessWidget {
  const SeletorAnimal({
    super.key,
    required this.selecionado,
    required this.cor,
    required this.onSelected,
  });

  /// Emoji escolhido. Valor fora da lista conta como "nenhum".
  final String selecionado;

  /// Cor do perfil: o fundo de cada bolinha usa ela, então dá para ver como o
  /// avatar vai ficar antes de salvar.
  final Color cor;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final fundo = Color.alphaBlend(cor.withValues(alpha: 0.18), Colors.white);

    return GridView.builder(
      // Dentro de um InsetGroup, que já rola: a grade não rola sozinha.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: Space.md,
        crossAxisSpacing: Space.md,
      ),
      itemCount: AvatarAnimals.opcoes.length,
      itemBuilder: (context, i) {
        final animal = AvatarAnimals.opcoes[i];
        return _Bolinha(
          animal: animal,
          fundo: fundo,
          cor: cor,
          ativo: animal.emoji == selecionado,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(animal.emoji);
          },
        );
      },
    );
  }
}

class _Bolinha extends StatelessWidget {
  const _Bolinha({
    required this.animal,
    required this.fundo,
    required this.cor,
    required this.ativo,
    required this.onTap,
  });

  final AnimalAvatar animal;
  final Color fundo;
  final Color cor;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: animal.nome,
      selected: ativo,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: fundo,
            shape: BoxShape.circle,
            // O escolhido ganha um anel da cor do perfil; os outros ficam sem
            // borda. Marca só um, sem pintar a grade inteira de contorno.
            border: Border.all(
              color: ativo ? cor : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, c) =>
                  AnimalGlyph(emoji: animal.emoji, size: c.maxWidth * 0.58),
            ),
          ),
        ),
      ),
    );
  }
}

/// Escolha da cor do perfil — o fundo do bicho.
class SeletorCor extends StatelessWidget {
  const SeletorCor({
    super.key,
    required this.selecionada,
    required this.onSelected,
  });

  final int selecionada;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AvatarColors.opcoes.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.md),
        itemBuilder: (context, i) {
          final cor = AvatarColors.opcoes[i];
          final ativo = cor.toARGB32() == selecionada;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(cor.toARGB32());
            },
            child: AnimatedContainer(
              duration: Motion.fast,
              width: 36,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ativo
                      ? context.palette.textPrimary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ativo
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
