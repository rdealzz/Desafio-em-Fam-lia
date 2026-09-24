import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/firestore_erros.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_log.dart';
import '../../models/activity_type.dart';
import '../../models/app_user.dart';
import '../../services/activity_service.dart';
import '../../services/feed_grouping.dart';
import '../../services/photo_cleanup_service.dart';
import '../../services/photo_proof.dart';
import '../../services/profile_stats.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/ui/activity_icons.dart';
import '../../widgets/ui/entrada.dart';
import '../../widgets/ui/inset_group.dart';
import '../../widgets/ui/primitives.dart';
import '../../widgets/weekly_activity_strip.dart';
import 'profile_edit_screen.dart';

/// Perfil de um integrante: quem é, quanto fez, do que mais gosta e o
/// histórico dia a dia.
///
/// No formato do app Fitness do iPhone: cabeçalho com a foto e o nome, os
/// números em blocos, o gráfico da semana, e as listas em grupos.
class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  static Future<void> open(BuildContext context, String memberId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberProfileScreen(memberId: memberId),
      ),
    );
  }

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  /// Guardado no estado: criado dentro do build, a consulta ao Firestore era
  /// reaberta a cada atualização da sessão (qualquer ponto de qualquer um).
  Stream<List<ActivityLog>>? _logs;

  /// Busca explícita em vez de `firstOrNull`: essa extensão vem de
  /// `package:collection`, que o projeto não declara como dependência.
  AppUser? _achar(SessionController session) {
    for (final m in session.members) {
      if (m.id == widget.memberId) return m;
    }
    final atual = session.user;
    return atual != null && atual.id == widget.memberId ? atual : null;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final member = _achar(session);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Integrante não encontrado.')),
      );
    }

    _logs ??= context.read<ActivityService>().watchUserLogs(member.id);

    return StreamBuilder<List<ActivityLog>>(
      stream: _logs,
      builder: (context, snap) {
        final logs = snap.data ?? const <ActivityLog>[];

        // Mesma limpeza do mural, por outro caminho: alcança o registro cujo
        // post já saiu da primeira página do feed.
        if (logs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<PhotoCleanupService>().limpar(logs: logs);
          });
        }

        return PerfilView(
          member: member,
          souEu: session.user?.id == member.id,
          cofre: session.family?.vaultThisWeek ?? 0,
          logs: logs,
          carregando: !snap.hasData && !snap.hasError,
          erro: snap.error,
        );
      },
    );
  }
}

/// O conteúdo do perfil, separado da sessão e do Firestore para dar para
/// montar com dados de mentira em teste.
class PerfilView extends StatelessWidget {
  const PerfilView({
    super.key,
    required this.member,
    required this.souEu,
    required this.cofre,
    required this.logs,
    this.carregando = false,
    this.erro,
  });

  final AppUser member;
  final bool souEu;

  /// Pontos do cofre da família nesta semana, para a fatia da pessoa.
  final int cofre;
  final List<ActivityLog> logs;
  final bool carregando;
  final Object? erro;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final modalidades = ProfileStats.porModalidade(logs);
    final dias = ProfileStats.porDia(logs);

