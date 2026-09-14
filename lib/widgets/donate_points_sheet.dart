import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/app_user.dart';
import '../services/activity_service.dart';
import '../services/app_exception.dart';
import '../services/points_calculator.dart';
import '../state/session_controller.dart';
import 'avatar_bubble.dart';

/// Bottom sheet da Carta "Salva-Mãe / Salva-Pai".
///
/// Quem treinou dobrado escolhe para quem manda os pontos; quem recebe leva
/// o DOBRO do que foi doado e mantém a sequência diária.
class DonatePointsSheet extends StatefulWidget {
  const DonatePointsSheet({super.key});

  /// Abre o sheet. Retorna `true` se a doação foi concluída.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DonatePointsSheet(),
    );
  }

  @override
  State<DonatePointsSheet> createState() => _DonatePointsSheetState();
}

class _DonatePointsSheetState extends State<DonatePointsSheet> {
  AppUser? _recipient;
  int _amount = 50;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final me = session.user;
    final others = session.otherMembers;

    if (me == null) return const SizedBox.shrink();

    final available = me.pointsThisWeek;
    // Nunca deixar o botão oferecer mais do que a pessoa tem na semana.
    final amount = _amount > available ? available : _amount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E0EE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Text('🦸', style: TextStyle(fontSize: 26)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Carta Salva-Mãe / Salva-Pai',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Você treinou em dobro? Doe pontos para salvar a sequência de '
                'alguém. Quem recebe leva o DOBRO do que você doar.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.style_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cartas disponíveis: ${me.saveCards}  •  '
                        'Seus pontos da semana: ${Formatters.points(available)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Para quem?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              if (others.isEmpty)
                const Text(
                  'Ninguém mais entrou na família ainda.',
                  style: TextStyle(color: AppColors.inkSoft),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: others.map((member) {
                    final selected = _recipient?.id == member.id;
                    return GestureDetector(
                      onTap: () => setState(() => _recipient = member),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.10)
                              : const Color(0xFFF6F5FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarBubble(
                              user: member,
                              size: 36,
                              showRing: false,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              member.firstName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Quantos pontos doar?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '${Formatters.points(amount)} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: amount.toDouble(),
                min: 0,
                max: available <= 0 ? 1 : available.toDouble(),
                divisions: available >= 10 ? (available ~/ 10) : null,
                label: '$amount pts',
                onChanged: available <= 0
                    ? null
                    : (value) => setState(() => _amount = value.round()),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_recipient?.firstName ?? 'Quem receber'} vai ganhar '
                  '${Formatters.points(PointsCalculator.donationValue(amount))} pts '
                  '(o dobro) e manter a sequência do dia.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B7F4C),
                    height: 1.35,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving || _recipient == null || amount <= 0
                    ? null
                    : () => _submit(amount),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Usar a carta 🦸'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(int amount) async {
    final session = context.read<SessionController>();
    final service = context.read<ActivityService>();
    // Guardado antes do pop: depois de fechar o sheet este context não serve
    // mais para achar o ScaffoldMessenger.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final me = session.user;
    final recipient = _recipient;

    if (me == null || recipient == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final received = await service.donatePoints(
        donor: me,
        recipientId: recipient.id,
        amount: amount,
      );

      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '🦸 ${recipient.firstName} recebeu ${Formatters.points(received)} pts!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível doar agora. Tente de novo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
