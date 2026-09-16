import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../services/app_exception.dart';
import '../../services/family_service.dart';
import '../../state/session_controller.dart';

/// Tela para quem está logado mas ainda não tem família — acontece se o
/// cadastro foi interrompido no meio.
class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _familyName =
      TextEditingController(text: FamilyService.nomePadrao);
  final _inviteCode = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _familyName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua família'),
        actions: [
          TextButton(
            onPressed: session.signOut,
            child: const Text('Sair'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Falta o time!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Crie a família ou entre com o código que alguém te mandou.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _familyName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome da família',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _createFamily,
              child: const Text('Criar família'),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _inviteCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código do convite',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : _joinFamily,
              child: const Text('Entrar com o código'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                _error!,
                style: TextStyle(color: context.palette.danger),
                textAlign: TextAlign.center,
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    final name = _familyName.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Dê um nome para a família.');
      return;
    }

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // O AuthGate troca de tela sozinho quando o perfil ganha o familyId.
      await context
          .read<FamilyService>()
          .createFamily(name: name, ownerId: user.id);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível criar agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    final code = _inviteCode.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Informe o código do convite.');
      return;
    }

    final user = context.read<SessionController>().user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context
          .read<FamilyService>()
          .joinFamilyByCode(inviteCode: code, userId: user.id);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível entrar agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
