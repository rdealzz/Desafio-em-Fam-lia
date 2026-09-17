import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_type.dart';
import '../../models/app_user.dart';
import '../../services/activity_service.dart';
import '../../services/photo_proof.dart';
import '../../services/activity_sync_service.dart';
import '../../services/app_exception.dart';
import '../../services/health_service.dart';
import '../../services/points_calculator.dart';
import '../../state/session_controller.dart';
import '../../widgets/activity_type_grid.dart';
import '../../widgets/ui/activity_icons.dart';
import '../../widgets/ui/duration_dial.dart';
import '../../widgets/ui/pressable.dart';
import '../../widgets/ui/primitives.dart';

/// TELA 2 — Registrar atividade.
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

  static const List<int> _atalhos = [15, 30, 45, 60, 90];

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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final b = _breakdown;
    final exigeFoto =
        context.watch<SessionController>().family?.requirePhotoProof ?? true;
    final semFoto = exigeFoto && _photoBytes == null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.lg,
            Space.gutter,
            Space.huge,
          ),
          children: [
            Text('Registrar', style: t.headlineMedium),
            const SizedBox(height: Space.xs),
            Text(
              'Os pontos vão direto para o cofre da família.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Space.xl),

            ActivityTypeGrid(
              selected: _type,
              onSelected: (tipo) => setState(() {
                _type = tipo;
                if (!tipo.tracksSteps) {
                  _stepCount = 0;
                  _steps.clear();
                }
              }),
            ),
            const SizedBox(height: Space.xxl),

            const SectionLabel('Duração'),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DurationDial(
                    minutes: _minutes,
                    onChanged: (m) => setState(() => _minutes = m),
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
                              setState(() => _minutes = v);
                            },
                          ),
                        ),
                        if (v != _atalhos.last) const SizedBox(width: Space.sm),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (_type.tracksSteps) ...[
              const SizedBox(height: Space.xxl),
              const SectionLabel('Passos (opcional)'),
              Surface(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _steps,
                        keyboardType: TextInputType.number,
                        style: t.titleMedium,
                        decoration: const InputDecoration(
                          hintText: '4200',
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) =>
                            setState(() => _stepCount = int.tryParse(v) ?? 0),
                      ),
                    ),
                    Text('+1 pt / 100 passos', style: t.bodySmall),
                    const SizedBox(width: Space.md),
                    _BotaoSync(
                      carregando: _loadingSteps,
                      onTap: _importarPassos,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: Space.xxl),
            SectionLabel(exigeFoto ? 'Comprovante · obrigatório' : 'Comprovante'),
            _Foto(
              bytes: _photoBytes,
              obrigatoria: exigeFoto,
              onPick: _escolherFoto,
              onRemove: () => setState(() => _photoBytes = null),
            ),

            const SizedBox(height: Space.xxl),
            const SectionLabel('Comentário'),
            TextField(
              controller: _note,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'opcional — aparece no mural',
                counterText: '',
              ),
            ),

            const SizedBox(height: Space.xl),
            _Resumo(breakdown: b, type: _type),
            const SizedBox(height: Space.lg),

            Pressable(
              onPressed: _saving || b.total <= 0 || semFoto ? null : _enviar,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: p.onAccent,
                      ),
                    )
                  : Text(
                      b.total <= 0
                          ? 'Aumente o tempo para pontuar'
                          : semFoto
                              ? 'Anexe a foto para registrar'
                              : 'Depositar ${Formatters.points(b.total)} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escolherFoto() async {
    final fonte = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto agora'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
            ),
            const SizedBox(height: Space.md),
          ],
        ),
      ),
    );
    if (fonte == null) return;

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
    if (mounted) setState(() => _photoBytes = bytes);
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
            content: Text('Contador de passos não conectado — digite o número.'),
          ),
        );
      } else {
        setState(() {
          _stepCount = passos;
          _steps.text = '$passos';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingSteps = false);
    }
  }

  Future<void> _enviar() async {
    final user = context.read<SessionController>().user;
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
      _limpar();
      HapticFeedback.mediumImpact();
      await _sucesso(r);
      widget.onDone?.call();
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

  void _limpar() {
    setState(() {
      _photoBytes = null;
      _stepCount = 0;
      _minutes = 30;
      _steps.clear();
      _note.clear();
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
        const SnackBar(content: Text('Não foi possível registrar nem guardar.')),
      );
      return;
    }
    if (!mounted) return;
    _limpar();
    await _dialogo(
      icone: Icons.cloud_upload_outlined,
      titulo: 'Guardado no celular',
      corpo: 'Sem internet agora. ${tipo.label} de '
          '${Formatters.duration(minutos)} entra no cofre assim que a conexão '
          'voltar — você não precisa fazer mais nada.',
    );
  }

  Future<void> _sucesso(ActivityRegistrationResult r) {
    final premios = r.unlockedRewards;
    return _dialogo(
      icone: Icons.check_circle_outline_rounded,
      titulo: '+${Formatters.points(r.pointsEarned)} pts',
      corpo: 'Cofre em ${Formatters.points(r.vaultPoints)} de '
          '${Formatters.points(r.weeklyGoal)}.'
          '${r.currentStreak > 1 ? ' Sequência de ${r.currentStreak} dias.' : ''}'
          '${premios.isEmpty ? '' : '\n\n${premios.map((p) => '${p.emoji} ${p.title} liberado!').join('\n')}'}',
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

class _Resumo extends StatelessWidget {
  const _Resumo({required this.breakdown, required this.type});

  final PointsBreakdown breakdown;
  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Surface(
      color: p.surfaceRaised,
      child: Column(
        children: [
          Row(
            children: [
              Icon(iconForActivity(type), size: 19, color: p.textSecondary),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(type.label, style: t.labelLarge),
              ),
              Text(
                Formatters.points(breakdown.total),
                style: t.displayMedium?.copyWith(fontSize: 30, color: p.accent),
              ),
              const SizedBox(width: Space.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('pts', style: t.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Divider(height: 1, color: p.border),
          const SizedBox(height: Space.md),
          _Linha(
            label: '${breakdown.completedBlocks} × ${type.blockMinutes} min',
            valor: '${breakdown.basePoints}',
          ),
          if (type.tracksSteps)
            _Linha(
              label: 'bônus de passos',
              valor: '+${breakdown.stepsPoints}',
            ),
          if (breakdown.minutesToNextBlock > 0) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 14, color: p.accent),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'mais ${breakdown.minutesToNextBlock} min e você ganha '
                    '+${type.blockPoints} pts',
                    style: t.bodySmall?.copyWith(color: p.accent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.label, required this.valor});

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodySmall)),
          Text(
            valor,
            style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({
    required this.bytes,
    required this.obrigatoria,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final bool obrigatoria;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (bytes == null) {
      return PressableCard(
        onTap: onPick,
        padding: const EdgeInsets.symmetric(vertical: Space.xl),
        child: Column(
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 24,
              color: obrigatoria ? p.accent : p.textSecondary,
            ),
            const SizedBox(height: Space.md),
            Text(
              obrigatoria ? 'Foto obrigatória' : 'Anexar foto',
              style: t.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              obrigatoria
                  ? 'sem foto não dá para registrar'
                  : 'a prova vai para o mural',
              style: t.bodySmall,
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Stack(
        children: [
          Image.memory(
            bytes!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: Space.sm,
            right: Space.sm,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
