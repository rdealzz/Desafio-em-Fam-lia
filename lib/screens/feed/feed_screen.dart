import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/feed_post.dart';
import '../../services/feed_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/feed_post_card.dart';
import '../../widgets/publish_card_sheet.dart';

/// TELA 3 — Mural do Deboche & Apoio.
///
/// Feed fechado dos 4 integrantes: fotos das atividades, pontos ganhos,
/// reações rápidas e as cartas de brincadeira publicadas.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final feedService = context.read<FeedService>();
    final user = session.user;
    final family = session.family;

    if (user == null || family == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mural do Deboche',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${family.name} • só entre vocês 4',
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Lançar carta',
                    icon: const Icon(Icons.style_outlined),
                    onPressed: () => _openCardMenu(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<FeedPost>>(
                stream: feedService.watchFeed(family.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _FeedMessage(
                      emoji: '⚠️',
                      title: 'Não consegui carregar o mural',
                      subtitle: 'Verifique a conexão e tente de novo.',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!;
                  if (posts.isEmpty) {
                    return const _FeedMessage(
                      emoji: '📭',
                      title: 'O mural está vazio',
                      subtitle:
                          'Registre a primeira atividade e comece a zoeira.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return FeedPostCard(
                        post: post,
                        currentUserId: user.id,
                        onReaction: (key) => feedService.toggleReaction(
                          postId: post.id,
                          reactionKey: key,
                          userId: user.id,
                          isActive: post.hasReacted(key, user.id),
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

  void _openCardMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Cartas de brincadeira',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Text('🔥', style: TextStyle(fontSize: 26)),
              title: const Text('Desafio Impossível'),
              subtitle: const Text('Mini-desafio relâmpago para o grupo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                PublishCardSheet.show(
                  context,
                  FeedPostType.impossibleChallenge,
                );
              },
            ),
            ListTile(
              leading: const Text('🦸', style: TextStyle(fontSize: 26)),
              title: const Text('Salva-Mãe / Salva-Pai'),
              subtitle: const Text('Doe pontos em dobro e salve a sequência'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                DonatePointsSheet.show(context);
              },
            ),
            ListTile(
              leading: const Text('🤡', style: TextStyle(fontSize: 26)),
              title: const Text('Punição Leve'),
              subtitle: const Text('A prenda de domingo de quem fez menos'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                PublishCardSheet.show(context, FeedPostType.punishment);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 46)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
