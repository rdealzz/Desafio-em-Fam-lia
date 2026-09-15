import 'dart:typed_data';

/// Navegador: não há sistema de arquivos para guardar a foto entre sessões.
///
/// Sem onde guardar a prova, a fila offline não funciona na web — e tudo bem:
/// quem abre o app pelo navegador já está online. O `isAvailable` deixa a
/// interface avisar em vez de falhar em silêncio.
class PhotoCache {
  const PhotoCache();

  bool get isAvailable => false;

  Future<String?> save(Uint8List bytes) async => null;

  Future<Uint8List?> read(String path) async => null;

  Future<void> delete(String path) async {}
}
