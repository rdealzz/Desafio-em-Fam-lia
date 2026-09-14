/// Ponte com o contador de passos do celular (Apple Health / Google Fit).
///
/// MVP: a implementação real fica para depois — hoje a tela de registro aceita
/// os passos digitados. A interface já está pronta para trocar de implementação
/// sem tocar na UI nem no cálculo de pontos.
///
/// Para plugar de verdade:
/// 1. descomente `health: ^11.1.1` no `pubspec.yaml`;
/// 2. crie um `HealthKitStepsService implements StepsService` usando
///    `Health().getTotalStepsInInterval(início, fim)`;
/// 3. troque o registro em `lib/app.dart`;
/// 4. adicione as permissões nativas:
///    - Android: `android.permission.ACTIVITY_RECOGNITION` + Health Connect;
///    - iOS: `NSHealthShareUsageDescription` no `Info.plist` + capability
///      HealthKit.
abstract class StepsService {
  /// Se a plataforma tem contador de passos disponível e autorizado.
  Future<bool> isAvailable();

  /// Pede autorização ao usuário. Retorna se foi concedida.
  Future<bool> requestPermission();

  /// Passos do dia informado (padrão: hoje). `null` = indisponível.
  Future<int?> stepsForDay([DateTime? day]);
}

/// Implementação neutra usada enquanto não há integração nativa.
class ManualStepsService implements StepsService {
  const ManualStepsService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<int?> stepsForDay([DateTime? day]) async => null;
}
