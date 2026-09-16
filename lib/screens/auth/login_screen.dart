import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../services/app_exception.dart';
import '../../services/auth_service.dart';
import '../../services/family_service.dart';
import '../../widgets/ui/avatar_animals.dart';
import '../../widgets/ui/avatar_colors.dart';
import '../../widgets/ui/avatar_picker.dart';
import '../../widgets/ui/inset_group.dart';
import '../../widgets/ui/pressable.dart';

/// Entrada do app: usuário e senha.
///
/// Dois campos para entrar. Para criar conta, o mínimo: nome, usuário, senha e
/// de qual família você faz parte. Sem e-mail, sem confirmação, sem etapa
/// extra — cada pessoa se cadastra sozinha em menos de um minuto.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _nome = TextEditingController();
  final _nomeFamilia =
      TextEditingController(text: FamilyService.nomePadrao);
  final _convite = TextEditingController();

  bool _criandoConta = false;
  bool _criarFamilia = true;
  bool _mostrarSenha = false;
  bool _carregando = false;
  String? _erro;
  int _cor = AvatarColors.opcoes.first.toARGB32();
  String _bicho = AvatarAnimals.opcoes.first.emoji;
  String _papel = 'membro';

  static const Map<String, String> _papeis = {
    'mae': 'Mãe',
    'pai': 'Pai',
    'filho': 'Filho(a)',
    'membro': 'Outro',
  };

  @override
  void dispose() {
    for (final c in [_usuario, _senha, _nome, _nomeFamilia, _convite]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.xxl,
            Space.gutter,
            Space.huge,
          ),
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.groups_rounded, size: 27, color: p.accent),
            ),
            const SizedBox(height: Space.lg),
            Text('Desafio em Família', style: t.headlineMedium),
            const SizedBox(height: Space.xs),
            Text(
              'Um cofre de pontos, quatro pessoas, um prêmio por semana.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Space.xxl),

            _Alternador(
              criandoConta: _criandoConta,
              onChanged: (v) => setState(() {
                _criandoConta = v;
                _erro = null;
              }),
            ),
            const SizedBox(height: Space.xl),

            if (_criandoConta) ...[
              InsetGroup(
                header: 'Quem é você',
                children: [
                  _Campo(
                    controller: _nome,
                    label: 'Nome que aparece para os outros',
                    hint: 'ex.: Rafael',
                    icon: Icons.person_outline_rounded,
                    capitalize: true,
                  ),
                  InsetRow(
                    icon: Icons.family_restroom_rounded,
                    title: 'Papel na família',
                    showChevron: false,
                    trailing: DropdownButton<String>(
                      value: _papel,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(Radii.group),
                      items: [
                        for (final e in _papeis.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) =>
                          setState(() => _papel = v ?? 'membro'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      Space.md,
                      Space.lg,
                      Space.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seu bicho', style: t.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          'é assim que você aparece para a família — dá para '
                          'trocar por uma foto depois',
                          style: t.bodySmall,
                        ),
                        const SizedBox(height: Space.lg),
                        SeletorAnimal(
                          selecionado: _bicho,
                          cor: Color(_cor),
                          onSelected: (b) => setState(() => _bicho = b),
                        ),
                        const SizedBox(height: Space.lg),
                        Text('Cor de fundo', style: t.labelLarge),
                        const SizedBox(height: Space.md),
                        SeletorCor(
                          selecionada: _cor,
                          onSelected: (c) => setState(() => _cor = c),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
            ],

            InsetGroup(
              header: _criandoConta ? 'Sua entrada' : 'Entrar',
              footer: _criandoConta
                  ? 'Anote a senha: sem e-mail cadastrado, não há recuperação '
                      'automática.'
                  : null,
              children: [
                _Campo(
                  controller: _usuario,
                  label: 'Usuário',
                  hint: 'ex.: rafael',
                  icon: Icons.alternate_email_rounded,
                  autocorrect: false,
                ),
                _Campo(
                  controller: _senha,
                  label: 'Senha',
                  hint: 'pode ser simples, tipo 123',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_mostrarSenha,
                  trailing: GestureDetector(
                    onTap: () =>
                        setState(() => _mostrarSenha = !_mostrarSenha),
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      _mostrarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 19,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            if (_criandoConta) ...[
              const SizedBox(height: Space.xl),
              InsetGroup(
                header: 'Sua família',
                footer: _criarFamilia
                    ? 'Depois você compartilha o código do convite com os outros.'
                    : 'Peça o código para quem já criou a família.',
                children: [
                  InsetRow(
                    icon: Icons.add_home_outlined,
                    title: 'Criar uma família',
                    subtitle: 'sou o primeiro a entrar',
                    showChevron: false,
                    onTap: () => setState(() => _criarFamilia = true),
                    trailing: _Marca(ativo: _criarFamilia),
                  ),
                  InsetRow(
                    icon: Icons.vpn_key_outlined,
                    title: 'Tenho um convite',
                    subtitle: 'alguém já criou',
                    showChevron: false,
                    onTap: () => setState(() => _criarFamilia = false),
                    trailing: _Marca(ativo: !_criarFamilia),
                  ),
                  if (_criarFamilia)
                    _Campo(
                      controller: _nomeFamilia,
                      label: 'Nome da família',
                      hint: FamilyService.nomePadrao,
                      icon: Icons.home_outlined,
                      capitalize: true,
                    )
                  else
                    _Campo(
                      controller: _convite,
                      label: 'Código do convite',
                      hint: 'ex.: K7M2PQ',
                      icon: Icons.confirmation_number_outlined,
                      uppercase: true,
                      autocorrect: false,
                    ),
                ],
              ),
            ],

            if (_erro != null) ...[
              const SizedBox(height: Space.lg),
              Container(
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: p.energySoft,
                  borderRadius: BorderRadius.circular(Radii.group),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 18, color: p.danger),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: t.bodySmall?.copyWith(color: p.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: Space.xl),
            Pressable(
              onPressed: _carregando ? null : _enviar,
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: _carregando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: p.onAccent,
                      ),
                    )
                  : Text(
                      _criandoConta ? 'Criar minha conta' : 'Entrar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final auth = context.read<AuthService>();
    try {
      if (_criandoConta) {
        await auth.signUp(
          name: _nome.text,
          username: _usuario.text,
          password: _senha.text,
          role: _papel,
          avatarEmoji: _bicho,
          avatarColor: _cor,
          familyName: _criarFamilia ? _nomeFamilia.text : null,
          inviteCode: _criarFamilia ? null : _convite.text,
        );
      } else {
        await auth.signIn(username: _usuario.text, password: _senha.text);
      }
      // O AuthGate troca de tela sozinho quando a sessão muda.
    } on AppException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Algo deu errado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }
}

/// Campo de texto embutido na linha do grupo — sem caixa dentro de caixa.
class _Campo extends StatelessWidget {
  const _Campo({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.capitalize = false,
    this.uppercase = false,
    this.autocorrect = true,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final bool capitalize;
  final bool uppercase;
  final bool autocorrect;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.textSecondary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: t.bodySmall),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  autocorrect: autocorrect,
                  enableSuggestions: autocorrect,
                  textCapitalization: capitalize
                      ? TextCapitalization.words
                      : TextCapitalization.none,
                  inputFormatters:
                      uppercase ? [UpperCaseFormatter()] : const [],
                  style: t.labelLarge,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Space.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Deixa o código do convite em caixa alta enquanto se digita.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _Alternador extends StatelessWidget {
  const _Alternador({required this.criandoConta, required this.onChanged});

  final bool criandoConta;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.group),
      ),
      child: Row(
        children: [
          _Aba(
            texto: 'Entrar',
            ativo: !criandoConta,
            onTap: () => onChanged(false),
          ),
          _Aba(
            texto: 'Criar conta',
            ativo: criandoConta,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({required this.texto, required this.ativo, required this.onTap});

  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(
              color: ativo ? p.border : Colors.transparent,
            ),
          ),
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ativo ? p.textPrimary : p.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Icon(
      ativo ? Icons.check_circle_rounded : Icons.circle_outlined,
      size: 21,
      color: ativo ? p.accent : p.borderStrong,
    );
  }
}
