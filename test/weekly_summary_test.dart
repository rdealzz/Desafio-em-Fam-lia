import 'package:desafio_em_familia/core/utils/week_utils.dart';
import 'package:desafio_em_familia/models/app_user.dart';
import 'package:desafio_em_familia/models/family.dart';
import 'package:desafio_em_familia/models/reward.dart';
import 'package:desafio_em_familia/services/weekly_pace.dart';
import 'package:desafio_em_familia/services/weekly_standings.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser membro(String nome, int pontos, {int sequencia = 0}) => AppUser(
      id: nome,
      familyId: 'f',
      displayName: nome,
      weeklyPoints: pontos,
      weekId: WeekUtils.currentWeekId(),
      currentStreak: sequencia,
    );

Family familia({required String weekId, int cofre = 4000}) => Family(
      id: 'f',
      name: 'Silva',
      inviteCode: 'X',
      memberIds: const ['a', 'b', 'c', 'd'],
      weeklyGoal: 5000,
      vaultPoints: cofre,
      weekId: weekId,
      rewards: [
        Reward(
            id: 'pizza',
            title: 'Pizza',
            requiredPoints: 3000,
            unlocked: true,
            unlockedAt: DateTime(2020)),
        const Reward(id: 'acai', title: 'Açaí', requiredPoints: 5000),
      ],
    );

void main() {
  group('Family na virada da semana', () {
    test('cofre da semana passada não conta na semana nova', () {
      final f = familia(weekId: '2000-W01');
      expect(f.vaultThisWeek, 0);
      expect(f.progress, 0);
      expect(f.goalReached, isFalse);
      expect(f.unlockedRewards, isEmpty);
      expect(f.nextReward?.id, 'pizza');
      expect(f.rewardsThisWeek.first.unlockedAt, isNull);
    });

    test('na semana corrente, vale o que está gravado', () {
      final f = familia(weekId: WeekUtils.currentWeekId());
      expect(f.vaultThisWeek, 4000);
      expect(f.unlockedRewards.map((r) => r.id), ['pizza']);
      expect(f.pointsRemaining, 1000);
    });

    test('prêmio já ultrapassado não é o próximo', () {
      final f = Family(
        id: 'f',
        name: 'Silva',
        inviteCode: 'X',
        vaultPoints: 3500,
        weekId: WeekUtils.currentWeekId(),
        rewards: Reward.defaults(5000),
      );
      expect(f.nextReward?.id, 'board_games');
    });
  });

  group('WeekUtils.daysLeftInWeek', () {
    test('segunda tem 7 dias, domingo tem 1', () {
      expect(WeekUtils.daysLeftInWeek(DateTime(2026, 9, 14)), 7);
      expect(WeekUtils.daysLeftInWeek(DateTime(2026, 9, 17)), 4);
      expect(WeekUtils.daysLeftInWeek(DateTime(2026, 9, 20, 23)), 1);
    });
  });

  group('WeeklyPace', () {
    test('divide o que falta pelos dias e pela turma, para cima', () {
      const pace = WeeklyPace(daysLeft: 3, pointsRemaining: 1000, members: 4);
      expect(pace.perDay, 334);
      expect(pace.perPersonPerDay, 84);
      expect(pace.done, isFalse);
    });

    test('meta batida não pede nada', () {
      const pace = WeeklyPace(daysLeft: 3, pointsRemaining: 0, members: 4);
      expect(pace.done, isTrue);
      expect(pace.perDay, 0);
      expect(pace.perPersonPerDay, 0);
    });

    test('domingo é o último dia', () {
      const pace = WeeklyPace(daysLeft: 1, pointsRemaining: 500, members: 1);
      expect(pace.lastDay, isTrue);
      expect(pace.perDay, 500);
      expect(pace.perPersonPerDay, 500);
    });
  });

  group('WeeklyStandings', () {
    test('ordena por pontos e marca a lanterna', () {
      final s = WeeklyStandings.from([
        membro('Ana', 300),
        membro('Bia', 900),
        membro('Caio', 100),
      ]);
      expect(s.rows.map((r) => r.member.id), ['Bia', 'Ana', 'Caio']);
      expect(s.rows.map((r) => r.position), [1, 2, 3]);
      expect(s.lantern.map((r) => r.member.id), ['Caio']);
      expect(s.totalPoints, 1300);
      expect(s.rows.first.share, closeTo(900 / 1300, 1e-9));
    });

    test('empate divide a posição e a lanterna', () {
      final s = WeeklyStandings.from([
        membro('Ana', 500),
        membro('Bia', 500),
        membro('Caio', 0),
        membro('Duda', 0),
      ]);
      expect(s.rows.map((r) => r.position), [1, 1, 3, 3]);
      expect(s.lantern.map((r) => r.member.id), ['Caio', 'Duda']);
      expect(s.podium.map((r) => r.member.id), ['Ana', 'Bia']);
    });

    test('todo mundo empatado: ninguém na lanterna', () {
      final s = WeeklyStandings.from([membro('Ana', 0), membro('Bia', 0)]);
      expect(s.lantern, isEmpty);
      expect(s.podium, isEmpty);
      expect(s.rows.first.share, 0);
    });

    test('sozinho não tem lanterna', () {
      final s = WeeklyStandings.from([membro('Ana', 200)]);
      expect(s.lantern, isEmpty);
    });
  });
}
