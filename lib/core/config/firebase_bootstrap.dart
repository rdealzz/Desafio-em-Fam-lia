import 'dart:async';

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

  /// Teto para o arranque.
  ///
  /// No navegador, os plugins do Firebase carregam o SDK JavaScript do
  /// gstatic.com em tempo de execução. Se essa busca não voltar — rede
  /// caída, gstatic bloqueado por firewall ou por uma extensão —, o
  /// `initializeApp` fica pendurado e o app nunca sai da tela de carregando.
  /// Com o teto, ele desiste e mostra a tela de configuração dizendo o que
  /// houve, que é sempre melhor do que uma tela parada sem explicação.
  static const Duration tempoLimite = Duration(seconds: 15);

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
      ).timeout(tempoLimite);

      if (useEmulators) {
        await _connectEmulators().timeout(tempoLimite);
      }

      await _guardarDadosNoAparelho(); // tem prazo próprio

      return const FirebaseStartup(FirebaseStartupStatus.ready);
    } on TimeoutException {
      return FirebaseStartup(
        FirebaseStartupStatus.failed,
        detail: useEmulators
            ? 'Os emuladores não responderam em ${tempoLimite.inSeconds}s. '
                'Confira se ./scripts/run_emulators.sh está rodando.'
            : 'O Firebase não respondeu em ${tempoLimite.inSeconds}s. '
                'Quase sempre é a internet, ou algo bloqueando o '
                'gstatic.com, de onde o navegador baixa o SDK.',
      );
    } on FirebaseException catch (e) {
      return FirebaseStartup(
        FirebaseStartupStatus.failed,
        detail: e.message ?? e.code,
      );
    } catch (e) {
      return FirebaseStartup(FirebaseStartupStatus.failed, detail: '$e');
    }
  }

  /// Guarda uma cópia dos dados no aparelho (só no navegador).
  ///
  /// No celular o Firestore já guarda cópia em disco por padrão; no navegador
  /// o padrão é só memória, e cada abertura começava do zero: tela vazia até
  /// o servidor responder, e nada sem internet. Com a cópia no IndexedDB o
  /// app abre com o cofre, a turma e o mural da última visita, e atualiza
  /// quando a rede chega.
  ///
  /// `synchronizeTabs`: com duas abas abertas, as duas usam a mesma cópia.
  /// Sem isso a segunda aba falharia ao pedir o armazenamento.
  ///
  /// E a sessão de login? Não é tocada aqui de propósito. O SDK web já
  /// começa guardando no IndexedDB, com localStorage de reserva. A versão
  /// anterior chamava `setPersistence(LOCAL)` a cada abertura, e isso **perdia
  /// o login**: a troca apaga a sessão do IndexedDB antes de gravar no
  /// localStorage — se a gravação falhasse (navegador embutido, modo privado,
  /// armazenamento cheio) ou a aba fechasse no meio, a pessoa voltava
  /// deslogada. Na abertura seguinte o SDK ainda movia tudo de volta para o
  /// IndexedDB, repetindo o risco toda vez.
  static Future<void> _guardarDadosNoAparelho() async {
    if (!kIsWeb) return;
    try {
      // A troca sugerida (Settings.persistenceEnabled) liga o cache de uma
      // aba só no navegador; a sincronização entre abas só existe aqui.
      await FirebaseFirestore.instance
          // ignore: deprecated_member_use
          .enablePersistence(const PersistenceSettings(synchronizeTabs: true))
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Modo privado ou armazenamento bloqueado: segue só com memória, como
      // era antes. É conforto, nunca motivo para travar o arranque.
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
