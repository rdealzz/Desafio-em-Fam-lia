import 'dart:convert';
import 'dart:typed_data';

import 'app_exception.dart';

/// A foto comprovante, guardada dentro do próprio documento do Firestore.
///
/// O caminho normal seria o Firebase Storage, mas projeto novo só ganha
/// Storage no plano Blaze, que pede cartão. Guardar local resolveria o
/// armazenamento e perderia o sentido: quem precisa ver a foto é o resto da
/// família, não quem tirou. Então a foto vai para o Firestore como texto
/// base64, dentro do post — todo mundo vê, sem Storage e sem custo.
///
/// O preço disso é o tamanho: documento do Firestore para em 1 MiB. Por isso a
/// foto é capturada pequena já na câmera ([larguraMaxima], [qualidade]) e
/// recusada aqui se ainda assim passar do teto. Não é foto de álbum — é prova
/// de que a pessoa estava lá, e 400 px mostram isso de sobra.
class PhotoProof {
  const PhotoProof._();

  /// Pedidos à câmera/galeria. Nesta faixa uma foto fica em 20-50 KB.
  static const int larguraMaxima = 400;
  static const int qualidade = 40;

  /// Teto dos bytes crus. O base64 cresce 4/3, então 120 KB viram ~160 KB de
  /// texto — longe do limite de 1 MiB do documento, com folga para o resto.
  static const int bytesMaximos = 120 * 1024;

  /// Quanto tempo a foto fica no ar.
  ///
  /// Um dia é o combinado da família: tempo de todo mundo dar uma olhada e ver
  /// que a pessoa realmente foi. Depois some, e o registro e os pontos ficam.
  /// Some também porque foto é o dado mais pesado e mais pessoal aqui — não há
  /// motivo para acumular meses disso.
  static const Duration validade = Duration(hours: 24);

  /// Prepara os bytes para irem ao Firestore.
  static String codificar(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const AppException('A foto veio vazia. Tente tirar de novo.');
    }
    if (bytes.length > bytesMaximos) {
      throw AppException(
        'A foto ficou pesada demais (${(bytes.length / 1024).round()} KB). '
        'Tente tirar de novo — a câmera devolve menor.',
      );
    }
    return base64Encode(bytes);
  }

  /// Devolve os bytes, ou `null` se o texto estiver corrompido.
  ///
  /// Nunca lança: isto roda dentro da construção da lista do mural, e um
  /// registro com foto estragada não pode derrubar a tela inteira.
  static Uint8List? decodificar(String? dados) {
    if (dados == null || dados.isEmpty) return null;
    try {
      return base64Decode(dados);
    } catch (_) {
      return null;
    }
  }

  /// Quando esta foto deixa de valer, a partir de agora.
  static DateTime vencimento([DateTime? agora]) =>
      (agora ?? DateTime.now()).add(validade);

  static bool venceu(DateTime? vencimento) =>
      vencimento != null && DateTime.now().isAfter(vencimento);
}
