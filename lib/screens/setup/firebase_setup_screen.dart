import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/firebase_bootstrap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';

/// App mínimo mostrado quando o Firebase ainda não está ligado.
///
/// Melhor do que crashar com tela branca: diz exatamente o que falta e qual
/// comando resolve.
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

  bool get _isFailure => startup.status == FirebaseStartupStatus.failed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Text(
              _isFailure ? '⚠️' : '🔌',
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 12),
            Text(
              _isFailure
                  ? 'Firebase não respondeu'
                  : 'Falta ligar o Firebase',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isFailure
                  ? 'As chaves existem, mas a conexão falhou. Confira se '
                      'Authentication, Firestore e Storage estão ativados no '
                      'console do projeto.'
                  : 'O arquivo lib/firebase_options.dart ainda está com os '
                      'valores de exemplo. Escolha um dos caminhos abaixo.',
              style: TextStyle(color: context.palette.textSecondary, height: 1.45),
            ),

            if (_isFailure && startup.detail.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  startup.detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.palette.danger,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            const _SetupStep(
              number: '1',
              emoji: '🧪',
              title: 'Só quero ver o app rodando agora',
              body: 'Roda contra o emulador local — não precisa de conta '
                  'Firebase nenhuma. Em dois terminais:',
              command: './scripts/run_emulators.sh\n\n'
                  'flutter run --dart-define=USE_FIREBASE_EMULATOR=true',
            ),
            const SizedBox(height: 16),
            const _SetupStep(
              number: '2',
              emoji: '🚀',
              title: 'Ligar no meu projeto Firebase de verdade',
              body: 'O script cria as pastas nativas, conecta o projeto e '
                  'publica as regras:',
              command: './scripts/setup_firebase.sh',
            ),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No console do Firebase, o projeto precisa ter ativados:\n'
                '• Authentication → método E-mail/senha\n'
                '• Cloud Firestore\n'
                '• Storage',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: context.palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Detalhes em docs/firebase_setup.md',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.emoji,
    required this.title,
    required this.body,
    required this.command,
  });

  final String number;
  final String emoji;
  final String title;
  final String body;
  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: const Color(0xFFEFEDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.palette.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comando copiado')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.palette.textPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      command,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: Color(0xFF9BE8B0),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_rounded,
                      size: 16, color: Colors.white54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
