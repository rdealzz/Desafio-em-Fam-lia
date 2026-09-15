import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../models/feed_post.dart';
import '../services/feed_service.dart';
import '../state/session_controller.dart';
import 'ui/pressable.dart';
import 'ui/primitives.dart';

/// Lançar uma Carta de Desafio Impossível ou de Punição Leve.
class PublishCardSheet extends StatefulWidget {
  const PublishCardSheet({super.key, required this.type});

  final FeedPostType type;

  static Future<bool?> show(BuildContext context, FeedPostType type) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PublishCardSheet(type: type),
    );
  }

  @override
  State<PublishCardSheet> createState() => _PublishCardSheetState();
}

class _PublishCardSheetState extends State<PublishCardSheet> {
  final TextEditingController _c = TextEditingController();
  bool _salvando = false;

  static const Map<FeedPostType, List<String>> _sugestoes = {
    FeedPostType.impossibleChallenge: [
      'Quem fizer 10 polichinelos em vídeo agora ganha +50 pontos',
      'Foto da garrafa de água vazia até as 18h vale ponto extra',
      '5 minutos de alongamento agora, quem não fizer paga mico domingo',
    ],
    FeedPostType.punishment: [
      'Quem fizer menos pontos lava a louça do almoço de domingo',
      'Último colocado prepara o café da tarde de domingo',
      'Quem ficar em último dança a música escolhida pelos outros',
    ],
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final desafio = widget.type == FeedPostType.impossibleChallenge;
    final sugestoes = _sugestoes[widget.type] ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionLabel(
                desafio ? 'Desafio impossível' : 'Punição leve',
              ),
              Text(
                desafio
                    ? 'Quem bate a meta primeiro lança o desafio do dia.'
                    : 'A prenda de domingo de quem fez menos pontos.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: Space.lg),
              TextField(
                controller: _c,
                maxLines: 3,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: desafio ? 'Qual é o desafio?' : 'Qual é a prenda?',
                  counterText: '',
                ),
              ),
              const SizedBox(height: Space.lg),
              const SectionLabel('Sugestões'),
              for (final texto in sugestoes)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: PressableCard(
                    onTap: () => setState(() => _c.text = texto),
                    padding: const EdgeInsets.all(Space.md),
                    child: Text(texto, style: t.bodyMedium),
                  ),
                ),
              const SizedBox(height: Space.lg),
              Pressable(
                onPressed: _salvando ? null : _enviar,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _salvando
                    ? SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: p.onAccent,
                        ),
                      )
                    : const Text(
                        'Publicar no mural',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final texto = _c.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva a carta antes de publicar.')),
      );
      return;
    }
    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _salvando = true);
    try {
      await context
          .read<FeedService>()
          .publishCard(author: user, type: widget.type, message: texto);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível publicar.')),
      );
    }
  }
}
