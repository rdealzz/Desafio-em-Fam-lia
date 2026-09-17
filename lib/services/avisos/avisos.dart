/// @docImport 'avisos_web.dart';
library;

/// Avisos do navegador ("Rafael treinou · +150 pts").
///
/// Duas implementações atrás de uma mesma porta: no navegador usa a API de
/// Notification, no celular nativo não faz nada — lá o caminho certo seria o
/// FCM, que precisa de um servidor para disparar, e servidor aqui significa
/// Cloud Function, que significa plano pago.
///
/// **O que isto alcança, dito de frente:** o aviso aparece enquanto o app
/// estiver aberto, mesmo em outra aba ou com o celular na tela inicial e o app
/// instalado. Não alcança o celular com o app fechado de vez — isso é push de
/// verdade, e push de verdade precisa de servidor.
export 'avisos_stub.dart' if (dart.library.js_interop) 'avisos_web.dart';
