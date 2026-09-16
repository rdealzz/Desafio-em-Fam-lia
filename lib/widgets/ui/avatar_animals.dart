import 'avatar_colors.dart';

/// Os bichos que servem de avatar.
///
/// São emoji de verdade, desenhados em cores, vindos da Noto Color Emoji
/// (licença OFL) empacotada em `assets/fonts/AnimalEmoji.ttf`. O arquivo tem
/// só estes 22 desenhos e pesa 44 KB — o original inteiro passa de 10 MB.
///
/// Empacotar era obrigatório: o CanvasKit do Flutter web não enxerga a fonte
/// de emoji do sistema, então no navegador todo emoji virava quadradinho. Com
/// a fonte junto do app, o bicho aparece igual no celular e no navegador.
class AvatarAnimals {
  const AvatarAnimals._();

  /// Família da fonte, declarada no `pubspec.yaml`.
  static const String fontFamily = 'AnimalEmoji';

  /// Ordem pensada para a grade: os mais pedidos primeiro.
  static const List<AnimalAvatar> opcoes = [
    AnimalAvatar('🦊', 'Raposa'),
    AnimalAvatar('🐻', 'Urso'),
    AnimalAvatar('🐼', 'Panda'),
    AnimalAvatar('🦁', 'Leão'),
    AnimalAvatar('🐯', 'Tigre'),
    AnimalAvatar('🐨', 'Coala'),
    AnimalAvatar('🐶', 'Cachorro'),
    AnimalAvatar('🐱', 'Gato'),
    AnimalAvatar('🐵', 'Macaco'),
    AnimalAvatar('🐷', 'Porco'),
    AnimalAvatar('🐮', 'Vaca'),
    AnimalAvatar('🐴', 'Cavalo'),
    AnimalAvatar('🐺', 'Lobo'),
    AnimalAvatar('🦄', 'Unicórnio'),
    AnimalAvatar('🐧', 'Pinguim'),
    AnimalAvatar('🦉', 'Coruja'),
    AnimalAvatar('🦅', 'Águia'),
    AnimalAvatar('🐸', 'Sapo'),
    AnimalAvatar('🐢', 'Tartaruga'),
    AnimalAvatar('🐬', 'Golfinho'),
    AnimalAvatar('🦈', 'Tubarão'),
    AnimalAvatar('🦋', 'Borboleta'),
  ];

  /// Só desenha o que existe na fonte empacotada. Cadastro antigo guardou
  /// '🙂' em `avatarEmoji`; esse rosto não está no arquivo e viraria
  /// quadradinho, então aqui ele é tratado como "não escolheu".
  static bool existe(String emoji) {
    for (final a in opcoes) {
      if (a.emoji == emoji) return true;
    }
    return false;
  }

  /// Bicho de quem ainda não escolheu, derivado do id e estável entre
  /// sessões. Deriva da mesma soma usada em [AvatarColors.paraId], mas com
  /// passo diferente: assim duas pessoas de mesma cor raramente caem no mesmo
  /// bicho, e ninguém abre o app com um avatar vazio.
  static AnimalAvatar paraId(String id) {
    if (id.isEmpty) return opcoes.first;
    final soma = id.codeUnits.fold<int>(0, (a, b) => a + b * 31);
    return opcoes[soma.abs() % opcoes.length];
  }

  /// O bicho a exibir: o escolhido, ou o sorteado pelo id.
  static String resolver(String salvo, String id) =>
      existe(salvo) ? salvo : paraId(id).emoji;
}

/// Um bicho e o nome dele em português — o nome vira rótulo de acessibilidade,
/// já que leitor de tela não sabe ler emoji de fonte empacotada.
class AnimalAvatar {
  const AnimalAvatar(this.emoji, this.nome);

  final String emoji;
  final String nome;
}
