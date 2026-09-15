import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_activity.dart';

/// Guarda a fila de registros offline no disco do aparelho.
///
/// `SharedPreferences` para os dados (são poucos e pequenos) e a pasta de
/// documentos do app para as fotos — o cache do `image_picker` é temporário e
/// o sistema apaga quando quer.
class PendingActivityStore {
  PendingActivityStore();

  static const String _key = 'pending_activities_v1';
  static const String _photoDir = 'pending_photos';

  Future<List<PendingActivity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PendingActivity.decodeList(prefs.getString(_key));
  }

  Future<void> _save(List<PendingActivity> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PendingActivity.encodeList(items));
  }

  /// Copia a foto para um lugar permanente e devolve o novo caminho.
  ///
  /// Sem isso, a foto some entre o registro e a sincronização — e o registro
  /// chega sem a prova que o app exige.
  Future<String?> persistPhoto(File? photo) async {
    if (photo == null) return null;
    try {
      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/$_photoDir',
      );
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final name = '${DateTime.now().millisecondsSinceEpoch}_'
          '${Random().nextInt(9999)}.jpg';
      final copy = await photo.copy('${dir.path}/$name');
      return copy.path;
    } catch (_) {
      // Não conseguir copiar a foto não pode derrubar o registro; a
      // sincronização vai falhar na exigência de foto e avisar.
      return null;
    }
  }

  Future<void> add(PendingActivity item) async {
    final items = await load();
    await _save([...items, item]);
  }

  Future<void> update(PendingActivity item) async {
    final items = await load();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    items[index] = item;
    await _save(items);
  }

  /// Tira da fila e apaga a foto local — ela já está no Storage.
  Future<void> remove(String id) async {
    final items = await load();
    final removed = items.where((e) => e.id == id).toList();
    await _save(items.where((e) => e.id != id).toList());

    for (final item in removed) {
      final path = item.photoPath;
      if (path == null) continue;
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {
        // Foto órfã ocupa pouco espaço; não vale falhar por isso.
      }
    }
  }

  Future<void> clear() async {
    final items = await load();
    for (final item in items) {
      await remove(item.id);
    }
  }

  /// Gera o id que também será o id do documento em `activity_logs`.
  static String newId() {
    final random = Random();
    final suffix = List.generate(6, (_) => random.nextInt(36).toRadixString(36))
        .join();
    return 'pend_${DateTime.now().millisecondsSinceEpoch}_$suffix';
  }
}
