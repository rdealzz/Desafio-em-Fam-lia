import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_exception.dart';
import 'firestore_refs.dart';
import 'storage_service.dart';

/// Edição do próprio perfil: nome que aparece para os outros, foto e cor.
class ProfileService {
  ProfileService(this._refs, this._storage);

  final FirestoreRefs _refs;
  final StorageService _storage;

  static const int maxNome = 24;

  /// Salva as mudanças do perfil. Só manda ao Firestore o que mudou.
  Future<void> salvar({
    required String userId,
    String? displayName,
    String? role,
    int? avatarColor,
  }) async {
    final dados = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      final nome = displayName.trim();
      if (nome.length < 2) {
        throw const AppException('O nome precisa de pelo menos 2 letras.');
      }
      if (nome.length > maxNome) {
        throw const AppException('O nome ficou comprido demais.');
      }
      dados['displayName'] = nome;
    }
    if (role != null) dados['role'] = role;
    if (avatarColor != null) dados['avatarColor'] = avatarColor;

    await _refs.user(userId).update(dados);
  }

  /// Envia a foto de perfil e devolve o endereço dela.
  ///
  /// Grava em `avatars/{userId}.jpg` — sempre o mesmo caminho, então trocar
  /// a foto substitui a anterior em vez de acumular arquivo órfão.
  Future<String> enviarFoto({
    required String userId,
    required Uint8List bytes,
  }) async {
    final url = await _storage.uploadAvatar(userId: userId, bytes: bytes);
    await _refs.user(userId).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  /// Volta para a inicial colorida.
  Future<void> removerFoto(String userId) {
    return _refs.user(userId).update({
      'photoUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
