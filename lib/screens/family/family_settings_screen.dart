import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../services/app_exception.dart';
import '../../services/family_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/ui/inset_group.dart';

/// Ajustes que valem para a família inteira: meta da semana e exigência de
/// foto.
///
/// Existe porque os dois dependem do mundo real e mudam com ele: a meta muda
/// quando a turma pega ritmo, e a foto depende de o Firebase Storage estar
/// disponível — em projeto novo ele só existe no plano Blaze. Sem esta tela,
/// mexer nisso exigiria editar o documento no console do Firebase.
class FamilySettingsScreen extends StatelessWidget {
  const FamilySettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FamilySettingsScreen()),
    );
  }

  /// Degraus em vez de campo livre: meta é decisão de turma, não de precisão.
  static const List<int> metas = [3000, 4000, 5000, 6000, 8000, 10000];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final family = session.family;
    final t = Theme.of(context).textTheme;

    if (family == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustes da família')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes da família')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.huge,
        ),
        children: [
          InsetGroup(
            header: 'Meta da semana',
            footer: 'O cofre zera toda segunda-feira. A meta é quanto a '
                'família junta até domingo.',
            children: [
              InsetRow(
                icon: Icons.flag_outlined,
                title: 'Pontos para a semana',
                showChevron: false,
                trailing: DropdownButton<int>(
                  value: metas.contains(family.weeklyGoal)
                      ? family.weeklyGoal
                      : null,
                  hint: Text('${family.weeklyGoal}'),
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(Radii.group),
                  items: [
                    for (final m in metas)
                      DropdownMenuItem(
                        value: m,
                        child: Text('${m ~/ 1000} mil'),
                      ),
                  ],
                  onChanged: (v) => _salvar(
                    context,
                    () => context
                        .read<FamilyService>()
                        .updateWeeklyGoal(family.id, v ?? family.weeklyGoal),
                    'Meta atualizada',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),

          InsetGroup(
            header: 'Foto comprovante',
            footer: family.requirePhotoProof
                ? 'O servidor recusa registro sem foto — não é só a tela '
                    'pedindo. A foto aparece no mural por um dia e depois é '
                    'apagada sozinha.'
                : 'Sem isso, a foto continua podendo ser anexada, só deixa de '
                    'ser obrigatória.',
            children: [
              InsetRow(
                icon: Icons.photo_camera_outlined,
                title: 'Exigir foto em todo registro',
                subtitle: family.requirePhotoProof
                    ? 'ligado — some do mural depois de 1 dia'
                    : 'desligado — a foto fica opcional',
                showChevron: false,
                trailing: Switch.adaptive(
                  value: family.requirePhotoProof,
                  onChanged: (v) => _salvar(
                    context,
                    () => context
                        .read<FamilyService>()
                        .setRequirePhotoProof(family.id, v),
                    v ? 'Foto passou a ser obrigatória' : 'Foto agora é opcional',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),

          InsetGroup(
            header: 'Convite',
            children: [
              InsetRow(
                icon: Icons.confirmation_number_outlined,
                title: 'Código da família',
                value: family.inviteCode,
                showChevron: false,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: family.inviteCode));
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código ${family.inviteCode} copiado')),
                  );
                },
              ),
              InsetRow(
                icon: Icons.group_outlined,
                title: 'Integrantes',
                value: '${family.memberIds.length} de ${FamilyService.maxMembers}',
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Estes ajustes valem para todo mundo da família.',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: context.palette.textMuted),
          ),
        ],
      ),
    );
  }

  /// Salva e avisa. O estado vem do Firestore em tempo real, então a tela se
  /// redesenha sozinha quando a gravação volta — não há estado local a mexer.
  Future<void> _salvar(
    BuildContext context,
    Future<void> Function() acao,
    String aviso,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await acao();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(aviso)));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não consegui salvar agora.')),
      );
    }
  }
}
