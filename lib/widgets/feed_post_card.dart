import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/firestore_utils.dart';
import '../core/utils/formatters.dart';
import '../models/activity_type.dart';
import '../models/feed_post.dart';
import 'avatar_bubble.dart';
import 'ui/activity_icons.dart';
import 'ui/avatar_animals.dart';
import 'ui/feed_photo.dart';
import 'ui/primitives.dart';
import 'ui/reaction_icons.dart';

/// Publicação do mural.
///
/// Três formatos, porque são três coisas diferentes:
///
/// - **Treino**: quem, o quê e quanto rendeu no topo; a foto com cantos
///   próprios, recuada do cartão como numa revista; e as reações embaixo.
///   Dois toques na foto dão 🔥, como todo mundo já espera de um feed.
/// - **Carta** (desafio, punição, salva): uma faixa na cor da carta com o
///   ícone, e o texto em destaque — a carta *é* a frase.
/// - **Prêmio liberado**: cartão dourado. É o momento de comemorar da semana,
///   não pode parecer mais um post.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onReaction,
  });

  final FeedPost post;
  final String currentUserId;
  final ValueChanged<String> onReaction;

  /// A reação dos dois toques na foto.
  static const String reacaoRapida = 'fire';

  bool get _premio =>
      post.type == FeedPostType.rewardUnlocked ||
      post.type == FeedPostType.system;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final foto = FeedPhoto.para(post);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          // Prêmio liberado ganha um tom quente chapado; o resto é o cartão
          // branco de sempre, sem contorno nem sombra.
          color: _premio
              ? Color.alphaBlend(
                  p.gold.withValues(alpha: p.isDark ? 0.16 : 0.10),
                  p.surface,
                )
              : p.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isCard) _Faixa(post: post),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.lg,
                Space.lg,
                0,
              ),
              child: _Cabecalho(post: post),
            ),
            if (post.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  0,
                ),
                child: _Mensagem(post: post),
              ),
            if (post.durationMinutes > 0 ||
                post.metadata['offlineSync'] == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  0,
                ),
                child: _Metadados(post: post),
              ),
            if (foto != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.md,
                  Space.md,
                  0,
                ),
                child: _FotoComToqueDuplo(
                  foto: foto,
                  onToqueDuplo: () {
                    // Toque duplo só liga: desligar por engano seria pior do
                    // que não fazer nada.
                    if (post.hasReacted(reacaoRapida, currentUserId)) return;
                    HapticFeedback.mediumImpact();
                    onReaction(reacaoRapida);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final e in Reactions.available.entries)
                    _Reacao(
                      icone: iconForReaction(e.key),
                      count: post.reactionCount(e.key),
                      ativa: post.hasReacted(e.key, currentUserId),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onReaction(e.key);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar, nome, o que fez e quando — e os pontos em destaque à direita.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final quando =
        post.createdAt == null ? 'agora' : Formatters.timeAgo(post.createdAt!);
    final treino = post.type == FeedPostType.activity;
    final tipo = treino
        ? ActivityType.fromId(post.metadata['activityType'] as String?)
        : null;

    final oQue = switch (post.type) {
      FeedPostType.activity => tipo!.label,
      FeedPostType.saveCard => 'usou a Salva-Mãe/Pai',
      FeedPostType.impossibleChallenge => 'lançou um desafio',
      FeedPostType.punishment => 'lançou uma prenda',
      FeedPostType.rewardUnlocked => 'prêmio liberado',
      FeedPostType.system => 'aviso',
    };

    return Row(
      children: [
        _AvatarAutor(post: post),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorId == 'system'
                    ? 'Cofre da família'
                    : post.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (tipo != null) ...[
                    Icon(iconForActivity(tipo), size: 13, color: p.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      '$oQue · $quando',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (post.points > 0) ...[
          const SizedBox(width: Space.sm),
          _Pontos(pontos: post.points),
        ],
      ],
    );
  }
}

/// Foto do autor, ou o bicho dele; o troféu quando quem fala é o app.
class _AvatarAutor extends StatelessWidget {
  const _AvatarAutor({required this.post});

  final FeedPost post;

  static const double _tam = 40;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Aviso do próprio app (prêmio liberado) não tem dono: leva o troféu em
    // vez de um bicho sorteado, que sugeriria que alguém publicou aquilo.
    final doApp = post.authorId == 'system';
    final temFoto =
        post.authorPhotoUrl != null && post.authorPhotoUrl!.isNotEmpty;

    final bicho = ColoredBox(
      color: doApp ? p.gold.withValues(alpha: 0.18) : p.surfaceSunken,
      child: Center(
        child: doApp
            ? Icon(Icons.emoji_events_rounded, size: 20, color: p.gold)
            : AnimalGlyph(
                emoji: AvatarAnimals.resolver(post.authorAvatar, post.authorId),
                size: 22,
              ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: _tam,
        height: _tam,
        child: temFoto
            ? Image.network(
                post.authorPhotoUrl!,
                fit: BoxFit.cover,
                cacheWidth: 120,
                errorBuilder: (_, __, ___) => bicho,
              )
            : bicho,
      ),
    );
  }
}

/// "+150" num selo azul-claro, como os badges do iOS: são os pontos que
/// entraram.
class _Pontos extends StatelessWidget {
  const _Pontos({required this.pontos});

  final int pontos;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        '+${Formatters.points(pontos)}',
        style: TextStyle(
          color: p.accent,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// O texto do post. Em carta, a frase é o conteúdo: fica maior.
class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final destaque = post.isCard ||
        post.type == FeedPostType.rewardUnlocked ||
        post.type == FeedPostType.system;

    return Text(
      post.message,
      style: destaque
          ? t.titleMedium?.copyWith(fontSize: 17, height: 1.35)
          : t.bodyLarge,
    );
  }
}

class _Metadados extends StatelessWidget {
  const _Metadados({required this.post});

  final FeedPost post;

  static int _num(Object? v) => v is num ? v.toInt() : 0;

  static String _rotuloOffline(FeedPost post) {
    final at = FirestoreUtils.toDateTime(post.metadata['performedAt']);
    return at == null ? 'offline' : 'feito ${Formatters.timeAgo(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final passos = _num(post.metadata['steps']);
    final sequencia = _num(post.metadata['streak']);

    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        if (post.durationMinutes > 0)
          MetaChip(
            icon: Icons.schedule_rounded,
            label: Formatters.duration(post.durationMinutes),
          ),
        if (passos > 0)
          MetaChip(
            icon: Icons.directions_walk_rounded,
            label: '${Formatters.points(passos)} passos',
          ),
        if (sequencia > 1)
          MetaChip(
            icon: Icons.local_fire_department_rounded,
            label: '$sequencia dias seguidos',
            tone: p.energy,
          ),
        if (post.metadata['offlineSync'] == true)
          MetaChip(
            icon: Icons.cloud_done_outlined,
            label: _rotuloOffline(post),
          ),
      ],
    );
  }
}

