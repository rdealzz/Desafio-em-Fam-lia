import 'package:flutter/material.dart';

import '../../models/feed_post.dart';

/// Ícone de cada reação.
///
/// O modelo guarda a chave (`fire`, `clap`…) e um emoji, mas a interface usa
/// ícone: no navegador o CanvasKit do Flutter não carrega fonte de emoji, e
/// todos eles viram quadradinho. Ícone renderiza em qualquer plataforma.
IconData iconForReaction(String chave) {
  switch (chave) {
    case 'fire':
      return Icons.local_fire_department_rounded;
    case 'muscle':
      return Icons.fitness_center_rounded;
    case 'clap':
      return Icons.celebration_rounded;
    case 'laugh':
      return Icons.sentiment_very_satisfied_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    default:
      return Icons.thumb_up_rounded;
  }
}

/// Ícone do prêmio, a partir do emoji configurado pela família.
///
/// Mapeia os sugeridos e cai num presente genérico para qualquer outro.
IconData iconForReward(String emoji) {
  switch (emoji) {
    case '🍕':
      return Icons.local_pizza_rounded;
    case '🎲':
      return Icons.casino_rounded;
    case '🍨':
      return Icons.icecream_rounded;
    case '🎡':
      return Icons.attractions_rounded;
    case '🎬':
      return Icons.movie_rounded;
    case '☕':
      return Icons.local_cafe_rounded;
    default:
      return Icons.card_giftcard_rounded;
  }
}

/// Ícone do tipo de publicação do mural.
IconData iconForPostType(FeedPostType tipo) {
  switch (tipo) {
    case FeedPostType.activity:
      return Icons.bolt_rounded;
    case FeedPostType.saveCard:
      return Icons.volunteer_activism_rounded;
    case FeedPostType.impossibleChallenge:
      return Icons.local_fire_department_rounded;
    case FeedPostType.punishment:
      return Icons.theater_comedy_rounded;
    case FeedPostType.rewardUnlocked:
      return Icons.emoji_events_rounded;
    case FeedPostType.system:
      return Icons.campaign_rounded;
  }
}
