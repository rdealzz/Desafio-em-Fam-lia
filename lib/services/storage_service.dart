import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload das fotos comprovante para o Firebase Storage.
class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  /// Guarda em `families/{familyId}/proofs/{userId}/{timestamp}.jpg`.
  /// O caminho por família permite regra de segurança simples no Storage.
  /// Recebe bytes, não arquivo: `putData` funciona no celular e no navegador,
  /// enquanto `putFile` depende de `dart:io` e quebraria a build web.
  Future<String> uploadActivityProof({
    required String familyId,
    required String userId,
    required Uint8List bytes,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('families/$familyId/proofs/$userId/$name');

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'familyId': familyId},
      ),
    );

    return ref.getDownloadURL();
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) async {
    // Pasta por pessoa em vez de "avatars/{uid}.jpg": assim a regra do
    // Storage compara o uid direto, sem precisar recortar a extensão do nome
    // com expressão regular.
    final ref = _storage.ref('avatars/$userId/perfil.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