/// A foto com cantos próprios e o 🔥 que aparece no toque duplo.
class _FotoComToqueDuplo extends StatefulWidget {
  const _FotoComToqueDuplo({required this.foto, required this.onToqueDuplo});

  final Widget foto;
  final VoidCallback onToqueDuplo;

  @override
  State<_FotoComToqueDuplo> createState() => _FotoComToqueDuploState();
}

class _FotoComToqueDuploState extends State<_FotoComToqueDuplo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  // Cresce com mola, segura um instante e some.
  late final Animation<double> _escala = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 0.4, end: 1.15)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
  ]).animate(_c);

  late final Animation<double> _opacidade = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        widget.onToqueDuplo();
        _c.forward(from: 0);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.foto,
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _c.isDismissed
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: _opacidade.value,
                        child: Transform.scale(
                          scale: _escala.value,
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            size: 88,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pílula de reação que dá um pulinho quando é ligada.
class _Reacao extends StatefulWidget {
  const _Reacao({
    required this.icone,
    required this.count,
    required this.ativa,
    required this.onTap,
  });

  final IconData icone;
  final int count;
  final bool ativa;
  final VoidCallback onTap;

  @override
  State<_Reacao> createState() => _ReacaoState();
}

class _ReacaoState extends State<_Reacao> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _escala = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(_Reacao anterior) {
    super.didUpdateWidget(anterior);
    // Pula quando liga, venha de onde vier (toque aqui ou toque duplo na
    // foto). Desligar é silencioso.
    if (widget.ativa && !anterior.ativa) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ativa = widget.ativa;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _escala,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: ativa ? p.accentSoft : p.surfaceSunken,
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icone,
                size: 16,
                color: ativa ? p.accent : p.textSecondary,
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '${widget.count}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ativa ? p.accent : p.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa das cartas: a cor e o ícone da carta, num tom suave.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cor = switch (post.type) {
      FeedPostType.impossibleChallenge => p.warning,
      FeedPostType.punishment => p.danger,
      _ => p.accent,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: p.isDark ? 0.18 : 0.10),
      ),
      child: Row(
        children: [
          Icon(iconForPostType(post.type), size: 16, color: cor),
          const SizedBox(width: Space.sm),
          Text(
            switch (post.type) {
              FeedPostType.saveCard => 'CARTA SALVA-MÃE/PAI',
              FeedPostType.impossibleChallenge => 'DESAFIO IMPOSSÍVEL',
              FeedPostType.punishment => 'PUNIÇÃO LEVE',
              _ => 'AVISO',
            },
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: cor, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
