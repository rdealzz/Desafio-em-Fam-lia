import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/firebase_bootstrap.dart';
import 'demo/demo_app.dart';
import 'screens/setup/firebase_setup_screen.dart';

/// Vitrine com dados de mentira, sem Firebase nenhum. Ligado com
/// `--dart-define=DEMO_MODE=true` — é assim que a versão web é publicada.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datas e números em português para todo o app.
  await initializeDateFormatting('pt_BR', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (kDemoMode) {
    // Nem inicializa o Firebase: a demonstração não fala com servidor algum.
    runApp(const DemoApp());
    return;
  }

  // Sem chaves ou com o Firebase fora do ar, o app abre a tela de setup em vez
  // de morrer no arranque.
  final startup = await FirebaseBootstrap.initialize();

  runApp(
    startup.isReady
        ? const DesafioEmFamiliaApp()
        : FirebaseSetupApp(startup: startup),
  );
}
