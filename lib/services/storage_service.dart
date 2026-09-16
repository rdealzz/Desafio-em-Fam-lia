import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'app_exception.dart';

/// Upload das fotos comprovante e dos avatares para o Firebase Storage.
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
  }) {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _enviar(
      caminho: 'families/$familyId/proofs/$userId/$name',
      bytes: bytes,
      metadados: {'userId': userId, 'familyId': familyId},
    );
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) {
    // Pasta por pessoa em vez de "avatars/{uid}.jpg": assim a regra do
    // Storage compara o uid direto, sem precisar recortar a extensão do nome
    // com expressão regular.
    return _enviar(caminho: 'avatars/$userId/perfil.jpg', bytes: bytes);
  }

  Future<String> _enviar({
    required String caminho,
    required Uint8List bytes,
    Map<String, String>? metadados,
  }) async {
    final ref = _storage.ref(caminho);
    try {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg', customMetadata: metadados),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw AppException(_traduzir(e));
    }
  }

  /// Transforma o erro do Firebase em frase que ajuda.
  ///
  /// O caso que mais aparece na prática não é bug nenhum: projeto novo do
  /// Firebase só ganha Storage no plano Blaze, então o balde simplesmente não
  /// existe. O erro cru ("[firebase_storage/unknown] An unknown error
  /// occurred") não diz isso, e quem lê acha que o app quebrou.
  String _traduzir(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return 'O Storage recusou o envio. Confira se as regras de '
            'storage.rules foram publicadas no console.';
      case 'object-not-found':
      case 'bucket-not-found':
      case 'project-not-found':
      case 'unknown':
        return 'Não consegui guardar a foto: o Storage não está disponível '
            'neste projeto Firebase. Dá para usar o app sem foto — desligue '
            'a exigência em Ajustes da família.';
      case 'retry-limit-exceeded':
      case 'canceled':
        return 'O envio da foto demorou demais. Tente de novo.';
      case 'quota-exceeded':
        return 'A cota do Storage acabou neste projeto.';
      default:
        return 'Não consegui enviar a foto (${e.code}).';
    }
  }
}
