import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_type.dart';
import '../../models/app_user.dart';
import '../../models/reward.dart';
import '../../services/activity_service.dart';
import '../../services/photo_proof.dart';
import '../../services/activity_sync_service.dart';
import '../../services/ultimo_treino.dart';
import '../../services/app_exception.dart';
import '../../services/health_service.dart';
import '../../services/points_calculator.dart';
import '../../state/session_controller.dart';
import '../../widgets/activity_type_grid.dart';
import '../../widgets/ui/activity_icons.dart';
import '../../widgets/ui/barra_marcos.dart';
import '../../widgets/ui/duration_dial.dart';
import '../../widgets/ui/entrada.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/reaction_icons.dart';
import '../../widgets/ui/primitives.dart';

/// TELA 2 — Registrar atividade.
///
/// Um formulário em quatro passos (modalidade, duração, foto, comentário)
/// com uma barra fixa embaixo: os pontos que vão entrar e o botão de
/// depositar ficam sempre à vista, em vez de lá no fim da rolagem. Quando
/// falta algo, a própria barra diz o quê.
class RegisterActivityScreen extends StatefulWidget {
  const RegisterActivityScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<RegisterActivityScreen> createState() => _RegisterActivityScreenState();
}

class _RegisterActivityScreenState extends State<RegisterActivityScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _steps = TextEditingController();
  final TextEditingController _note = TextEditingController();

  ActivityType _type = ActivityType.walk;
  int _minutes = 30;
  int _stepCount = 0;
  Uint8List? _photoBytes;
  bool _saving = false;
  bool _loadingSteps = false;

  /// O último treino deste aparelho, para o atalho "repetir".
  UltimoTreino? _ultimo;

  /// A pessoa já mexeu no formulário: o último treino não sobrescreve mais.
  bool _mexeu = false;

  static const List<int> _atalhos = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    UltimoTreino.carregar().then((u) {
      if (!mounted || u == null) return;
      setState(() {
        _ultimo = u;
        // Abre no que a pessoa costuma fazer — se ela ainda não começou a
        // escolher outra coisa.
        if (!_mexeu) {
          _type = u.tipo;
          _minutes = u.minutos;
        }
      });
    });
  }

  @override
  void dispose() {
    _steps.dispose();
    _note.dispose();
    super.dispose();
  }

  PointsBreakdown get _breakdown => PointsCalculator.calculate(
        type: _type,
        minutes: _minutes,
        steps: _stepCount,
      );

  void _mudar(VoidCallback f) {
    _mexeu = true;
    setState(f);
  }

  void _escolherTipo(ActivityType tipo) => _mudar(() {
        _type = tipo;
        if (!tipo.tracksSteps) {
          _stepCount = 0;
          _steps.clear();
        }
      });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = _breakdown;
    final session = context.watch<SessionController>();
    final family = session.family;
    final exigeFoto = family?.requirePhotoProof ?? true;
    final semFoto = exigeFoto && _photoBytes == null;
    final ultimo = _ultimo;
    final mostrarRepetir =
        ultimo != null && (ultimo.tipo != _type || ultimo.minutos != _minutes);

    final String? falta = b.total <= 0
        ? 'aumente o tempo para pontuar'
        : semFoto
            ? 'falta a foto comprovante'
            : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.lg,
                  Space.gutter,
                  Space.xl,
                ),
                children: [
                  Entrada(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REGISTRAR', style: t.labelMedium),
                        const SizedBox(height: 2),
                        Text('O que você fez hoje?', style: t.headlineMedium),
                        const SizedBox(height: Space.xs),
                        Text(
                          'Os pontos vão direto para o cofre da família.',
                          style: t.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (mostrarRepetir) ...[
                    const SizedBox(height: Space.lg),
                    Entrada(
                      ordem: 1,
                      child: _Repetir(
                        ultimo: ultimo,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _mudar(() {
                            _type = ultimo.tipo;
                            _minutes = ultimo.minutos;
                            if (!ultimo.tipo.tracksSteps) {
                              _stepCount = 0;
                              _steps.clear();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.xl),
                  const Entrada(
                    ordem: 2,
                    child: _Etapa(numero: 1, titulo: 'Modalidade'),
                  ),
                  Entrada(
                    ordem: 2,
                    child: ActivityTypeGrid(
                      selected: _type,
                      onSelected: _escolherTipo,
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  const _Etapa(numero: 2, titulo: 'Duração'),
                  Surface(
                    radius: Radii.xl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DurationDial(
                          minutes: _minutes,
                          onChanged: (m) => _mudar(() => _minutes = m),
                        ),
                        const SizedBox(height: Space.lg),
                        Row(
                          children: [
                            for (final v in _atalhos) ...[
                              Expanded(
                                child: _Atalho(
                                  minutos: v,
                                  ativo: _minutes == v,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _mudar(() => _minutes = v);
                                  },
                                ),
                              ),
                              if (v != _atalhos.last)
                                const SizedBox(width: Space.sm),
                            ],
                          ],
                        ),
                        const SizedBox(height: Space.lg),
                        _ProximoBloco(breakdown: b, type: _type),
                      ],
                    ),
                  ),
                  if (_type.tracksSteps) ...[
                    const SizedBox(height: Space.lg),
                    Surface(
                      radius: Radii.xl,
                      child: Row(
                        children: [
                          Icon(Icons.directions_walk_rounded,
                              size: 20, color: context.palette.textSecondary),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: TextField(
                              controller: _steps,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              style: t.titleMedium,
                              decoration: const InputDecoration(
                                hintText: 'passos (opcional)',
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => _mudar(
                                  () => _stepCount = int.tryParse(v) ?? 0),
                            ),
                          ),
                          Text('+1 pt / 100', style: t.bodySmall),
                          const SizedBox(width: Space.sm),
                          _BotaoSync(
                            carregando: _loadingSteps,
                            onTap: _importarPassos,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.xxl),
                  _Etapa(
                    numero: 3,
                    titulo: 'Comprovante',
                    detalhe: exigeFoto ? 'obrigatório' : 'opcional',
                  ),
                  _Foto(
                    bytes: _photoBytes,
                    obrigatoria: exigeFoto,
                    onPick: _escolherFoto,
                    onRemove: () => _mudar(() => _photoBytes = null),
                  ),
                  const SizedBox(height: Space.xxl),
                  const _Etapa(
                    numero: 4,
                    titulo: 'Comentário',
                    detalhe: 'opcional',
                  ),
                  TextField(
                    controller: _note,
                    maxLength: 140,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'aparece no mural — capricha na zoeira',
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            _BarraDeposito(
              breakdown: b,
              type: _type,
              cofreAntes: family?.vaultThisWeek ?? 0,
              falta: falta,
              salvando: _saving,
              onDepositar: _enviar,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escolherFoto(ImageSource fonte) async {
    // Pequena de propósito: a foto vai dentro do documento do Firestore, que
    // para em 1 MiB. Nesta faixa ela fica em algumas dezenas de KB, e 400 px
    // mostram de sobra que a pessoa estava lá — é prova, não álbum.
    final escolhida = await _picker.pickImage(
      source: fonte,
      imageQuality: PhotoProof.qualidade,
      maxWidth: PhotoProof.larguraMaxima.toDouble(),
    );
    if (escolhida == null) return;

    final bytes = await escolhida.readAsBytes();
    if (mounted) _mudar(() => _photoBytes = bytes);
  }

  Future<void> _importarPassos() async {
    setState(() => _loadingSteps = true);
    final servico = context.read<StepsService>();
    try {
      final ok = await servico.requestPermission();
      final passos = ok ? await servico.stepsForDay() : null;
      if (!mounted) return;
      if (passos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Contador de passos não conectado — digite o número.'),
          ),
        );
      } else {
        _mudar(() {
          _stepCount = passos;
          _steps.text = '$passos';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingSteps = false);
    }
  }

  Future<void> _enviar() async {
    final session = context.read<SessionController>();
    final user = session.user;
    if (user == null) return;

    final feitoEm = DateTime.now();
    setState(() => _saving = true);

    try {
      final r = await context.read<ActivityService>().registerActivity(
            user: user,
            type: _type,
            durationMinutes: _minutes,
            steps: _stepCount,
            photoBytes: _photoBytes,
            note: _note.text.trim(),
            performedAt: feitoEm,
          );
      if (!mounted) return;
      final tipo = _type;
      await _lembrar();
      _limpar();
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      final irAoMural = await Comemoracao.mostrar(
        context,
        resultado: r,
        tipo: tipo,
        rewards: session.family?.rewardsThisWeek ?? const [],
      );
      if (irAoMural == true) widget.onDone?.call();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      await _guardar(user, feitoEm);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Guarda modalidade e tempo para o próximo registro abrir neles.
  Future<void> _lembrar() async {
    final u = UltimoTreino(tipo: _type, minutos: _minutes);
    await UltimoTreino.salvar(u.tipo, u.minutos);
    _ultimo = u;
  }

  /// Depois de registrar, o formulário volta ao treino de costume — que é o
  /// que a pessoa acabou de fazer —, sem foto, passos nem comentário.
  void _limpar() {
    setState(() {
      _photoBytes = null;
      _stepCount = 0;
      _steps.clear();
      _note.clear();
      _mexeu = false;
    });
  }

  Future<void> _guardar(AppUser user, DateTime feitoEm) async {
    final tipo = _type;
    final minutos = _minutes;
    try {
      await context.read<ActivitySyncService>().enqueue(
            user: user,
            type: tipo,
            durationMinutes: minutos,
            steps: _stepCount,
            photoBytes: _photoBytes,
            note: _note.text.trim(),
            performedAt: feitoEm,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível registrar nem guardar.')),
      );
      return;
    }
    if (!mounted) return;
    await _lembrar();
    _limpar();
    if (!mounted) return;
    await _dialogo(
      icone: Icons.cloud_upload_outlined,
      titulo: 'Guardado no celular',
      corpo: 'Sem internet agora. ${tipo.label} de '
          '${Formatters.duration(minutos)} entra no cofre assim que a conexão '
          'voltar — você não precisa fazer mais nada.',
    );
  }

  Future<void> _dialogo({
    required IconData icone,
    required String titulo,
    required String corpo,
  }) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 30, color: p.accent),
            const SizedBox(height: Space.md),
            Text(titulo, style: t.headlineMedium),
            const SizedBox(height: Space.sm),
            Text(corpo, style: t.bodyMedium),
          ],
        ),
        actions: [
          Pressable(
            onPressed: () => Navigator.of(d).pop(),
            expand: false,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xl,
              vertical: Space.md,
            ),
            child: const Text(
              'Entendi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.minutos,
    required this.ativo,
    required this.onTap,
  });

  final int minutos;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ativo ? p.accentSoft : p.surfaceSunken,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: ativo ? p.accent : Colors.transparent),
        ),
        child: Text(
          '$minutos',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ativo ? p.accent : p.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _BotaoSync extends StatelessWidget {
  const _BotaoSync({required this.carregando, required this.onTap});

  final bool carregando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: carregando ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 34,
        height: 34,
        child: carregando
            ? const Center(
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Icon(Icons.sync_rounded, size: 18, color: p.accent),
      ),
    );
  }
}

/// Título de cada passo do formulário: número num círculo e o nome.
class _Etapa extends StatelessWidget {
  const _Etapa({required this.numero, required this.titulo, this.detalhe});

  final int numero;
  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: p.accentGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: TextStyle(
                color: p.onAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(titulo, style: t.titleMedium),
          if (detalhe != null) ...[
            const SizedBox(width: Space.sm),
            Text(detalhe!, style: t.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// "Repetir: Caminhada · 40 min" — o treino de sempre num toque.
class _Repetir extends StatelessWidget {
  const _Repetir({required this.ultimo, required this.onTap});

  final UltimoTreino ultimo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Icon(Icons.replay_rounded, size: 19, color: p.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Repetir: '),
                  TextSpan(
                    text: '${ultimo.tipo.label} · '
                        '${Formatters.duration(ultimo.minutos)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: t.bodyMedium?.copyWith(color: p.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(iconForActivity(ultimo.tipo), size: 18, color: p.textMuted),
        ],
      ),
    );
  }
}

/// Os blocos já garantidos e quanto falta para o próximo, dentro do cartão
/// de duração — é ali que a pessoa decide se estica mais dez minutos.
class _ProximoBloco extends StatelessWidget {
  const _ProximoBloco({required this.breakdown, required this.type});

  final PointsBreakdown breakdown;
  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final blocos = breakdown.completedBlocks;
    final falta = breakdown.minutesToNextBlock;
    final noTeto = falta <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: blocos == 0 ? p.energySoft : p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        children: [
          Icon(
            blocos == 0 ? Icons.hourglass_bottom_rounded : Icons.trending_up,
            size: 16,
            color: blocos == 0 ? p.energy : p.accent,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              blocos == 0
                  ? 'Mínimo de ${type.blockMinutes} min para pontuar — '
                      'faltam $falta min'
                  : noTeto
                      ? '$blocos ${blocos == 1 ? 'bloco' : 'blocos'} de '
                          '${type.blockMinutes} min — o máximo por registro'
                      : '$blocos ${blocos == 1 ? 'bloco' : 'blocos'} de '
                          '${type.blockMinutes} min · mais $falta min '
                          'valem +${type.blockPoints} pts',
              style: t.bodySmall?.copyWith(
                color: blocos == 0 ? p.energy : p.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A foto comprovante: câmera e galeria direto no cartão, sem menu no meio.
class _Foto extends StatelessWidget {
  const _Foto({
    required this.bytes,
    required this.obrigatoria,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final bool obrigatoria;
  final ValueChanged<ImageSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (bytes == null) {
      return Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(
            color: obrigatoria ? p.accent.withValues(alpha: 0.45) : p.border,
            width: obrigatoria ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: p.accentGradient,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.photo_camera_rounded, size: 24, color: p.onAccent),
            ),
            const SizedBox(height: Space.md),
            Text(
              obrigatoria ? 'Mostra que você foi!' : 'Quer mostrar no mural?',
              style: t.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              obrigatoria
                  ? 'a foto é o que libera o registro'
                  : 'a foto aparece no mural por um dia',
              style: t.bodySmall,
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    tone: PressableTone.neutral,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => onPick(ImageSource.camera),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 17),
                        SizedBox(width: Space.sm),
                        Text('Câmera'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Pressable(
                    tone: PressableTone.neutral,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => onPick(ImageSource.gallery),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 17),
                        SizedBox(width: Space.sm),
                        Text('Galeria'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xl),
      child: Stack(
        children: [
          Image.memory(
            bytes!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
          // Sombra embaixo para os botões lerem sobre qualquer foto.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Space.md,
            bottom: Space.md,
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    size: 17, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Comprovante anexado',
                  style: t.labelLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            right: Space.sm,
            bottom: Space.sm,
            child: _BotaoSobreFoto(
              icone: Icons.cached_rounded,
              rotulo: 'Trocar',
              onTap: () => onPick(ImageSource.gallery),
            ),
          ),
          Positioned(
            top: Space.sm,
            right: Space.sm,
            child: _BotaoSobreFoto(icone: Icons.close_rounded, onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class _BotaoSobreFoto extends StatelessWidget {
  const _BotaoSobreFoto(
      {required this.icone, required this.onTap, this.rotulo});

  final IconData icone;
  final String? rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: rotulo == null ? 0 : 12),
        width: rotulo == null ? 32 : null,
        decoration: BoxDecoration(
          color: const Color(0x99000000),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 16, color: Colors.white),
            if (rotulo != null) ...[
              const SizedBox(width: 6),
              Text(
                rotulo!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A barra fixa: quantos pontos vão entrar, o cofre antes → depois, e o
/// botão. Quando falta algo, diz o quê no lugar do cofre.
class _BarraDeposito extends StatelessWidget {
  const _BarraDeposito({
    required this.breakdown,
    required this.type,
    required this.cofreAntes,
    required this.falta,
    required this.salvando,
    required this.onDepositar,
  });

  final PointsBreakdown breakdown;
  final ActivityType type;
  final int cofreAntes;
  final String? falta;
  final bool salvando;
  final VoidCallback onDepositar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final total = breakdown.total;
    final pode = falta == null && !salvando;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    NumeroAnimado(
                      valor: total,
                      formatar: (v) => '+${Formatters.points(v)}',
                      style: t.displayMedium?.copyWith(
                        fontSize: 28,
                        color: total > 0 ? p.accent : p.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('pts', style: t.bodySmall),
                    if (breakdown.stepsPoints > 0) ...[
                      const SizedBox(width: Space.sm),
                      Flexible(
                        child: Text(
                          '(${breakdown.stepsPoints} de passos)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  falta ??
                      'cofre ${Formatters.points(cofreAntes)} → '
                          '${Formatters.points(cofreAntes + total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: falta == null ? p.textSecondary : p.energy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          Pressable(
            expand: false,
            onPressed: pode ? onDepositar : null,
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xl,
              vertical: 15,
            ),
            child: salvando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: p.onAccent,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_rounded, size: 19),
                      SizedBox(width: Space.sm),
                      Text(
                        'Depositar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A comemoração depois de registrar.
///
/// Os pontos sobem, a barra do cofre anda do valor de antes até o de agora,
/// e prêmio liberado aparece em dourado. É o momento de recompensa do app —
/// a caixinha de texto de antes não dava essa sensação.
class Comemoracao extends StatelessWidget {
  const Comemoracao({
    super.key,
    required this.resultado,
    required this.tipo,
    this.rewards = const [],
  });

  final ActivityRegistrationResult resultado;
  final ActivityType tipo;

  /// Prêmios da semana, para os marcos da barra.
  final List<Reward> rewards;

  /// Devolve `true` quando a pessoa quer ver o post no mural.
  static Future<bool?> mostrar(
    BuildContext context, {
    required ActivityRegistrationResult resultado,
    required ActivityType tipo,
    List<Reward> rewards = const [],
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Comemoracao(
        resultado: resultado,
        tipo: tipo,
        rewards: rewards,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final r = resultado;
    final meta = r.weeklyGoal;
    final depois = r.vaultPoints;
    final antes = (depois - r.pointsEarned).clamp(0, depois);
    final premios = r.unlockedRewards;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.xl,
          Space.xl,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: r.goalReached
                      ? LinearGradient(colors: [p.gold, p.energy])
                      : p.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (r.goalReached ? p.gold : p.accent)
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  r.goalReached
                      ? Icons.emoji_events_rounded
                      : iconForActivity(tipo),
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            NumeroAnimado(
              valor: r.pointsEarned,
              formatar: (v) => '+${Formatters.points(v)}',
              style: t.displayLarge?.copyWith(color: p.accent),
            ),
            Text('pts no cofre da família', style: t.bodyMedium),
            const SizedBox(height: Space.xl),
            BarraMarcos(
              inicio: meta <= 0 ? 0 : antes / meta,
              valor: meta <= 0 ? 0 : depois / meta,
              marcos: [
                for (final rw in rewards)
                  if (meta > 0 && rw.requiredPoints < meta)
                    rw.requiredPoints / meta,
              ],
              altura: 10,
            ),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Text(
                  '${Formatters.points(depois)} de ${Formatters.points(meta)}',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (r.currentStreak > 1)
                  MetaChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '${r.currentStreak} dias seguidos',
                    tone: p.energy,
                  ),
              ],
            ),
            if (premios.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              for (final pr in premios)
                Container(
                  margin: const EdgeInsets.only(bottom: Space.sm),
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: p.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    children: [
                      Icon(iconForReward(pr.emoji), size: 20, color: p.gold),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          '${pr.title} liberado!',
                          style: t.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: Space.lg),
            Pressable(
              onPressed: () => Navigator.of(context).pop(true),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Text(
                'Ver no mural',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Registrar outro'),
            ),
          ],
        ),
      ),
    );
  }
}
