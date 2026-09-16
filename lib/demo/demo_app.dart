import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../services/activity_service.dart';
import '../services/activity_sync_service.dart';
import '../services/feed_service.dart';
import '../services/health_service.dart';
import '../services/pending_activity_store.dart';
import '../services/profile_service.dart';
import '../state/session_controller.dart';
import '../screens/shell/home_shell.dart';
import 'demo_backend.dart';

/// Vitrine do app: mesmas telas, dados de mentira, nenhum servidor.
///
/// É o que a versão publicada na web mostra. A faixa "DEMO" no canto existe
/// para ninguém confundir com o app de verdade da família.
class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  // Criados uma vez só. Instanciar dentro do build() devolveria objetos novos
  // a cada reconstrução, e a sessão perderia o estado a cada toque na tela.
  late final DemoBackend _backend = DemoBackend();
  late final DemoSessionController _session = DemoSessionController(_backend);
  late final DemoActivityService _activityService =
      DemoActivityService(_backend);
  late final DemoFeedService _feedService = DemoFeedService(_backend);
  late final DemoProfileService _profileService = DemoProfileService(_backend);
  late final ActivitySyncService _syncService = ActivitySyncService(
    _activityService,
    PendingActivityStore(),
  );
  late final ThemeController _tema = ThemeController();

  @override
  void dispose() {
    // `.value` não descarta por conta própria — o dono é este State.
    _tema.dispose();
    _syncService.dispose();
    _session.dispose();
    _backend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: _session),
        Provider<ActivityService>.value(value: _activityService),
        Provider<FeedService>.value(value: _feedService),
        Provider<ProfileService>.value(value: _profileService),
        Provider<StepsService>(create: (_) => const ManualStepsService()),
        ChangeNotifierProvider<ActivitySyncService>.value(value: _syncService),
        ChangeNotifierProvider<ThemeController>.value(value: _tema),
      ],
      child: Consumer<ThemeController>(
        builder: (context, tema, _) => MaterialApp(
          title: 'Desafio em Família — demonstração',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: tema.mode,
          home: const Banner(
            message: 'DEMO',
            location: BannerLocation.topEnd,
            color: Color(0xFF2E90FA),
            child: HomeShell(),
          ),
        ),
      ),
    );
  }
}
