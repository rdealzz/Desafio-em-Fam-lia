import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/firebase_bootstrap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// App mínimo mostrado quando o Firebase ainda não está ligado.
///
/// Melhor do que crashar com tela branca: diz exatamente o que falta e qual
/// comando resolve. É a primeira coisa que aparece num clone novo, então
/// carrega o tema de verdade — o app não pode dar as boas-vindas feio.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, required this.startup});

  final FirebaseStartup startup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desafio em Família — configuração',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FirebaseSetupScreen(startup: startup),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.startup});

  final FirebaseStartup startup;

  bool get _falhou => startup.status == FirebaseStartupStatus.failed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Sem isso, no monitor a linha de texto atravessa a tela inteira e
          // fica ilegível. 560 é o limite usual de largura de leitura.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.xxl,
                Space.lg,
                Space.huge,
              ),
              children: [
                // Ícone do Material, não emoji: o CanvasKit do Flutter web não
                // usa a fonte de emoji do sistema e desenharia quadradinho.
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _falhou ? p.energySoft : p.accentSoft,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(
                    _falhou
                        ? Icons.error_outline_rounded
                        : Icons.power_settings_new_rounded,
                    size: 30,
                    color: _falhou ? p.danger : p.accent,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Text(
                  _falhou ? 'O Firebase não respondeu' : 'Falta ligar o servidor',
                  style: t.headlineMedium,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  _falhou
                      ? 'As chaves existem, mas a conexão falhou. Confira se '
                          'Authentication, Firestore e Storage estão ativados '
                          'no console do projeto.'
                      : 'O app está pronto; falta dizer a ele em qual servidor '
                          'guardar os pontos e as fotos. São dois minutos, uma '
                          'vez só.',
                  style: t.bodyMedium?.copyWith(height: 1.45),
                ),

                if (_falhou && startup.detail.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: p.energySoft,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      startup.detail,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: p.danger,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: Space.xl),

                const _Passo(
                  numero: '1',
                  icone: Icons.content_paste_rounded,
                  titulo: 'Já criei o projeto no console',
                  corpo: 'No console, em Criar aplicativo → Web, aparece um '
                      'bloco "const firebaseConfig = { ... }". Copie ele '
                      'inteiro e cole no script — ele preenche as chaves '
                      'sozinho. Não precisa de Node nem de CLI.',
                  comando: './scripts/aplicar_chaves.py',
                ),
                const SizedBox(height: Space.lg),
                const _Passo(
                  numero: '2',
                  icone: Icons.rocket_launch_rounded,
                  titulo: 'Fazer tudo pelo terminal',
                  corpo: 'Abre o navegador para você entrar com a sua conta '
                      'Google, cria o projeto, gera as chaves de web, Android '
                      'e iOS, e publica as regras de segurança.',
                  comando: './scripts/setup_firebase.sh',
                ),
                const SizedBox(height: Space.lg),
                const _Passo(
                  numero: '3',
                  icone: Icons.science_outlined,
                  titulo: 'Ou só experimentar, sem criar conta',
                  corpo: 'O emulador roda tudo no seu computador: dá para usar '
                      'o app inteiro sem conta Firebase nenhuma. Os dados '
                      'somem quando você fecha. Em dois terminais:',
                  comando: './scripts/run_emulators.sh\n\n'
                      'flutter run --dart-define=USE_FIREBASE_EMULATOR=true',
                ),

                const SizedBox(height: Space.xl),
                Container(
                  padding: const EdgeInsets.all(Space.lg),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(Radii.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No console do Firebase, o projeto precisa ter '
                        'ativados:',
                        style: t.labelLarge?.copyWith(color: p.accent),
                      ),
                      const SizedBox(height: Space.sm),
                      for (final item in const [
                        'Authentication → método E-mail/senha',
                        'Cloud Firestore',
                        'Storage',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 16, color: p.accent),
                              const SizedBox(width: Space.sm),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: p.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: Space.lg),
                Text(
                  'Passo a passo e solução de problemas em '
                  'docs/firebase_setup.md',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({
    required this.numero,
    required this.icone,
    required this.titulo,
    required this.corpo,
    required this.comando,
  });

  final String numero;
  final IconData icone;
  final String titulo;
  final String corpo;
  final String comando;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  numero,
                  style: TextStyle(
                    color: p.onAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Icon(icone, size: 19, color: p.textSecondary),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(titulo, style: t.titleSmall)),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(corpo, style: t.bodySmall?.copyWith(height: 1.45)),
          const SizedBox(height: Space.md),
          _Comando(comando: comando),
        ],
      ),
    );
  }
}

/// O comando, em caixa preta, que copia ao toque.
class _Comando extends StatelessWidget {
  const _Comando({required this.comando});

  final String comando;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: comando));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Comando copiado')),
          );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          // Terminal é escuro nos dois temas: quem lê reconhece na hora que
          // aquilo é para colar no terminal, não para ler.
          color: const Color(0xFF14161C),
          borderRadius: BorderRadius.circular(Radii.group),
        ),
        child: Row(
          children: [
            Expanded(
              // Texto simples, não SelectableText: a seleção engoliria o
              // toque, e tocar na caixa é justamente o que copia.
              child: Text(
                comando,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['Courier New', 'monospace'],
                  fontSize: 12.5,
                  color: Color(0xFF9BE8B0),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            // A caixa é escura nos dois temas, então a cor do ícone é
            // fixa — p.onAccent inverteria junto com o tema e sumiria.
            const Icon(Icons.copy_rounded, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
