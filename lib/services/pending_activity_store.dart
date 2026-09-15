import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_activity.dart';
import 'photo_cache.dart';

/// Guarda a fila de registros offline no disco do aparelho.
///
/// `SharedPreferences` para os dados (são poucos e pequenos) e a pasta de
/// documentos do app para as fotos — o cache do `image_picker` é temporário e
/// o sistema apaga quando quer.
class PendingActivityStore {
  PendingActivityStore({PhotoCache photoCache = const PhotoCache()})
      : _photoCache = photoCache;

  final PhotoCache _photoCache;

  static const String _key = 'pending_activities_v1';

  /// Se dá para guardar a foto entre sessões. Falso no navegador — e sem isso
  /// a fila offline não tem como existir, porque o registro exige a prova.
  bool get supportsOfflineQueue => _photoCache.isAvailable;

  Future<List<PendingActivity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PendingActivity.decodeList(prefs.getString(_key));
  }

  Future<void> _save(List<PendingActivity> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PendingActivity.encodeList(items));
  }

  /// Guarda a foto num lugar permanente e devolve o caminho.
  ///
  /// Sem isso, a foto some entre o registro e a sincronização — e o registro
  /// chega sem a prova que o app exige.
  Future<String?> persistPhoto(Uint8List? bytes) async {
    if (bytes == null) return null;
    return _photoCache.save(bytes);
  }

  /// Lê de volta a foto guardada, para enviar ao Storage.
  Future<Uint8List?> readPhoto(String path) => _photoCache.read(path);

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
      if (path != null) await _photoCache.delete(path);
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
