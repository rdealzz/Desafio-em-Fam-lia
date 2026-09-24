import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/week_utils.dart';
import '../../models/app_user.dart';
import '../../models/family.dart';
import '../../models/feed_post.dart';
import '../../services/weekly_standings.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/publish_card_sheet.dart';
import '../../widgets/ui/entrada.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/primitives.dart';
import '../profile/member_profile_screen.dart';

/// Placar da semana — e, no domingo, o fechamento.
///
/// O cofre é de todos, então o placar não é para humilhar ninguém: mostra
/// quem puxou a semana e quem fica com a Punição Leve. No domingo o título
/// vira "Fechamento" e o botão de lançar a prenda ganha destaque.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScoreboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return ScoreboardView(
      members: session.members,
      family: session.family,
      meuId: session.user?.id,
      hoje: DateTime.now(),
    );
  }
}

/// O conteúdo do placar, separado da sessão para dar para testar e montar
/// com dados de mentira.
class ScoreboardView extends StatelessWidget {
  const ScoreboardView({
    super.key,
    required this.members,
    required this.family,
    required this.meuId,
    required this.hoje,
  });

  final List<AppUser> members;
  final Family? family;
  final String? meuId;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final family = this.family;
    final placar = WeeklyStandings.from(members);
    final t = Theme.of(context).textTheme;
    final p = context.palette;
    final domingo = hoje.weekday == DateTime.sunday;

