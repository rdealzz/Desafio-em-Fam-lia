import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// `Notification` não existe em navegador antigo nem fora de HTTPS. A checagem
/// é pelo objeto global, e não por `window.Notification`, porque em iOS antigo
/// a propriedade existe e o construtor lança.
bool get avisosSuportados =>
    (web.window as JSObject).has('Notification');

/// 'granted', 'denied', 'default' — ou 'unsupported'.
String get avisosPermissao =>
    avisosSuportados ? web.Notification.permission : 'unsupported';

Future<String> pedirPermissaoDeAvisos() async {
  if (!avisosSuportados) return 'unsupported';
  final resposta = await web.Notification.requestPermission().toDart;
  return resposta.toDart;
}

void mostrarAviso({
  required String titulo,
  required String corpo,
  String? tag,
  String? icone,
}) {
  if (avisosPermissao != 'granted') return;
  final opcoes = web.NotificationOptions(body: corpo);
  // `tag` faz o aviso novo substituir o anterior do mesmo assunto em vez de
  // empilhar — quem abre o app depois de três registros quer ver um aviso,
  // não três.
  if (tag != null) opcoes.tag = tag;
  if (icone != null) opcoes.icon = icone;
  web.Notification(titulo, opcoes);
}
