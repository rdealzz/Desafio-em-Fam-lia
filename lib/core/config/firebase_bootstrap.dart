import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

enum FirebaseStartupStatus {
  /// Firebase conectado — pode subir o app.
  ready,

  /// `lib/firebase_options.dart` ainda está com os placeholders.
  notConfigured,

  /// As chaves existem mas a conexão falhou (projeto errado, serviço
  /// desativado, sem rede).
  failed,
}

class FirebaseStartup {
  const FirebaseStartup(this.status, {this.detail = ''});

  final FirebaseStartupStatus status;
  final String detail;

  bool get isReady => status == FirebaseStartupStatus.ready;
}

/// Liga o app ao Firebase — em produção ou contra o Emulator Suite.
///
/// Três caminhos possíveis:
///
/// 1. **Produção**: `flutterfire configure` preencheu `firebase_options.dart`
///    e o app conecta no projeto real.
/// 2. **Emulador**: `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`
///    aponta Auth, Firestore e Storage para o emulador local. Não precisa de
///    conta Firebase nenhuma — dá para testar o app inteiro offline.
/// 3. **Não configurado**: em vez de crashar com tela branca, o app mostra a
///    tela de setup com o passo a passo.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  /// Ligado com `--dart-define=USE_FIREBASE_EMULATOR=true`.
  static const bool useEmulators =
      bool.fromEnvironment('USE_FIREBASE_EMULATOR');

  /// Só é necessário em aparelho físico, para apontar ao IP do computador:
  /// `--dart-define=FIREBASE_EMULATOR_HOST=192.168.0.10`
  static const String _hostOverride =
      String.fromEnvironment('FIREBASE_EMULATOR_HOST');

  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;

  /// Projeto fictício do emulador. O prefixo `demo-` é reconhecido pelo
  /// Firebase CLI: nenhuma chamada escapa para a nuvem.
  static const String demoProjectId = 'demo-desafio-em-familia';

  static const FirebaseOptions _emulatorOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: demoProjectId,
    storageBucket: '$demoProjectId.appspot.com',
  );

  static String get emulatorHost {
    if (_hostOverride.isNotEmpty) return _hostOverride;
    // O emulador Android roda numa VM: 10.0.2.2 é o "localhost" do host.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  /// `false` enquanto `firebase_options.dart` tiver os placeholders `COLE_...`.
  static bool get hasRealCredentials {
    try {
      return !DefaultFirebaseOptions.currentPlatform.apiKey.startsWith('COLE_');
    } catch (_) {
      // Plataforma sem configuração gerada.
      return false;
    }
  }

  static Future<FirebaseStartup> initialize() async {
    if (!useEmulators && !hasRealCredentials) {
      return const FirebaseStartup(FirebaseStartupStatus.notConfigured);
    }

    try {
      await Firebase.initializeApp(
        options: useEmulators
            ? _emulatorOptions
            : DefaultFirebaseOptions.currentPlatform,
      );

      if (useEmulators) {
        await _connectEmulators();
      }

      return const FirebaseStartup(FirebaseStartupStatus.ready);
    } on FirebaseException catch (e) {
      return FirebaseStartup(
        FirebaseStartupStatus.failed,
        detail: e.message ?? e.code,
      );
    } catch (e) {
      return FirebaseStartup(FirebaseStartupStatus.failed, detail: '$e');
    }
  }

  /// Precisa rodar antes de qualquer leitura/escrita — por isso fica no boot.
  static Future<void> _connectEmulators() async {
    final host = emulatorHost;
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    await FirebaseStorage.instance.useStorageEmulator(host, storagePort);
  }
}
