import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/feed_post.dart';
import '../services/feed_service.dart';
import '../state/session_controller.dart';

/// Bottom sheet para lançar uma Carta de Desafio Impossível ou de Punição Leve.
///
/// Quem bate a meta do dia primeiro ganha o direito de lançar o desafio;
/// a punição leve é a prenda de domingo de quem fez menos pontos na semana.
class PublishCardSheet extends StatefulWidget {
  const PublishCardSheet({super.key, required this.type});

  final FeedPostType type;

  static Future<bool?> show(BuildContext context, FeedPostType type) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PublishCardSheet(type: type),
    );
  }

  @override
  State<PublishCardSheet> createState() => _PublishCardSheetState();
}

class _PublishCardSheetState extends State<PublishCardSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  /// Sugestões prontas — tirar o atrito de ter que inventar na hora.
  static const Map<FeedPostType, List<String>> _suggestions = {
    FeedPostType.impossibleChallenge: [
      'Quem fizer 10 polichinelos em vídeo agora ganha +50 pontos 🔥',
      'Foto da garrafa de água vazia até as 18h vale ponto extra 💧',
      '5 minutos de alongamento AGORA, quem não fizer paga mico domingo 🧘',
    ],
    FeedPostType.punishment: [
      'Quem fizer menos pontos lava a louça do almoço de domingo 🍽️',
      'Último colocado prepara o café da tarde de domingo ☕',
      'Quem ficar em último dança a música escolhida pelos outros 💃',
    ],
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChallenge = widget.type == FeedPostType.impossibleChallenge;
    final accent = isChallenge ? AppColors.danger : AppColors.warning;
    final suggestions = _suggestions[widget.type] ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E0EE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(widget.type.emoji,
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isChallenge
                          ? 'Desafio Impossível'
                          : 'Punição Leve (Pagando Mico)',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isChallenge
                      ? 'Qual é o desafio relâmpago?'
                      : 'Qual é a prenda de domingo?',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sugestões:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...suggestions.map(
                (text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _controller.text = text),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 13.5, height: 1.3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text('Publicar no mural ${widget.type.emoji}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva a carta antes de publicar.')),
      );
      return;
    }

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await context.read<FeedService>().publishCard(
            author: user,
            type: widget.type,
            message: message,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível publicar. Tente de novo.')),
      );
    }
  }
}
