import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/firestore_erros.dart';
import '../../models/feed_post.dart';
import '../../services/feed_service.dart';
import '../../services/photo_cleanup_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/feed_post_card.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/primitives.dart';

/// TELA 3 — Mural.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final feedService = context.read<FeedService>();
    final user = session.user;
    final family = session.family;
    final t = Theme.of(context).textTheme;

    if (user == null || family == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.lg,
                Space.gutter,
                Space.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MURAL', style: t.labelMedium),
                        const SizedBox(height: 2),
                        Text('Deboche & Apoio', style: t.headlineMedium),
                      ],
                    ),
                  ),
                  Pressable(
                    tone: PressableTone.neutral,
                    expand: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.md,
                    ),
                    onPressed: () => _cartas(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style_outlined, size: 16),
                        SizedBox(width: Space.sm),
                        Text(
                          'Carta',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<FeedPost>>(
                stream: feedService.watchFeed(family.id),
                builder: (context, snap) {
                  if (snap.hasError) {
                    final erro = FirestoreErros.traduzir(snap.error);
                    return _Vazio(
                      icon: erro.link == null
                          ? Icons.wifi_off_rounded
                          : Icons.build_outlined,
                      titulo: erro.titulo,
                      texto: erro.texto,
                      link: erro.link,
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snap.data!;
                  // Aproveita que a lista já chegou: as fotos vencidas que
                  // estão nela somem do servidor agora. Fora do build para não
                  // escrever no meio da construção do quadro.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<PhotoCleanupService>().limpar(posts: posts);
                  });
                  if (posts.isEmpty) {
                    return const _Vazio(
                      icon: Icons.inbox_outlined,
                      titulo: 'Mural vazio',
                      texto: 'Registre a primeira atividade e comece a zoeira.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      0,
                      Space.gutter,
                      Space.huge,
                    ),
                    // Sem ajuste manual de cache: o padrão do ListView já
                    // serve, e cada item entra com RepaintBoundary próprio —
                    // é daí que vem o ganho na rolagem, não do cache extra.
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Space.md),
                    itemBuilder: (context, i) {
                      final post = posts[i];
                      return FeedPostCard(
                        post: post,
                        currentUserId: user.id,
                        onReaction: (k) => feedService.toggleReaction(
                          postId: post.id,
                          reactionKey: k,
                          userId: user.id,
                          isActive: post.hasReacted(k, user.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cartas(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(Space.gutter, Space.sm, 0, 0),
              child: SectionLabel('Cartas de brincadeira'),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Desafio Impossível'),
              subtitle: const Text('mini-desafio relâmpago para o grupo'),
              onTap: () {
                Navigator.of(sheet).pop();
                PublishCardSheet.show(
                    context, FeedPostType.impossibleChallenge);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Salva-Mãe / Salva-Pai'),
              subtitle: const Text('doe pontos em dobro e salve a sequência'),
              onTap: () {
                Navigator.of(sheet).pop();
                DonatePointsSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.theater_comedy_outlined),
              title: const Text('Punição Leve'),
              subtitle: const Text('a prenda de domingo de quem fez menos'),
              onTap: () {
                Navigator.of(sheet).pop();
                PublishCardSheet.show(context, FeedPostType.punishment);
              },
            ),
            const SizedBox(height: Space.md),
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({
    required this.icon,
    required this.titulo,
    required this.texto,
    this.link,
  });

  final IconData icon;
  final String titulo;
  final String texto;

  /// Endereço que resolve o problema, quando existe. Fica copiável em vez de
  /// abrir sozinho: quem precisa dele está configurando o projeto, e vai colar
  /// no navegador onde já está logado no console.
  final String? link;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: p.textMuted),
            const SizedBox(height: Space.lg),
            Text(titulo, style: t.titleMedium),
            const SizedBox(height: Space.xs),
            Text(texto, textAlign: TextAlign.center, style: t.bodyMedium),
            if (link != null) ...[
              const SizedBox(height: Space.lg),
              Pressable(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link!));
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copiado — cole no navegador'),
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.lg,
                  vertical: Space.md,
                ),
                child: const Text('Copiar o link da correção'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