    return Scaffold(
      appBar: AppBar(
        title: Text(domingo ? 'Fechamento da semana' : 'Placar da semana'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.huge,
        ),
        children: [
          Entrada(
            child: Text(
              _periodo(hoje),
              style: t.labelMedium,
            ),
          ),
          const SizedBox(height: Space.md),
          if (placar.podium.isEmpty)
            Entrada(
              ordem: 1,
              child: Surface(
                padding: const EdgeInsets.symmetric(
                  vertical: Space.xxl,
                  horizontal: Space.xl,
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 36, color: p.textMuted),
                    const SizedBox(height: Space.md),
                    Text('Ninguém pontuou ainda', style: t.titleMedium),
                    const SizedBox(height: Space.xs),
                    Text(
                      'O primeiro registro da semana abre o pódio.',
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Entrada(ordem: 1, child: _Podio(podio: placar.podium)),
          const SizedBox(height: Space.xl),
          if (family != null)
            Entrada(
              ordem: 2,
              child: Surface(
                child: Row(
                  children: [
                    Expanded(
                      child: StatBlock(
                        value: Formatters.points(placar.totalPoints),
                        label: 'pontos',
                        accent: true,
                      ),
                    ),
                    Expanded(
                      child: StatBlock(
                        value: '${(family.progress * 100).round()}%',
                        label: 'da meta',
                      ),
                    ),
                    Expanded(
                      child: StatBlock(
                        value: '${WeekUtils.daysLeftInWeek(hoje)}',
                        label: WeekUtils.daysLeftInWeek(hoje) == 1
                            ? 'dia restante'
                            : 'dias restantes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.xxl),
          if (!placar.isEmpty) ...[
            const SectionLabel('Classificação'),
            Entrada(
              ordem: 3,
              child: Surface(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Column(
                  children: [
                    for (var i = 0; i < placar.rows.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: Space.lg,
                          endIndent: Space.lg,
                        ),
                      _Linha(
                        linha: placar.rows[i],
                        souEu: placar.rows[i].member.id == meuId,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
          ],
          if (placar.lantern.isNotEmpty)
            Entrada(
              ordem: 4,
              child: _Lanterna(placar: placar, destaque: domingo),
            ),
        ],
      ),
    );
  }

  /// "14 A 20 DE SETEMBRO"
  static String _periodo(DateTime hoje) {
    final ini = WeekUtils.startOfWeek(hoje);
    final fim = ini.add(const Duration(days: 6));
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    final texto = ini.month == fim.month
        ? '${ini.day} a ${fim.day} de ${meses[fim.month - 1]}'
        : '${ini.day} de ${meses[ini.month - 1]} a '
            '${fim.day} de ${meses[fim.month - 1]}';
    return texto.toUpperCase();
  }
}

/// Três degraus, o primeiro no meio e mais alto — a forma que qualquer um
/// reconhece sem legenda.
class _Podio extends StatelessWidget {
  const _Podio({required this.podio});

  final List<Standing> podio;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Ordem visual: 2º, 1º, 3º.
    final visual = <(Standing, double, Color)>[
      if (podio.length > 1) (podio[1], 92, p.accent),
      (podio[0], 128, p.gold),
      if (podio.length > 2) (podio[2], 68, p.accentAlt),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, 0),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (linha, altura, cor) in visual)
            Expanded(
              child: _Degrau(linha: linha, altura: altura, cor: cor),
            ),
        ],
      ),
    );
  }
}

class _Degrau extends StatelessWidget {
  const _Degrau({
    required this.linha,
    required this.altura,
    required this.cor,
  });

  final Standing linha;
  final double altura;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final primeiro = linha.position == 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => MemberProfileScreen.open(context, linha.member.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (primeiro)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Icon(Icons.emoji_events_rounded, size: 22, color: p.gold),
            ),
          AvatarBubble(user: linha.member, size: primeiro ? 64 : 52),
          const SizedBox(height: Space.sm),
          Text(
            linha.member.firstName,
            style: t.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${Formatters.points(linha.points)} pts',
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: Space.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: altura),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, h, _) => Container(
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: Space.xs),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: Space.sm),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(Radii.md)),
                // Degrau chapado, na cor do lugar em tom suave.
                color: cor.withValues(alpha: p.isDark ? 0.28 : 0.16),
              ),
              child: h < 30
                  ? null
                  : Text(
                      '${linha.position}º',
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.linha, required this.souEu});

  final Standing linha;
  final bool souEu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final m = linha.member;

    return InkWell(
      onTap: () => MemberProfileScreen.open(context, m.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${linha.position}º',
                style: t.labelLarge?.copyWith(
                  color: linha.position == 1 ? p.gold : p.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AvatarBubble(user: m, size: 36),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          souEu ? '${m.firstName} (você)' : m.firstName,
                          style: t.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.currentStreak > 1) ...[
                        const SizedBox(width: Space.sm),
                        Icon(Icons.local_fire_department_rounded,
                            size: 14, color: p.energy),
                        Text(
                          '${m.currentStreak}',
                          style: t.labelSmall?.copyWith(color: p.energy),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressBarThin(
                    value: linha.share,
                    height: 5,
                    color: linha.lantern ? p.energy : p.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.points(linha.points),
                  style: t.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text('${(linha.share * 100).round()}%', style: t.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quem está na lanterna e o atalho para lançar a Punição Leve.
class _Lanterna extends StatelessWidget {
  const _Lanterna({required this.placar, required this.destaque});

  final WeeklyStandings placar;

  /// Domingo: é hora de cobrar, o botão vira o principal.
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final nomes = placar.lantern.map((r) => r.member.firstName).toList();
    final quem = nomes.length == 1
        ? nomes.first
        : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    final plural = nomes.length > 1;

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.energySoft,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.theater_comedy_outlined, size: 20, color: p.energy),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  plural ? 'Na lanterna: $quem' : '$quem está na lanterna',
                  style: t.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            destaque
                ? 'Semana fechando. Hora de escolher a prenda de domingo.'
                : 'Ainda dá tempo de sair daí até domingo.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.md),
          Pressable(
            tone: destaque ? PressableTone.danger : PressableTone.neutral,
            padding: const EdgeInsets.symmetric(vertical: 13),
            onPressed: () =>
                PublishCardSheet.show(context, FeedPostType.punishment),
            child: const Text(
              'Lançar Punição Leve',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
