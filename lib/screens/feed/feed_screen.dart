import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/firestore_erros.dart';
import '../../core/utils/formatters.dart';
import '../../models/feed_post.dart';
import '../../services/feed_grouping.dart';
import '../../services/feed_service.dart';
import '../../services/photo_cleanup_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/donate_points_sheet.dart';
import '../../widgets/feed_post_card.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/ui/entrada.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/segmentado.dart';
import '../../widgets/ui/primitives.dart';

/// TELA 3 — Mural.
///
/// Organizado por dia ("Hoje", "Ontem"...), com um resumo do que a família
/// já fez hoje no topo e um filtro para ver só os treinos ou só as cartas.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  /// Guardado no estado: criar o stream dentro do build reabriria a consulta
  /// no Firestore a cada reconstrução (cada reação, cada troca de filtro).
  Stream<List<FeedPost>>? _stream;
  String? _familiaDoStream;

  Stream<List<FeedPost>> _feed(FeedService service, String familyId) {
    if (_stream == null || _familiaDoStream != familyId) {
      _familiaDoStream = familyId;
      _stream = service.watchFeed(familyId);
    }
    return _stream!;
  }

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
                stream: _feed(feedService, family.id),
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
                    // O guarda importa: sair do mural no quadro em que o
                    // snapshot chega deixaria este context desativado, e a
                    // busca pelo provider lançaria.
                    if (!context.mounted) return;
                    context.read<PhotoCleanupService>().limpar(posts: posts);
                  });
                  if (posts.isEmpty) {
                    return const _Vazio(
                      icon: Icons.inbox_outlined,
                      titulo: 'Mural vazio',
                      texto: 'Registre a primeira atividade e comece a zoeira.',
                    );
                  }
                  return MuralLista(
                    posts: posts,
                    userId: user.id,
                    onReaction: (post, k) => feedService.toggleReaction(
                      postId: post.id,
                      reactionKey: k,
                      userId: user.id,
                      isActive: post.hasReacted(k, user.id),
                    ),
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

/// A lista do mural depois que os posts chegaram: resumo do dia, filtro e
/// as publicações agrupadas por dia. Separada da tela para dar para montar
/// com dados de mentira em teste.
class MuralLista extends StatefulWidget {
  const MuralLista({
    super.key,
    required this.posts,
    required this.userId,
    required this.onReaction,
  });

  final List<FeedPost> posts;
  final String userId;
  final void Function(FeedPost post, String reacao) onReaction;

  @override
  State<MuralLista> createState() => _MuralListaState();
}

class _MuralListaState extends State<MuralLista> {
  FiltroMural _filtro = FiltroMural.todos;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final posts = widget.posts;
    final agora = DateTime.now();
    final dias = FeedGrouping.porDia(
      posts.where(_filtro.aceita).toList(),
      agora,
    );
    final resumo = FeedGrouping.resumoDeHoje(posts, agora);

    // Lista plana de itens (cabeçalho de dia ou post) para o
    // ListView continuar preguiçoso: só constrói o que aparece.
    final itens = <Object>[
      for (final dia in dias) ...[dia.rotulo, ...dia.posts],
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.huge,
      ),
      itemCount: itens.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Entrada(child: _ResumoDeHoje(resumo: resumo)),
                const SizedBox(height: Space.lg),
                Entrada(
                  ordem: 1,
                  child: Segmentado<FiltroMural>(
                    opcoes: {for (final f in FiltroMural.values) f: f.rotulo},
                    atual: _filtro,
                    onMudar: (f) {
                      HapticFeedback.selectionClick();
                      setState(() => _filtro = f);
                    },
                  ),
                ),
                if (itens.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.huge),
                    child: Center(
                      child: Text(
                        _filtro == FiltroMural.cartas
                            ? 'Nenhuma carta lançada ainda.'
                            : 'Nenhum treino no mural ainda.',
                        style: t.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        final item = itens[i - 1];
        // Só os primeiros entram em cascata; o resto chega
        // rolando e não precisa de efeito.
        final ordem = i < 8 ? i + 1 : 0;
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xs,
              Space.lg,
              Space.xs,
              Space.md,
            ),
            child: Text(
              item.toUpperCase(),
              style: t.labelMedium,
            ),
          );
        }
        final post = item as FeedPost;
        final card = FeedPostCard(
          key: ValueKey(post.id),
          post: post,
          currentUserId: widget.userId,
          onReaction: (k) => widget.onReaction(post, k),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: ordem > 0 ? Entrada(ordem: ordem, child: card) : card,
        );
      },
    );
  }
}

/// O que a família já fez hoje, num cartão só.
class _ResumoDeHoje extends StatelessWidget {
  const _ResumoDeHoje({required this.resumo});

  final ResumoDoDia resumo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (resumo.treinos == 0) {
      return Surface(
        child: Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 20, color: p.textMuted),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                'Ninguém treinou hoje ainda. Quem abre o placar do dia?',
                style: t.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Surface(
      padding: const EdgeInsets.all(Space.lg),
      radius: Radii.xl,
      child: Row(
        children: [
          Expanded(
            child: _NumeroDoDia(
              valor: '${resumo.treinos}',
              rotulo: resumo.treinos == 1 ? 'treino hoje' : 'treinos hoje',
              cor: p.textPrimary,
            ),
          ),
          Expanded(
            child: _NumeroDoDia(
              valor: Formatters.duration(resumo.minutos),
              rotulo: 'de exercício',
              cor: p.textPrimary,
            ),
          ),
          Expanded(
            child: _NumeroDoDia(
              valor: '+${Formatters.points(resumo.pontos)}',
              rotulo: 'no cofre',
              cor: p.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumeroDoDia extends StatelessWidget {
  const _NumeroDoDia({
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          maxLines: 1,
          style: t.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall,
        ),
      ],
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
