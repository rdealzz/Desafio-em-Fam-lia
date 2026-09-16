// Gerado a partir das chaves do console do Firebase.
//
// Chave de cliente do Firebase é pública por natureza: quem protege os
// dados são as regras em firestore.rules e storage.rules, não o segredo
// destes valores. Por isso o arquivo fica versionado.
//
// Para regerar: ./scripts/aplicar_chaves.py (ou flutterfire configure).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plataforma sem configuração. Rode `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'COLE_SUA_API_KEY_ANDROID',
    appId: 'COLE_SEU_APP_ID_ANDROID',
    messagingSenderId: 'COLE_SEU_SENDER_ID',
    projectId: 'COLE_SEU_PROJECT_ID',
    storageBucket: 'COLE_SEU_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'COLE_SUA_API_KEY_IOS',
    appId: 'COLE_SEU_APP_ID_IOS',
    messagingSenderId: 'COLE_SEU_SENDER_ID',
    projectId: 'COLE_SEU_PROJECT_ID',
    storageBucket: 'COLE_SEU_PROJECT_ID.appspot.com',
    iosBundleId: 'com.exemplo.desafioEmFamilia',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAH-DRxqBxkRLLfkx_pZcYXqKK9N8spGjk',
    appId: '1:20486915287:web:48cbd9df390ef281ac9c92',
    messagingSenderId: '20486915287',
    projectId: 'familia-3d96f',
    authDomain: 'familia-3d96f.firebaseapp.com',
    storageBucket: 'familia-3d96f.firebasestorage.app',
    measurementId: 'G-ZYVB1BWXQ2',
  );
}
