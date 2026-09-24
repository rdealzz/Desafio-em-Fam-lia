import 'package:flutter/material.dart';

import '../core/theme/palette.dart';
import '../core/theme/tokens.dart';
import '../core/utils/formatters.dart';
import '../models/family.dart';
import '../services/weekly_pace.dart';
import 'ui/barra_marcos.dart';
import 'ui/entrada.dart';

/// O Cofre da Semana — bloco principal da Tela 1.
///
/// O número continua sendo o herói; o que mudou é o entorno. Um brilho do
/// azul atrás do total dá profundidade sem virar o cartão roxo chapado de
/// antes, a barra mostra os prêmios como marcos no caminho, e o rodapé troca
/// o "faltam X pts" solto por um ritmo: quantos pontos por dia, e quanto é
/// isso para cada um.
class VaultProgressCard extends StatelessWidget {
  const VaultProgressCard({super.key, required this.family});

  final Family family;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final bateu = family.goalReached;
    final pace = WeeklyPace.of(family, DateTime.now());
    final meta = family.weeklyGoal;
    final brilho = bateu ? p.gold : p.accentAlt;

    final marcos = [
      for (final r in family.rewardsThisWeek)
        if (meta > 0 && r.requiredPoints < meta) r.requiredPoints / meta,
    ];

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.xl),
        child: Stack(
          children: [
            // Brilho difuso no canto: é luz, não pintura. Some no escuro o
            // bastante para não virar mancha.
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        brilho.withValues(alpha: p.isDark ? 0.22 : 0.16),
                        brilho.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'COFRE DA SEMANA',
                          style: t.labelMedium,
                        ),
                      ),
                      _Selo(pace: pace, bateu: bateu),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      NumeroAnimado(
                        valor: family.vaultThisWeek,
                        formatar: Formatters.points,
                        style: t.displayLarge,
                      ),
                      const SizedBox(width: Space.sm),
                      Text(
                        '/ ${Formatters.points(meta)}',
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(family.progress * 100).round()}%',
                        style: t.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: bateu ? p.gold : p.accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  BarraMarcos(valor: family.progress, marcos: marcos),
                  const SizedBox(height: Space.lg),
                  _Ritmo(family: family, pace: pace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantos dias restam, no canto do cartão.
class _Selo extends StatelessWidget {
  const _Selo({required this.pace, required this.bateu});

  final WeeklyPace pace;
  final bool bateu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    final (texto, cor, fundo) = bateu
        ? ('meta batida', p.gold, p.gold.withValues(alpha: 0.14))
        : pace.lastDay
            ? ('último dia', p.energy, p.energySoft)
            : (
                'faltam ${pace.daysLeft} dias',
                p.textSecondary,
                p.surfaceSunken
              );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        texto,
        style: t.labelSmall?.copyWith(color: cor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// O rodapé do cofre: o próximo prêmio e o ritmo para chegar na meta.
class _Ritmo extends StatelessWidget {
  const _Ritmo({required this.family, required this.pace});

  final Family family;
  final WeeklyPace pace;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (family.goalReached) {
      return Row(
        children: [
          Icon(Icons.workspace_premium_rounded, size: 18, color: p.gold),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'Meta batida. Prêmios do fim de semana liberados.',
              style: t.bodySmall?.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final proximo = family.nextReward;
    final faltaProximo = proximo == null
        ? family.pointsRemaining
        : proximo.requiredPoints - family.vaultThisWeek;

    return Row(
      children: [
        Expanded(
          child: _Dado(
            valor: Formatters.points(pace.perDay),
            rotulo: pace.lastDay ? 'hoje' : 'por dia',
          ),
        ),
        _Separador(cor: p.border),
        Expanded(
          child: _Dado(
            valor: Formatters.points(pace.perPersonPerDay),
            rotulo: 'cada um',
          ),
        ),
        _Separador(cor: p.border),
        Expanded(
          flex: 2,
          child: _Dado(
            valor: Formatters.points(faltaProximo),
            rotulo: proximo == null ? 'para a meta' : 'para ${proximo.title}',
          ),
        ),
      ],
    );
  }
}

class _Dado extends StatelessWidget {
  const _Dado({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          rotulo,
          style: t.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador({required this.cor});

  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: Space.md),
      color: cor,
    );
  }
}
