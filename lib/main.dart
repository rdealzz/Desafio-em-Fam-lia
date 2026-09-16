import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/firebase_bootstrap.dart';
import 'screens/setup/firebase_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datas e números em português para todo o app.
  await initializeDateFormatting('pt_BR', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Sem chaves ou com o Firebase fora do ar, o app abre a tela de setup em vez
  // de morrer no arranque.
  final startup = await FirebaseBootstrap.initialize();

  runApp(
    startup.isReady
        ? const DesafioEmFamiliaApp()
        : FirebaseSetupApp(startup: startup),
  );
}
