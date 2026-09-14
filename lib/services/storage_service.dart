import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload das fotos comprovante para o Firebase Storage.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Guarda em `families/{familyId}/proofs/{userId}/{timestamp}.jpg`.
  /// O caminho por família permite regra de segurança simples no Storage.
  Future<String> uploadActivityProof({
    required String familyId,
    required String userId,
    required File file,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('families/$familyId/proofs/$userId/$name');

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'familyId': familyId},
      ),
    );

    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    final ref = _storage.ref('avatars/$userId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
