/// Guarda temporária de fotos da fila offline.
///
/// A implementação muda por plataforma: no celular grava arquivo na pasta do
/// app; no navegador não existe sistema de arquivos, então vira no-op e a fila
/// offline fica indisponível lá (a web já depende de estar online mesmo).
///
/// O `export` condicional é o que permite o mesmo código compilar nos dois
/// lados: `dart:io` sequer é importado quando o alvo é a web.
library;

export 'photo_cache_web.dart' if (dart.library.io) 'photo_cache_io.dart';