    return Scaffold(
      appBar: AppBar(
        title: Text(souEu ? 'Meu perfil' : member.firstName),
        actions: [
          if (souEu)
            TextButton(
              onPressed: () => ProfileEditScreen.open(context),
              child: const Text('Editar'),
            ),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.huge,
        ),
        children: [
          // Sem isto, falha de consulta virava lista vazia — a tela dizia
          // "nenhum registro" quando o problema era outro.
          if (erro != null) _AvisoErro(erro: erro),

          Entrada(child: _Cabecalho(member: member, souEu: souEu)),
          const SizedBox(height: Space.xl),

          Entrada(
            ordem: 1,
            child: _Numeros(
              member: member,
              cofre: cofre,
              minutosSemana: ProfileStats.minutosDaSemana(logs, DateTime.now()),
            ),
          ),
          const SizedBox(height: Space.lg),

          Entrada(ordem: 2, child: WeeklyActivityStrip(logs: logs)),

          if (modalidades.isNotEmpty) ...[
            const SizedBox(height: Space.xxl),
            Entrada(
              ordem: 3,
              child: InsetGroup(
                header: souEu ? 'Seus treinos' : 'Treinos',
                footer: 'Nos últimos ${logs.length} registros.',
                children: [
                  for (final m in modalidades)
                    InsetRow(
                      icon: iconForActivity(m.tipo),
                      tint: _corDoGrupo(context.palette, m.tipo.group),
                      title: m.tipo.label,
                      subtitle: '${m.vezes} ${m.vezes == 1 ? 'vez' : 'vezes'}'
                          ' · ${Formatters.duration(m.minutos)}',
                      value: '+${Formatters.points(m.pontos)}',
                      showChevron: false,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: Space.xxl),
          if (carregando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Space.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dias.isEmpty)
            _Vazio(souEu: souEu, nome: member.firstName)
          else
            for (final dia in dias) ...[
              InsetGroup(
                header: FeedGrouping.rotuloDoDia(dia.dia, DateTime.now()),
                trailing: Text(
                  '+${Formatters.points(dia.pontos)} pts',
                  style: t.labelMedium,
                ),
                children: [for (final l in dia.logs) _Registro(log: l)],
              ),
              const SizedBox(height: Space.xl),
            ],
        ],
      ),
    );
  }
}

/// A cor do quadradinho de cada modalidade vem do grupo: três cores, não
/// sete — sete não se distinguem para quem é daltônico.
Color _corDoGrupo(Palette p, ActivityGroup g) => switch (g) {
      ActivityGroup.outdoor => p.success,
      ActivityGroup.training => p.accent,
      ActivityGroup.home => p.accentAlt,
    };

/// Foto grande, nome, papel e se já treinou hoje.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.member, required this.souEu});

  final AppUser member;
  final bool souEu;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final ativo = member.isActiveToday;
    final papel = member.papelLabel;

    return Column(
      children: [
        GestureDetector(
          onTap: souEu ? () => ProfileEditScreen.open(context) : null,
          child: AvatarBubble(user: member, size: 96),
        ),
        const SizedBox(height: Space.md),
        Text(
          member.displayName,
          textAlign: TextAlign.center,
          style: t.headlineMedium,
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            if (papel.isNotEmpty) _Etiqueta(texto: papel, cor: p.textSecondary),
            _Etiqueta(
              texto: ativo ? 'treinou hoje' : 'ainda não treinou hoje',
              cor: ativo ? p.success : p.textMuted,
              ponto: true,
            ),
          ],
        ),
        if (member.statusMessage.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text(
            '"${member.statusMessage}"',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

/// Etiqueta cinza com bolinha opcional na cor do estado.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor, this.ponto = false});

  final String texto;
  final Color cor;
  final bool ponto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ponto) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ponto ? p.textSecondary : cor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Os quatro números, em blocos 2 × 2 como os resumos do app Fitness.
class _Numeros extends StatelessWidget {
  const _Numeros({
    required this.member,
    required this.cofre,
    required this.minutosSemana,
  });

  final AppUser member;
  final int cofre;
  final int minutosSemana;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final semana = member.pointsThisWeek;
    final fatia = cofre == 0 ? 0 : ((semana / cofre) * 100).round();
    final seq = member.currentStreak;
    final recorde = member.longestStreak;

    final blocos = [
      _Bloco(
        icone: Icons.bolt_rounded,
        cor: p.accent,
        rotulo: 'Nesta semana',
        valor: Formatters.points(semana),
        unidade: 'pts',
        detalhe: minutosSemana > 0
            ? '${Formatters.duration(minutosSemana)} de treino'
            : 'nenhum treino ainda',
      ),
      _Bloco(
        icone: Icons.local_fire_department_rounded,
        cor: p.energy,
        rotulo: 'Sequência',
        valor: '$seq',
        unidade: seq == 1 ? 'dia' : 'dias',
        detalhe: recorde > seq
            ? 'recorde: $recorde dias'
            : seq > 0
                ? 'é o seu recorde!'
                : 'treine hoje para começar',
      ),
      _Bloco(
        icone: Icons.pie_chart_rounded,
        cor: p.accentAlt,
        rotulo: 'Do cofre',
        valor: '$fatia',
        unidade: '%',
        detalhe: '${Formatters.points(cofre)} pts no total',
      ),
      _Bloco(
        icone: Icons.star_rounded,
        cor: p.gold,
        rotulo: 'Desde sempre',
        valor: Formatters.points(member.totalPoints),
        unidade: 'pts',
        detalhe: 'pontos acumulados',
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < blocos.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Space.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: blocos[i]),
                const SizedBox(width: Space.md),
                Expanded(child: blocos[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.icone,
    required this.cor,
    required this.rotulo,
    required this.valor,
    required this.unidade,
    required this.detalhe,
  });

  final IconData icone;
  final Color cor;
  final String rotulo;
  final String valor;
  final String unidade;
  final String detalhe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Surface(
      radius: Radii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 16, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.labelLarge?.copyWith(fontSize: 14, color: cor),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(valor, style: t.displayMedium?.copyWith(fontSize: 30)),
                const SizedBox(width: 3),
                Text(
                  unidade,
                  style: t.labelLarge?.copyWith(color: t.bodySmall?.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalhe,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Uma linha do histórico, como item de lista do iOS.
class _Registro extends StatelessWidget {
  const _Registro({required this.log});

  final ActivityLog log;

  /// Miniatura: a foto nova em base64 (enquanto vale) ou a antiga do
  /// Storage. A versão anterior só olhava o Storage, e as fotos novas nunca
  /// apareciam aqui.
  Widget? _miniatura() {
    Widget quadrado(Widget img) => ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(width: 36, height: 36, child: img),
        );
    if (!PhotoProof.venceu(log.photoExpiresAt)) {
      final Uint8List? bytes = PhotoProof.decodificar(log.photoData);
      if (bytes != null) {
        return quadrado(Image.memory(
          bytes,
          fit: BoxFit.cover,
          cacheWidth: 108,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ));
      }
    }
    final url = log.photoUrl;
    if (url != null && url.isNotEmpty) {
      return quadrado(Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: 108,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final quando = log.createdAt;
    final miniatura = _miniatura();

    return InsetRow(
      icon: iconForActivity(log.type),
      tint: _corDoGrupo(p, log.type.group),
      title: log.type.label,
      subtitle: [
        Formatters.duration(log.durationMinutes),
        if (log.steps > 0) '${Formatters.points(log.steps)} passos',
        if (quando != null)
          '${quando.hour.toString().padLeft(2, '0')}:'
              '${quando.minute.toString().padLeft(2, '0')}',
        if (log.isOfflineSync) 'registrado offline',
      ].join(' · '),
      showChevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (miniatura != null) ...[
            miniatura,
            const SizedBox(width: Space.md)
          ],
          Text(
            '+${Formatters.points(log.points)}',
            style: t.labelLarge?.copyWith(
              color: p.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.souEu, required this.nome});

  final bool souEu;
  final String nome;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Surface(
      radius: Radii.xl,
      padding: const EdgeInsets.symmetric(
        vertical: Space.xxl,
        horizontal: Space.xl,
      ),
      child: Column(
        children: [
          Icon(Icons.directions_run_rounded, size: 34, color: p.textMuted),
          const SizedBox(height: Space.md),
          Text(
            souEu ? 'Nenhum treino ainda' : '$nome ainda não registrou nada',
            style: t.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            souEu
                ? 'O primeiro registro aparece aqui, com o dia e a foto.'
                : 'Quando registrar, o histórico aparece aqui.',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Aviso no topo do progresso quando a consulta falha.
class _AvisoErro extends StatelessWidget {
  const _AvisoErro({required this.erro});

  final Object? erro;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final traduzido = FirestoreErros.traduzir(erro);
    final link = traduzido.link;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.lg),
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.energySoft,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(traduzido.titulo,
              style: t.labelLarge?.copyWith(color: p.danger)),
          const SizedBox(height: Space.xs),
          Text(
            traduzido.texto,
            style: t.bodySmall?.copyWith(color: p.danger, height: 1.45),
          ),
          if (link != null) ...[
            const SizedBox(height: Space.md),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: link));
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copiado — cole no navegador'),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 15, color: p.danger),
                  const SizedBox(width: Space.sm),
                  Text(
                    'Copiar o link da correção',
                    style: t.labelMedium?.copyWith(color: p.danger),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
