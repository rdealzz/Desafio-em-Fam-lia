import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../models/app_user.dart';
import 'ui/avatar_animals.dart';
import 'ui/avatar_colors.dart';

/// Avatar do integrante: a foto, se tiver; senão o bicho escolhido sobre um
/// fundo da cor do perfil.
///
/// O bicho vem de uma fonte de emoji empacotada (ver [AvatarAnimals]) — sem
/// ela o navegador desenharia quadradinho, que foi o que aconteceu na primeira
/// versão. Quem ainda não escolheu recebe um bicho sorteado pelo id, então
/// ninguém abre o app com um círculo vazio.
///
/// O anel cheio marca quem treinou hoje; quem não treinou fica com traço
/// apagado. Diferença de peso, não de cor berrante.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.user,
    this.size = 40,
    this.showRing = true,
  });

  final AppUser user;
  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ativo = user.isActiveToday;
    final temFoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(showRing ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showRing
            ? Border.all(
                // Anel forte em quem treinou hoje, apagado em quem não.
                color: ativo
                    ? AvatarColors.resolver(user.avatarColor, user.id)
                    : p.border,
                width: ativo ? 2 : 1.5,
              )
            : null,
      ),
      child: ClipOval(
        child: temFoto
            ? Image.network(
                user.photoUrl!,
                fit: BoxFit.cover,
                // Decodifica no tamanho exibido, não no original da câmera.
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => _Bicho(user: user, size: size),
              )
            : _Bicho(user: user, size: size),
      ),
    );
  }
}

class _Bicho extends StatelessWidget {
  const _Bicho({required this.user, required this.size});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cor = AvatarColors.resolver(user.avatarColor, user.id);
    return ColoredBox(
      // Fundo suave da cor escolhida: o bicho aparece sobre a cor dele, não
      // sobre um branco chapado.
      color: Color.alphaBlend(cor.withValues(alpha: 0.18), Colors.white),
      child: Center(
        child: AnimalGlyph(
          emoji: AvatarAnimals.resolver(user.avatarEmoji, user.id),
          // Deixa uma margem para o bicho não encostar na borda do círculo.
          size: size * 0.56,
        ),
      ),
    );
  }
}

/// Desenha um emoji de bicho com a fonte empacotada.
///
/// Existe como widget próprio para o nome da família da fonte ficar num lugar
/// só: se o recorte da fonte mudar de nome, muda aqui.
class AnimalGlyph extends StatelessWidget {
  const AnimalGlyph({super.key, required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontFamily: AvatarAnimals.fontFamily,
        fontSize: size,
        // A Noto Color Emoji é de bitmap e vem com entrelinha folgada; sem
        // travar a altura o desenho fica descentralizado no círculo.
        height: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }
}
