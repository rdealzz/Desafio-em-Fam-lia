/// Fora do navegador não há API de Notification; o lugar disto no celular
/// seria o FCM. Tudo responde "não dá", e a interface esconde a opção.
bool get avisosSuportados => false;

String get avisosPermissao => 'unsupported';

Future<String> pedirPermissaoDeAvisos() async => 'unsupported';

void mostrarAviso({
  required String titulo,
  required String corpo,
  String? tag,
  String? icone,
}) {}
