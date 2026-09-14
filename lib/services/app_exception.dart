/// Erro de negócio com mensagem já pronta para mostrar ao usuário.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
