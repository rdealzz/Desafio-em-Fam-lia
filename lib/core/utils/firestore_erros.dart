import 'package:cloud_firestore/cloud_firestore.dart';

/// Erro de consulta do Firestore, já traduzido para quem está olhando a tela.
class ErroDeConsulta {
  const ErroDeConsulta({required this.titulo, required this.texto, this.link});

  final String titulo;
  final String texto;

  /// Endereço para resolver, quando existe um. O Firestore devolve um link
  /// pronto no caso do índice faltando.
  final String? link;
}

/// Transforma o erro cru do Firestore em algo acionável.
///
/// Todo erro de consulta caía num "verifique a conexão", o que manda a pessoa
/// procurar no lugar errado: a falha mais provável num projeto recém-criado
/// não é a rede, é índice que ainda não existe.
class FirestoreErros {
  const FirestoreErros._();

  static ErroDeConsulta traduzir(Object? erro) {
    if (erro is FirebaseException) {
      switch (erro.code) {
        case 'failed-precondition':
          return ErroDeConsulta(
            titulo: 'Falta um índice no Firestore',
            texto: 'Listas ordenadas por data precisam de um índice, criado '
                'uma vez por projeto. O Firebase já preparou o link: abra, '
                'clique em "Criar índice" e espere uns minutos.',
            link: _extrairLink(erro.message),
          );
        case 'permission-denied':
          return const ErroDeConsulta(
            titulo: 'Sem permissão',
            texto: 'O Firestore recusou a leitura. Confira se as regras de '
                'firestore.rules foram publicadas no console.',
          );
        case 'unavailable':
        case 'deadline-exceeded':
          return const ErroDeConsulta(
            titulo: 'Não consegui carregar',
            texto: 'Verifique a conexão e tente de novo.',
          );
        case 'unauthenticated':
          return const ErroDeConsulta(
            titulo: 'Sessão expirada',
            texto: 'Saia e entre de novo.',
          );
      }
    }
    return const ErroDeConsulta(
      titulo: 'Não consegui carregar',
      texto: 'Verifique a conexão e tente de novo.',
    );
  }

  /// O Firestore embute o endereço de criação do índice no meio da mensagem.
  /// Vale pescar: é um clique que resolve, contra uma caçada no console.
  static String? _extrairLink(String? mensagem) {
    if (mensagem == null) return null;
    final achado = RegExp(r'https://\S+').firstMatch(mensagem);
    // A mensagem costuma terminar em ponto final, que não faz parte do link.
    return achado?.group(0)?.replaceAll(RegExp(r'[.,)]+$'), '');
  }
}
