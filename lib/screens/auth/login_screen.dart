import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../services/app_exception.dart';
import '../../services/auth_service.dart';

/// Entrada do app: login ou cadastro (que já cria/entra numa família).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _familyName = TextEditingController();
  final _inviteCode = TextEditingController();

  bool _isSignUp = false;
  bool _createNewFamily = true;
  bool _loading = false;
  String? _error;
  String _role = 'membro';
  String _avatar = '🙂';

  static const List<String> _avatars = [
    '🙂', '😎', '🦸', '🧔', '👩', '👵', '👴', '🐻', '🦊', '🐼'
  ];

  static const Map<String, String> _roles = {
    'mae': 'Mãe',
    'pai': 'Pai',
    'filho': 'Filho(a)',
    'membro': 'Outro',
  };

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _familyName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text(
                  'Desafio em Família',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Um cofre de pontos, quatro pessoas, um prêmio por semana.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Alternância login / cadastro
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    children: [
                      _ModeTab(
                        label: 'Entrar',
                        selected: !_isSignUp,
                        onTap: () => setState(() {
                          _isSignUp = false;
                          _error = null;
                        }),
                      ),
                      _ModeTab(
                        label: 'Criar conta',
                        selected: _isSignUp,
                        onTap: () => setState(() {
                          _isSignUp = true;
                          _error = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isSignUp) ...[
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().length < 2)
                            ? 'Digite seu nome'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  _AvatarPicker(
                    avatars: _avatars,
                    selected: _avatar,
                    onSelected: (emoji) => setState(() => _avatar = emoji),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(
                      labelText: 'Quem é você na família?',
                      prefixIcon: Icon(Icons.family_restroom_outlined),
                    ),
                    items: _roles.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _role = value ?? 'membro'),
                  ),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),

                if (_isSignUp) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'Sua família',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          emoji: '🏠',
                          label: 'Criar família',
                          selected: _createNewFamily,
                          onTap: () =>
                              setState(() => _createNewFamily = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ChoiceCard(
                          emoji: '🔑',
                          label: 'Tenho convite',
                          selected: !_createNewFamily,
                          onTap: () =>
                              setState(() => _createNewFamily = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_createNewFamily)
                    TextFormField(
                      controller: _familyName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome da família',
                        hintText: 'Ex.: Família Silva',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (value) {
                        if (!_isSignUp || !_createNewFamily) return null;
                        return (value == null || value.trim().isEmpty)
                            ? 'Dê um nome para a família'
                            : null;
                      },
                    )
                  else
                    TextFormField(
                      controller: _inviteCode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código do convite',
                        hintText: 'Ex.: K7M2PQ',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      validator: (value) {
                        if (!_isSignUp || _createNewFamily) return null;
                        return (value == null || value.trim().length < 4)
                            ? 'Informe o código recebido'
                            : null;
                      },
                    ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceRaised,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: context.palette.danger,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isSignUp ? 'Criar minha conta' : 'Entrar'),
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: const Text('Esqueci minha senha'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthService>();

    try {
      if (_isSignUp) {
        await auth.signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          role: _role,
          avatarEmoji: _avatar,
          familyName: _createNewFamily ? _familyName.text : null,
          inviteCode: _createNewFamily ? null : _inviteCode.text,
        );
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      // O AuthGate troca de tela sozinho quando a sessão muda.
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Algo deu errado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_email.text.contains('@')) {
      setState(() => _error = 'Digite seu e-mail para recuperar a senha.');
      return;
    }
    try {
      await context.read<AuthService>().sendPasswordReset(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviamos um e-mail de recuperação.')),
      );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? context.palette.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? context.palette.onAccent
                  : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? context.palette.accentSoft : context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.palette.accent : context.palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatars,
    required this.selected,
    required this.onSelected,
  });

  final List<String> avatars;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha seu avatar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: avatars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final emoji = avatars[index];
              final isSelected = emoji == selected;
              return GestureDetector(
                onTap: () => onSelected(emoji),
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.palette.accentSoft
                        : context.palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? context.palette.accent
                          : context.palette.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
