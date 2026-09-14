// ATENÇÃO: arquivo de exemplo.
//
// Gere o seu com a CLI oficial — ela sobrescreve este arquivo com as chaves
// reais do seu projeto Firebase:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=SEU_PROJETO_FIREBASE
//
// Enquanto os valores abaixo forem os placeholders, o app não conecta.
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
    apiKey: 'COLE_SUA_API_KEY_WEB',
    appId: 'COLE_SEU_APP_ID_WEB',
    messagingSenderId: 'COLE_SEU_SENDER_ID',
    projectId: 'COLE_SEU_PROJECT_ID',
    storageBucket: 'COLE_SEU_PROJECT_ID.appspot.com',
    authDomain: 'COLE_SEU_PROJECT_ID.firebaseapp.com',
  );
}
