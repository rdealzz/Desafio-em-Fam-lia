import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/activity_type.dart';
import '../models/app_user.dart';
import '../models/pending_activity.dart';
import 'activity_service.dart';
import 'app_exception.dart';
import 'pending_activity_store.dart';

/// Esvazia a fila de registros offline quando há internet.
///
/// O app tenta enviar na hora; só o que falhar por rede vira pendência. Assim
/// o caminho normal continua instantâneo (com a comemoração dos pontos e o
/// aviso de prêmio) e a fila é só o plano B.
///
/// Erros de regra de negócio — falta de foto, tempo insuficiente — NÃO entram
/// na fila: tentar de novo daria o mesmo erro para sempre.
class ActivitySyncService extends ChangeNotifier {
  ActivitySyncService(this._activityService, this._store);

  final ActivityService _activityService;
  final PendingActivityStore _store;

  List<PendingActivity> _pending = const [];
  bool _syncing = false;

  List<PendingActivity> get pending => _pending;
  int get pendingCount => _pending.length;
  bool get syncing => _syncing;
  bool get hasPending => _pending.isNotEmpty;

  /// Falso no navegador: sem sistema de arquivos não há onde guardar a foto,
  /// e sem a foto o registro seria recusado pelas regras.
  bool get isAvailable => _store.supportsOfflineQueue;

  Future<void> refresh() async {
    _pending = await _store.load();
    notifyListeners();
  }

  /// Guarda uma atividade para enviar quando der.
  ///
  /// A foto é copiada para a pasta do app antes de qualquer coisa: é o que
  /// garante que a prova ainda exista na hora de sincronizar.
  Future<PendingActivity> enqueue({
    required AppUser user,
    required ActivityType type,
    required int durationMinutes,
    int steps = 0,
    Uint8List? photoBytes,
    String note = '',
    DateTime? performedAt,
  }) async {
    final item = PendingActivity(
      id: PendingActivityStore.newId(),
      userId: user.id,
      familyId: user.familyId,
      typeId: type.id,
      durationMinutes: durationMinutes,
      steps: steps,
      note: note,
      photoPath: await _store.persistPhoto(photoBytes),
      performedAt: performedAt ?? DateTime.now(),
    );

    await _store.add(item);
    await refresh();
    return item;
  }

  /// Tenta enviar tudo que está parado. Silencioso de propósito: roda na
  /// abertura do app e ao voltar do segundo plano, sem incomodar ninguém.
  Future<int> drain(AppUser user) async {
    if (_syncing) return 0;

    _syncing = true;
    notifyListeners();

    var enviados = 0;
    try {
      for (final item in await _store.load()) {
        if (item.userId != user.id) continue;

        if (item.isExpired) {
          await _store.remove(item.id);
          continue;
        }

        Uint8List? photoBytes;
        final path = item.photoPath;
        if (path != null) {
          photoBytes = await _store.readPhoto(path);
          if (photoBytes == null) {
            // Foto sumiu do disco: sem a prova o registro seria recusado.
            await _store.remove(item.id);
            continue;
          }
        }

        try {
          await _activityService.registerActivity(
            user: user,
            type: item.type,
            durationMinutes: item.durationMinutes,
            steps: item.steps,
            photoBytes: photoBytes,
            note: item.note,
            source: 'offline_queue',
            performedAt: item.performedAt,
            logId: item.id,
          );
          await _store.remove(item.id);
          enviados++;
        } on AppException catch (e) {
          // Regra de negócio: insistir não resolve, então sai da fila.
          await _store.remove(item.id);
          debugPrint('Pendência ${item.id} descartada: ${e.message}');
        } catch (e) {
          // Provavelmente ainda sem rede — fica para a próxima tentativa.
          await _store.update(
            item.copyWith(attempts: item.attempts + 1, lastError: '$e'),
          );
        }
      }
    } finally {
      _syncing = false;
      await refresh();
    }

    return enviados;
  }
}
