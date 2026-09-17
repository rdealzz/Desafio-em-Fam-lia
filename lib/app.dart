import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'core/theme/tokens.dart';
import 'core/utils/firestore_erros.dart';
import 'core/theme/theme_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/join_family_screen.dart';
import 'screens/shell/home_shell.dart';
import 'widgets/ui/pressable.dart';
import 'services/activity_service.dart';
import 'services/activity_sync_service.dart';
import 'services/auth_service.dart';
import 'services/family_service.dart';
import 'services/feed_service.dart';
import 'services/firestore_refs.dart';
import 'services/health_service.dart';
import 'services/pending_activity_store.dart';
import 'services/photo_cleanup_service.dart';
import 'services/profile_service.dart';
import 'services/storage_service.dart';
import 'state/avisos_controller.dart';
import 'state/session_controller.dart';

/// Raiz do app. Monta a injeção de dependências uma única vez.
///
/// Serviços são objetos simples sem estado próprio — por isso `Provider`
/// puro; só o [SessionController] notifica mudanças.
class DesafioEmFamiliaApp extends StatelessWidget {
  const DesafioEmFamiliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        Provider<FirestoreRefs>(
          create: (_) => FirestoreRefs(FirebaseFirestore.instance),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(FirebaseStorage.instance),
        ),
        // Troque por uma implementação HealthKit/Google Fit quando integrar
        // o contador de passos (ver lib/services/health_service.dart).
        Provider<StepsService>(create: (_) => const ManualStepsService()),
        ProxyProvider<FirestoreRefs, FamilyService>(
          update: (_, refs, __) => FamilyService(refs),
        ),
        ProxyProvider<FirestoreRefs, FeedService>(
          update: (_, refs, __) => FeedService(refs),
        ),
        // Sem StorageService: a foto comprovante vai dentro do documento do
        // Firestore (ver PhotoProof). O Storage ficou só para o avatar.
        ProxyProvider<FirestoreRefs, ActivityService>(
          update: (_, refs, __) => ActivityService(refs),
        ),
        ProxyProvider<FirestoreRefs, PhotoCleanupService>(
          update: (_, refs, __) => PhotoCleanupService(refs),
        ),
        Provider<PendingActivityStore>(create: (_) => PendingActivityStore()),
        ChangeNotifierProxyProvider2<ActivityService, PendingActivityStore,
            ActivitySyncService>(
          create: (context) => ActivitySyncService(
            context.read<ActivityService>(),
            context.read<PendingActivityStore>(),
          ),
          update: (_, __, ___, previous) => previous!,
        ),
        ProxyProvider2<FirestoreRefs, StorageService, ProfileService>(
          update: (_, refs, storage, __) => ProfileService(refs, storage),
        ),
        ProxyProvider2<FirestoreRefs, FamilyService, AuthService>(
          update: (_, refs, familyService, __) =>
              AuthService(FirebaseAuth.instance, refs, familyService),
        ),
        ChangeNotifierProxyProvider<FeedService, AvisosController>(
          create: (context) =>
              AvisosController(context.read<FeedService>())..carregar(),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider2<AuthService, FamilyService,
            SessionController>(
          create: (context) => SessionController(
            authService: context.read<AuthService>(),
            familyService: context.read<FamilyService>(),
          ),
          update: (_, __, ___, previous) => previous!,
        ),
      ],
      // `Consumer` em volta só do MaterialApp: trocar de tema reconstrói o
      // app, mas não refaz os provedores de serviço acima.
      child: Consumer<ThemeController>(
        builder: (context, tema, _) => MaterialApp(
          title: 'Desafio em Família',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: tema.mode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Decide qual tela mostrar conforme o estado da sessão.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    // Aqui porque é o único lugar que reconstrói a cada mudança de sessão —
    // login, troca de família, logout. Fora do build para não tocar em outro
    // provider no meio da construção do quadro.
    final familyId = session.family?.id;
    final meuId = session.user?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context
          .read<AvisosController>()
          .observar(familyId: familyId, meuId: meuId);
    });

    switch (session.status) {
      case SessionStatus.loading:
        return const _SplashScreen();
      case SessionStatus.signedOut:
        return const LoginScreen();
      case SessionStatus.needsFamily:
        return const JoinFamilyScreen();
      case SessionStatus.ready:
        return const HomeShell();
      case SessionStatus.falhou:
        return const _FalhaAoCarregar();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Logado, mas os dados não vieram.
///
/// Antes isto era a bolinha girando para sempre — o app parecia travado e não
/// dizia nada. A causa quase sempre é regra do Firestore desatualizada ou rede
/// fora, e as duas têm saída: tentar de novo, ou sair e entrar.
class _FalhaAoCarregar extends StatelessWidget {
  const _FalhaAoCarregar();

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    final p = context.palette;
    final t = Theme.of(context).textTheme;
    final erro = FirestoreErros.traduzir(session.erro);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 32, color: p.textMuted),
                const SizedBox(height: Space.lg),
                Text(erro.titulo, style: t.titleMedium),
                const SizedBox(height: Space.xs),
                Text(
                  erro.texto,
                  textAlign: TextAlign.center,
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.xl),
                Pressable(
                  onPressed: session.recarregar,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xxl,
                    vertical: 15,
                  ),
                  child: const Text('Tentar de novo'),
                ),
                const SizedBox(height: Space.md),
                TextButton(
                  onPressed: session.signOut,
                  child: const Text('Sair da conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
