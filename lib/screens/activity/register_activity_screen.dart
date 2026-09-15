import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_type.dart';
import '../../models/app_user.dart';
import '../../services/activity_service.dart';
import '../../services/activity_sync_service.dart';
import '../../services/app_exception.dart';
import '../../services/health_service.dart';
import '../../services/points_calculator.dart';
import '../../state/session_controller.dart';
import '../../widgets/activity_type_grid.dart';

/// TELA 2 — Registro de Atividade.
///
/// Fluxo curto de propósito: escolher a modalidade, dizer o tempo, (opcional)
/// tirar foto e confirmar. O total de pontos é recalculado a cada toque.
class RegisterActivityScreen extends StatefulWidget {
  const RegisterActivityScreen({super.key, this.onDone});

  /// Chamado depois de salvar — a casca leva para o Mural.
  final VoidCallback? onDone;

  @override
  State<RegisterActivityScreen> createState() => _RegisterActivityScreenState();
}

class _RegisterActivityScreenState extends State<RegisterActivityScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  ActivityType _type = ActivityType.walk;
  int _minutes = 30;
  int _steps = 0;
  File? _photo;
  bool _saving = false;
  bool _loadingSteps = false;

  /// Atalhos de duração — cobrem o uso real sem abrir o teclado.
  static const List<int> _quickMinutes = [10, 15, 20, 30, 45, 60, 90];

  @override
  void dispose() {
    _stepsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Botão desabilitado precisa dizer o que falta, senão vira beco sem saída.
  String _submitLabel(PointsBreakdown breakdown, bool missingPhoto) {
    if (breakdown.total <= 0) return 'Aumente o tempo para pontuar';
    if (missingPhoto) return 'Anexe a foto para registrar';
    return 'Depositar ${Formatters.points(breakdown.total)} pts no cofre';
  }

  PointsBreakdown get _breakdown => PointsCalculator.calculate(
        type: _type,
        minutes: _minutes,
        steps: _steps,
      );

  @override
  Widget build(BuildContext context) {
    final breakdown = _breakdown;
    // Na dúvida (família ainda carregando), exige — o padrão seguro é pedir a
    // prova, não dispensá-la.
    final requiresPhoto =
        context.watch<SessionController>().family?.requirePhotoProof ?? true;
    final missingPhoto = requiresPhoto && _photo == null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'Registrar Atividade',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Escolha o que você fez hoje. Os pontos vão direto para o cofre.',
              style: TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 22),

            ActivityTypeGrid(
              selected: _type,
              onSelected: (type) => setState(() {
                _type = type;
                if (!type.tracksSteps) _steps = 0;
              }),
            ),
            const SizedBox(height: 26),

            // --- Duração --------------------------------------------------
            Row(
              children: [
                Text(
                  'Quanto tempo?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  Formatters.duration(_minutes),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickMinutes.map((value) {
                final selected = _minutes == value;
                return GestureDetector(
                  onTap: () => setState(() => _minutes = value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE7E5F2),
                      ),
                    ),
                    child: Text(
                      '$value min',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _minutes.toDouble(),
              min: 5,
              max: PointsCalculator.maxMinutesPerLog.toDouble(),
              divisions: (PointsCalculator.maxMinutesPerLog - 5) ~/ 5,
              label: '$_minutes min',
              onChanged: (value) => setState(() => _minutes = value.round()),
            ),

            // --- Passos (só caminhada) ------------------------------------
            if (_type.tracksSteps) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_walk,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Passos (opcional)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '+1 ponto a cada 100 passos',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stepsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Ex.: 4200',
                              isDense: true,
                            ),
                            onChanged: (value) => setState(
                              () => _steps = int.tryParse(value) ?? 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: 'Buscar do celular',
                          onPressed: _loadingSteps ? null : _importSteps,
                          icon: _loadingSteps
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // --- Foto comprovante -----------------------------------------
            _PhotoPicker(
              photo: _photo,
              required: requiresPhoto,
              onPick: _pickPhoto,
              onRemove: () => setState(() => _photo = null),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _noteController,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Escrever algo no mural (opcional)',
                hintText: 'Ex.: caminhada com a vizinha 😄',
              ),
            ),
            const SizedBox(height: 8),

            // --- Preview dos pontos ---------------------------------------
            _PointsPreview(breakdown: breakdown, type: _type),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _saving || breakdown.total <= 0 || missingPhoto
                  ? null
                  : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(_submitLabel(breakdown, missingPhoto)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
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
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto agora'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Comprime na origem: comprovante não precisa de resolução máxima e
    // upload leve economiza dado móvel da família.
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _importSteps() async {
    setState(() => _loadingSteps = true);
    final service = context.read<StepsService>();

    try {
      final granted = await service.requestPermission();
      final steps = granted ? await service.stepsForDay() : null;

      if (!mounted) return;
      if (steps == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Contador de passos ainda não conectado — digite o número.',
            ),
          ),
        );
      } else {
        setState(() {
          _steps = steps;
          _stepsController.text = steps.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingSteps = false);
    }
  }

  Future<void> _submit() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    // Marcada agora, antes de qualquer espera de rede: se o registro cair na
    // fila, o que vale é a hora em que a pessoa terminou o exercício.
    final performedAt = DateTime.now();

    setState(() => _saving = true);

    try {
      final result = await context.read<ActivityService>().registerActivity(
            user: user,
            type: _type,
            durationMinutes: _minutes,
            steps: _steps,
            photo: _photo,
            note: _noteController.text.trim(),
            performedAt: performedAt,
          );

      if (!mounted) return;

      // Volta ao estado inicial para o próximo registro.
      setState(() {
        _photo = null;
        _steps = 0;
        _minutes = 30;
        _stepsController.clear();
        _noteController.clear();
      });

      await _showSuccess(result);
      widget.onDone?.call();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      // Chegou aqui depois de a regra de negócio passar, então quase sempre é
      // rede. Guardar é melhor que perder: o exercício já foi feito.
      await _guardarParaDepois(user, performedAt);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Guarda o registro na fila local e limpa a tela como se tivesse enviado —
  /// da perspectiva de quem treinou, está registrado; só ainda não subiu.
  Future<void> _guardarParaDepois(AppUser user, DateTime performedAt) async {
    final note = _noteController.text.trim();
    final photo = _photo;
    final type = _type;
    final minutes = _minutes;
    final steps = _steps;

    try {
      await context.read<ActivitySyncService>().enqueue(
            user: user,
            type: type,
            durationMinutes: minutes,
            steps: steps,
            photo: photo,
            note: note,
            performedAt: performedAt,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar nem guardar. Tente de novo.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _photo = null;
      _steps = 0;
      _minutes = 30;
      _stepsController.clear();
      _noteController.clear();
    });

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Guardado no celular',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sem internet agora. ${type.emoji} ${type.label} de '
              '${Formatters.duration(minutes)} entra no cofre assim que a '
              'conexão voltar — você não precisa fazer mais nada.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.45),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess(ActivityRegistrationResult result) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '+${Formatters.points(result.pointsEarned)} pontos!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cofre em ${Formatters.points(result.vaultPoints)} / '
              '${Formatters.points(result.weeklyGoal)} pts',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            if (result.currentStreak > 1) ...[
              const SizedBox(height: 10),
              Text(
                '🔥 ${result.currentStreak} dias seguidos!',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
            if (result.unlockedRewards.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: result.unlockedRewards
                      .map(
                        (reward) => Text(
                          '${reward.emoji} ${reward.title} desbloqueado!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B7F4C),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Ver no mural'),
          ),
        ],
      ),
    );
  }
}

/// Cartão com o total de pontos e a explicação da conta.
class _PointsPreview extends StatelessWidget {
  const _PointsPreview({required this.breakdown, required this.type});

  final PointsBreakdown breakdown;
  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.activityGroup[type.group.id] ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Você vai ganhar',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.points(breakdown.total)} pts',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(type.emoji, style: const TextStyle(fontSize: 40)),
            ],
          ),
          const SizedBox(height: 14),
          _BreakdownLine(
            label: '${breakdown.completedBlocks}x ${type.blockMinutes} min',
            value: '${breakdown.basePoints} pts',
          ),
          if (type.tracksSteps)
            _BreakdownLine(
              label: 'Bônus de passos',
              value: '+${breakdown.stepsPoints} pts',
            ),
          if (breakdown.minutesToNextBlock > 0) ...[
            const SizedBox(height: 8),
            Text(
              '💡 Mais ${breakdown.minutesToNextBlock} min e você ganha '
              '+${type.blockPoints} pts',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.required,
    required this.onPick,
    required this.onRemove,
  });

  final File? photo;

  /// Quando a família exige comprovante, o vazio é um bloqueio — e precisa
  /// parecer um: contorno laranja e a palavra "obrigatória".
  final bool required;

  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo == null) {
      final accent = required ? AppColors.secondary : AppColors.primary;
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 124,
          decoration: BoxDecoration(
            color: required ? accent.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: required ? accent : const Color(0xFFD9D6E8),
              width: required ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 28, color: accent),
              const SizedBox(height: 8),
              Text(
                required ? 'Foto obrigatória' : 'Anexar foto do momento',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: required ? accent : AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                required
                    ? 'Sem foto não dá para registrar — é a prova que vale no mural'
                    : 'A prova vai para o mural 😄',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            photo!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.55),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}
