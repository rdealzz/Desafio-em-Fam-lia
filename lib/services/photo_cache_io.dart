import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Celular: grava a foto na pasta de documentos do app.
///
/// O cache do `image_picker` é temporário e o sistema apaga quando quer — sem
/// esta cópia, a foto sumiria entre registrar offline e sincronizar.
class PhotoCache {
  const PhotoCache();

  static const String _dirName = 'pending_photos';

  bool get isAvailable => true;

  Future<String?> save(Uint8List bytes) async {
    try {
      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$_dirName',
      );
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final name = '${DateTime.now().millisecondsSinceEpoch}_'
          '${Random().nextInt(9999)}.jpg';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> read(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Foto órfã ocupa pouco espaço; não vale falhar por isso.
    }
  }
}
