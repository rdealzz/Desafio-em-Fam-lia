import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import '../services/activity_service.dart';
import '../services/app_exception.dart';
import '../services/points_calculator.dart';
import '../state/session_controller.dart';
import 'avatar_bubble.dart';
import 'ui/pressable.dart';
import 'ui/primitives.dart';

/// Carta "Salva-Mãe / Salva-Pai": doar pontos, quem recebe leva o dobro.
class DonatePointsSheet extends StatefulWidget {
  const DonatePointsSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DonatePointsSheet(),
    );
  }

  @override
  State<DonatePointsSheet> createState() => _DonatePointsSheetState();
}

class _DonatePointsSheetState extends State<DonatePointsSheet> {
  AppUser? _destino;
  int _valor = 50;
  bool _salvando = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final session = context.watch<SessionController>();
    final eu = session.user;
    final outros = session.otherMembers;
    if (eu == null) return const SizedBox.shrink();

    final disponivel = eu.pointsThisWeek;
    final valor = _valor > disponivel ? disponivel : _valor;

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
              const SectionLabel('Carta Salva-Mãe / Salva-Pai'),
              Text(
                'Treinou em dobro? Doe pontos para salvar a sequência de '
                'alguém. Quem recebe leva o dobro do que você doar.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: Space.lg),
              Surface(
                color: p.surfaceRaised,
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    Expanded(
                      child: StatBlock(
                        value: '${eu.cartasDisponiveis}',
                        label: 'cartas',
                      ),
                    ),
                    Expanded(
                      child: StatBlock(
                        value: Formatters.points(disponivel),
                        label: 'pontos na semana',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.xl),
              const SectionLabel('Para quem'),
              if (outros.isEmpty)
                Text('Ninguém mais entrou na família ainda.', style: t.bodyMedium)
              else
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final m in outros)
                      SizedBox(
                        width: 150,
                        child: PressableCard(
                          selected: _destino?.id == m.id,
                          onTap: () => setState(() => _destino = m),
                          padding: const EdgeInsets.all(Space.md),
                          child: Row(
                            children: [
                              AvatarBubble(user: m, size: 30, showRing: false),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  m.firstName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: Space.xl),
              SectionLabel(
                'Quanto doar',
                trailing: Text(
                  '${Formatters.points(valor)} pts',
                  style: t.labelLarge?.copyWith(color: p.accent),
                ),
              ),
              Slider(
                value: valor.toDouble(),
                min: 0,
                max: disponivel <= 0 ? 1 : disponivel.toDouble(),
                divisions: disponivel >= 10 ? (disponivel ~/ 10) : null,
                onChanged: disponivel <= 0
                    ? null
                    : (v) => setState(() => _valor = v.round()),
              ),
              const SizedBox(height: Space.sm),
              Surface(
                color: p.accentSoft,
                border: false,
                child: Text(
                  '${_destino?.firstName ?? 'Quem receber'} ganha '
                  '${Formatters.points(PointsCalculator.donationValue(valor))} pts '
                  'e mantém a sequência do dia.',
                  style: t.bodyMedium?.copyWith(color: p.textPrimary),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: Space.md),
                Text(
                  _erro!,
                  style: t.bodySmall?.copyWith(color: p.danger),
                ),
              ],
              const SizedBox(height: Space.lg),
              Pressable(
                onPressed: _salvando || _destino == null || valor <= 0
                    ? null
                    : () => _enviar(valor),
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
                        'Usar a carta',
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

  Future<void> _enviar(int valor) async {
    final session = context.read<SessionController>();
    final servico = context.read<ActivityService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final eu = session.user;
    final destino = _destino;
    if (eu == null || destino == null) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final recebido = await servico.donatePoints(
        donor: eu,
        recipientId: destino.id,
        amount: valor,
      );
      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${destino.firstName} recebeu ${Formatters.points(recebido)} pts',
          ),
        ),
      );
    } on AppException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Não foi possível doar agora.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
