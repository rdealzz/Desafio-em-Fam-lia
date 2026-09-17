import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../services/app_exception.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/avatar_bubble.dart';
import '../../widgets/ui/avatar_animals.dart';
import '../../widgets/ui/avatar_colors.dart';
import '../../widgets/ui/avatar_picker.dart';
import '../../widgets/ui/inset_group.dart';
import '../../widgets/ui/pressable.dart';

/// Editar o próprio perfil: foto, nome que aparece para os outros, cor e senha.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
    );
  }

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nome = TextEditingController();

  int? _cor;
  String? _bicho;
  String? _papel;
  bool _salvando = false;
  bool _enviandoFoto = false;
  bool _iniciado = false;

  static const Map<String, String> _papeis = {
    'mae': 'Mãe',
    'pai': 'Pai',
    'filho': 'Filho(a)',
    'membro': 'Outro',
  };

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Preenche uma vez, com o que está salvo; depois o estado local manda,
    // senão cada atualização do Firestore apagaria o que está sendo digitado.
    if (!_iniciado) {
      _iniciado = true;
      _nome.text = user.displayName;
      _cor = user.avatarColor;
      _bicho = user.avatarEmoji;
      _papel = user.role;
    }

    final corAtual = _cor ?? user.avatarColor;
    final bichoAtual =
        AvatarAnimals.resolver(_bicho ?? user.avatarEmoji, user.id);
    final temFoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.huge,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    AvatarBubble(user: user, size: 104, showRing: false),
                    if (_enviandoFoto)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.shadow,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _enviandoFoto ? null : _escolherFoto,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.bg, width: 3),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 15,
                            color: p.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Text(
                  temFoto
                      ? 'Toque na câmera para trocar a foto'
                      : 'Coloque uma foto sua, do seu bicho, do que quiser',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
                if (temFoto) ...[
                  const SizedBox(height: Space.xs),
                  GestureDetector(
                    onTap: _removerFoto,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'remover foto',
                      style: t.bodySmall?.copyWith(
                        color: p.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),

          InsetGroup(
            header: 'Como você aparece',
            footer: user.username.isEmpty
                ? null
                : 'O usuário "${user.username}" é o que você digita para '
                    'entrar e não muda.',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.md,
                  Space.lg,
                  Space.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nome que os outros veem', style: t.bodySmall),
                    TextField(
                      controller: _nome,
                      textCapitalization: TextCapitalization.words,
                      maxLength: ProfileService.maxNome,
                      style: t.labelLarge,
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
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
                  onChanged: (v) => setState(() => _papel = v),
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
                      temFoto
                          ? 'aparece se você tirar a foto'
                          : 'é assim que você aparece para a família',
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: Space.lg),
                    SeletorAnimal(
                      selecionado: bichoAtual,
                      cor: AvatarColors.resolver(corAtual, user.id),
                      onSelected: (b) => setState(() => _bicho = b),
                    ),
                    const SizedBox(height: Space.lg),
                    Text('Cor de fundo', style: t.labelLarge),
                    const SizedBox(height: Space.md),
                    SeletorCor(
                      selecionada: corAtual,
                      onSelected: (c) => setState(() => _cor = c),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),

          InsetGroup(
            header: 'Conta',
            footer: 'Sem e-mail cadastrado não existe recuperação: quem '
                'esquecer a senha precisa de conta nova. Vale cadastrar antes '
                'de precisar.',
            children: [
              InsetRow(
                icon: Icons.lock_outline_rounded,
                title: 'Trocar senha',
                subtitle: 'precisa saber a senha atual',
                onTap: () => _trocarSenha(context),
              ),
              Builder(builder: (context) {
                final email = context.read<AuthService>().emailDeRecuperacao;
                return InsetRow(
                  icon: email == null
                      ? Icons.mail_outline_rounded
                      : Icons.mark_email_read_outlined,
                  tint: email == null ? p.warning : null,
                  title: 'E-mail para recuperar a senha',
                  subtitle: email ?? 'nenhum — você não conseguirá recuperar',
                  onTap: () => _cadastrarEmail(context),
                );
              }),
            ],
          ),
          const SizedBox(height: Space.xxl),

          Pressable(
            onPressed: _salvando ? null : _salvar,
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: _salvando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: p.onAccent,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
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
              title: const Text('Tirar foto'),
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
    if (fonte == null || !mounted) return;

    // Tudo que vem do contexto é lido AGORA, antes de qualquer espera: depois
    // do await o widget pode nem existir mais.
    final servico = context.read<ProfileService>();
    final user = context.read<SessionController>().user;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) return;

    // Avatar é exibido pequeno: 600px já sobra, e o upload fica leve no dado
    // móvel da família.
    final escolhida = await _picker.pickImage(
      source: fonte,
      imageQuality: 75,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (escolhida == null) return;

    final Uint8List bytes = await escolhida.readAsBytes();
    if (!mounted) return;

    setState(() => _enviandoFoto = true);
    try {
      await servico.enviarFoto(userId: user.id, bytes: bytes);
      if (mounted) HapticFeedback.mediumImpact();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não consegui enviar a foto. Verifique a conexão — e se o Storage '
            'está ativado no Firebase.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _removerFoto() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;
    try {
      await context.read<ProfileService>().removerFoto(user.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não consegui remover agora.')),
      );
    }
  }

  Future<void> _salvar() async {
    final user = context.read<SessionController>().user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _salvando = true);

    try {
      await context.read<ProfileService>().salvar(
            userId: user.id,
            displayName: _nome.text,
            role: _papel,
            avatarEmoji: _bicho,
            avatarColor: _cor,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Perfil salvo')));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não consegui salvar agora.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _cadastrarEmail(BuildContext context) async {
    final campo = TextEditingController(
      text: context.read<AuthService>().emailDeRecuperacao ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthService>();

    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (folha) => Padding(
        padding: EdgeInsets.only(
          left: Space.gutter,
          right: Space.gutter,
          top: Space.xl,
          bottom: MediaQuery.of(folha).viewInsets.bottom + Space.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('E-mail para recuperar a senha',
                style: Theme.of(folha).textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            Text(
              'Serve só para isto: se você esquecer a senha, o link de '
              'redefinição chega nesse endereço. Você continua entrando pelo '
              'usuário, não pelo e-mail.',
              style: Theme.of(folha).textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: campo,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Seu e-mail',
                hintText: 'ex.: rafael@gmail.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: Space.lg),
            Pressable(
              onPressed: () => Navigator.of(folha).pop(campo.text.trim()),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text('Mandar confirmação'),
            ),
          ],
        ),
      ),
    );
    campo.dispose();
    if (email == null || email.isEmpty) return;

    try {
      await auth.cadastrarEmailDeRecuperacao(email);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Mandei um link de confirmação para $email. Abra e clique — até '
            'lá nada muda.',
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não consegui mandar agora.')),
      );
    }
  }

  Future<void> _trocarSenha(BuildContext context) async {
    final atual = TextEditingController();
    final nova = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: _TrocarSenha(atual: atual, nova: nova),
      ),
    );

    atual.dispose();
    nova.dispose();
  }
}

class _TrocarSenha extends StatefulWidget {
  const _TrocarSenha({required this.atual, required this.nova});

  final TextEditingController atual;
  final TextEditingController nova;

  @override
  State<_TrocarSenha> createState() => _TrocarSenhaState();
}

class _TrocarSenhaState extends State<_TrocarSenha> {
  bool _salvando = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Trocar senha', style: t.titleLarge),
          const SizedBox(height: Space.lg),
          TextField(
            controller: widget.atual,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha atual'),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: widget.nova,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha nova',
              hintText: 'pode ser simples',
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: Space.md),
            Text(_erro!, style: t.bodySmall?.copyWith(color: p.danger)),
          ],
          const SizedBox(height: Space.lg),
          Pressable(
            onPressed: _salvando ? null : _trocar,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Text(
              'Trocar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _trocar() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await context.read<AuthService>().alterarSenha(
            senhaAtual: widget.atual.text,
            novaSenha: widget.nova.text,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Senha trocada')));
    } on AppException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Não consegui trocar agora.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
