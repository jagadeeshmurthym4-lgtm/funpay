import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper that simulates the daily reset logic from SpinWheelScreen's
/// _onSpinDataReceived: when the stored lastResetDate is before today,
/// spinsToday and bonusSpins are both reset to 0.
SpinDataEntity _applyDailyReset(SpinDataEntity data, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final resetDay = DateTime(
    data.lastResetDate.year,
    data.lastResetDate.month,
    data.lastResetDate.day,
  );
  if (resetDay.isBefore(today)) {
    return data.copyWith(
      spinsToday: 0,
      bonusSpins: 0,
      lastResetDate: now,
      lastSpinDate: now,
    );
  }
  return data;
}

/// Helper that simulates the bonus spin consumption logic from
/// SpinWheelScreen's _creditAndSave: when free spins are exhausted
/// (spinsToday >= dailyLimit), decrement bonusSpins.
({SpinDataEntity data, int newBonusSpins}) _consumeSpin(
  SpinDataEntity data, {
  int dailyLimit = 3,
}) {
  final hasFreeSpinsLeft = data.spinsToday < dailyLimit;
  final int newBonusSpins;
  if (!hasFreeSpinsLeft && data.bonusSpins > 0) {
    newBonusSpins = data.bonusSpins - 1;
  } else {
    newBonusSpins = data.bonusSpins;
  }

  final updated = data.copyWith(
    totalSpins: data.totalSpins + 1,
    spinsToday: data.spinsToday + 1,
    bonusSpins: newBonusSpins,
    lastSpinDate: DateTime.now(),
  );
  return (data: updated, newBonusSpins: newBonusSpins);
}

/// Helper that simulates earning a bonus spin from an ad
SpinDataEntity _earnBonusSpin(SpinDataEntity data) {
  return data.copyWith(
    bonusSpins: data.bonusSpins + 1,
    lastSpinDate: DateTime.now(),
  );
}

void main() {
  // ═══════════════════════════════════════════════════════════
  // SpinDataEntity copyWith — bonusSpins
  // ═══════════════════════════════════════════════════════════

  group('SpinDataEntity.bonusSpins', () {
    test('defaults to 0', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
      );
      expect(entity.bonusSpins, 0);
    });

    test('can be set in constructor', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
        bonusSpins: 3,
      );
      expect(entity.bonusSpins, 3);
    });

    test('copyWith updates bonusSpins', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
      );
      final updated = entity.copyWith(bonusSpins: 5);
      expect(updated.bonusSpins, 5);
    });

    test('copyWith preserves bonusSpins when not specified', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
        bonusSpins: 2,
      );
      final updated = entity.copyWith(totalSpins: 10);
      expect(updated.bonusSpins, 2);
    });

    test('copyWith can reset bonusSpins to 0', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
        bonusSpins: 3,
      );
      final updated = entity.copyWith(bonusSpins: 0);
      expect(updated.bonusSpins, 0);
    });

    test('copyWith is immutable (original unchanged)', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
        bonusSpins: 2,
      );
      entity.copyWith(bonusSpins: 10);
      expect(entity.bonusSpins, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // SpinDataModel serialization — bonusSpins
  // ═══════════════════════════════════════════════════════════

  group('SpinDataModel.bonusSpins serialization', () {
    final baseTime = DateTime(2026, 7, 17, 10, 30, 0);
    final ts = Timestamp.fromDate(baseTime);

    Map<String, dynamic> baseMap({
      int bonusSpins = 0,
    }) {
      return {
        'userId': 'test-uid',
        'totalSpins': 10,
        'spinsToday': 3,
        'bonusSpins': bonusSpins,
        'lastSpinDate': ts,
        'lastResetDate': ts,
        'totalRewardsEarned': 25.0,
        'totalSpinsWon': 5,
        'spinHistory': <Map<String, dynamic>>[],
      };
    }

    test('fromFirestore reads bonusSpins', () {
      final model = SpinDataModel.fromFirestore(baseMap(bonusSpins: 2));
      expect(model.bonusSpins, 2);
    });

    test('fromFirestore defaults to 0 when missing', () {
      final map = baseMap()..remove('bonusSpins');
      final model = SpinDataModel.fromFirestore(map);
      expect(model.bonusSpins, 0);
    });

    test('fromFirestore defaults to 0 when null', () {
      final map = baseMap()..['bonusSpins'] = null;
      final model = SpinDataModel.fromFirestore(map);
      expect(model.bonusSpins, 0);
    });

    test('toFirestore includes bonusSpins', () {
      final model = SpinDataModel(
        userId: 'test-uid',
        lastSpinDate: baseTime,
        lastResetDate: baseTime,
        totalSpins: 10,
        spinsToday: 3,
        bonusSpins: 2,
        totalRewardsEarned: 25.0,
        totalSpinsWon: 5,
      );
      final map = model.toFirestore();
      expect(map['bonusSpins'], 2);
    });

    test('fromFirestore / toFirestore round-trip via Timestamps', () {
      // fromFirestore expects Timestamps for date fields (Firestore format)
      final firestoreMap = {
        'userId': 'test-uid',
        'totalSpins': 10,
        'spinsToday': 3,
        'bonusSpins': 4,
        'lastSpinDate': Timestamp.fromDate(baseTime),
        'lastResetDate': Timestamp.fromDate(baseTime),
        'totalRewardsEarned': 25.0,
        'totalSpinsWon': 5,
        'spinHistory': <Map<String, dynamic>>[],
      };
      final restored = SpinDataModel.fromFirestore(firestoreMap);
      expect(restored.bonusSpins, 4);
      expect(restored.spinsToday, 3);
      expect(restored.totalSpins, 10);
      expect(restored.userId, 'test-uid');
    });

    test('fromEntity preserves bonusSpins', () {
      final entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: baseTime,
        bonusSpins: 3,
      );
      final model = SpinDataModel.fromEntity(entity);
      expect(model.bonusSpins, 3);
    });

    test('handles multiple bonus spin increments in serialization', () {
      // Simulate earning bonus spins over time
      var entity = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: baseTime,
      );

      // Earn 3 bonus spins from ads
      entity = _earnBonusSpin(entity); // 1
      entity = _earnBonusSpin(entity); // 2
      entity = _earnBonusSpin(entity); // 3
      expect(entity.bonusSpins, 3);

      // Serialize and restore via fromEntity + toFirestore Timestamp conversion
      final model = SpinDataModel.fromEntity(entity);
      final modelMap = model.toFirestore();
      // Convert DateTimes to Timestamps for fromFirestore
      final firestoreMap = Map<String, dynamic>.from(modelMap)
        ..['lastSpinDate'] = Timestamp.fromDate(entity.lastSpinDate)
        ..['lastResetDate'] = Timestamp.fromDate(entity.lastResetDate);
      final restored = SpinDataModel.fromFirestore(firestoreMap);
      expect(restored.bonusSpins, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Daily reset logic — bonusSpins cleared
  // ═══════════════════════════════════════════════════════════

  group('Daily reset clears bonusSpins', () {
    test('resets both spinsToday and bonusSpins when new day', () {
      final yesterday = DateTime(2026, 7, 16, 23, 0, 0);
      final today = DateTime(2026, 7, 17, 10, 0, 0);

      final data = SpinDataEntity(
        userId: 'test-uid',
        totalSpins: 15,
        spinsToday: 5,
        bonusSpins: 2,
        lastSpinDate: yesterday,
        lastResetDate: yesterday,
        totalRewardsEarned: 30.0,
      );

      final reset = _applyDailyReset(data, today);
      expect(reset.spinsToday, 0);
      expect(reset.bonusSpins, 0);
      expect(reset.totalSpins, 15); // total spins preserved
    });

    test('does not reset when same day', () {
      final now = DateTime(2026, 7, 17, 10, 0, 0);

      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 2,
        bonusSpins: 1,
        lastSpinDate: now,
        lastResetDate: now,
      );

      final result = _applyDailyReset(data, now);
      expect(result.spinsToday, 2);
      expect(result.bonusSpins, 1);
    });

    test('does not reset when future date (edge case)', () {
      final today = DateTime(2026, 7, 17);
      final futureReset = DateTime(2026, 7, 20);

      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 3,
        bonusSpins: 2,
        lastSpinDate: today,
        lastResetDate: futureReset,
      );

      final result = _applyDailyReset(data, today);
      expect(result.spinsToday, 3);
      expect(result.bonusSpins, 2);
    });

    test('multiple day gap still resets', () {
      final threeDaysAgo = DateTime(2026, 7, 14);
      final today = DateTime(2026, 7, 17);

      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 5,
        bonusSpins: 3,
        lastSpinDate: threeDaysAgo,
        lastResetDate: threeDaysAgo,
      );

      final reset = _applyDailyReset(data, today);
      expect(reset.spinsToday, 0);
      expect(reset.bonusSpins, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Bonus spin consumption logic
  // ═══════════════════════════════════════════════════════════

  group('Bonus spin consumption', () {
    test('free spin consumed first (spinsToday < dailyLimit)', () {
      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 1,
        bonusSpins: 2,
        lastSpinDate: DateTime.now(),
      );

      final result = _consumeSpin(data);
      expect(result.data.spinsToday, 2); // free spin used
      expect(result.data.bonusSpins, 2); // bonus not touched
      expect(result.newBonusSpins, 2);
    });

    test('bonus spin consumed when free spins exhausted (spinsToday == dailyLimit)', () {
      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 3,
        bonusSpins: 2,
        lastSpinDate: DateTime.now(),
      );

      final result = _consumeSpin(data);
      expect(result.data.spinsToday, 4); // total up
      expect(result.data.bonusSpins, 1); // bonus decremented
      expect(result.newBonusSpins, 1);
    });

    test('bonus spin consumed when free spins exceeded (spinsToday > dailyLimit)', () {
      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 5,
        bonusSpins: 3,
        lastSpinDate: DateTime.now(),
      );

      final result = _consumeSpin(data);
      expect(result.data.spinsToday, 6);
      expect(result.data.bonusSpins, 2); // decremented
    });

    test('cannot consume bonus spin when bonusSpins is 0', () {
      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 3,
        bonusSpins: 0,
        lastSpinDate: DateTime.now(),
      );

      final result = _consumeSpin(data);
      expect(result.data.spinsToday, 4);
      expect(result.data.bonusSpins, 0); // stays 0
      expect(result.newBonusSpins, 0);
    });

    test('multiple consecutive bonus spins decrement correctly', () {
      final data = SpinDataEntity(
        userId: 'test-uid',
        spinsToday: 3,
        bonusSpins: 3,
        lastSpinDate: DateTime.now(),
      );

      // Use 3 bonus spins
      var result = _consumeSpin(data);
      expect(result.data.bonusSpins, 2);

      result = _consumeSpin(result.data);
      expect(result.data.bonusSpins, 1);

      result = _consumeSpin(result.data);
      expect(result.data.bonusSpins, 0);

      // Next spin should have no bonus spin to consume
      result = _consumeSpin(result.data);
      expect(result.data.bonusSpins, 0);
    });

    test('earn and consume cycle works end-to-end', () {
      var data = SpinDataEntity(
        userId: 'test-uid',
        lastSpinDate: DateTime.now(),
      );

      // Use 3 free spins
      data = _consumeSpin(data).data; // spin 1 (free)
      expect(data.spinsToday, 1);
      expect(data.bonusSpins, 0);

      data = _consumeSpin(data).data; // spin 2 (free)
      expect(data.spinsToday, 2);
      expect(data.bonusSpins, 0);

      data = _consumeSpin(data).data; // spin 3 (free)
      expect(data.spinsToday, 3);
      expect(data.bonusSpins, 0);

      // Free spins exhausted — earn a bonus spin from ad
      data = _earnBonusSpin(data);
      expect(data.bonusSpins, 1);

      // Use the bonus spin
      data = _consumeSpin(data).data; // spin 4 (bonus)
      expect(data.spinsToday, 4);
      expect(data.bonusSpins, 0);

      // Earn another and use it
      data = _earnBonusSpin(data);
      data = _consumeSpin(data).data;
      expect(data.spinsToday, 5);
      expect(data.bonusSpins, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Computed property helpers
  // ═══════════════════════════════════════════════════════════

  group('Computed spin properties', () {
    // These simulate the getters in SpinWheelScreen
    const dailyLimit = 3;

    int freeSpinsRemaining(SpinDataEntity d) =>
        (dailyLimit - d.spinsToday).clamp(0, dailyLimit);

    int spinsRemaining(SpinDataEntity d) =>
        freeSpinsRemaining(d) + d.bonusSpins;

    bool hasFreeSpinsLeft(SpinDataEntity d) => d.spinsToday < dailyLimit;

    bool canSpin(SpinDataEntity d) => spinsRemaining(d) > 0;

    test('freeSpinsRemaining returns correct values', () {
      final now = DateTime.now();
      expect(freeSpinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 0)), 3);
      expect(freeSpinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 2)), 1);
      expect(freeSpinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3)), 0);
      expect(freeSpinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 5)), 0); // clamped
    });

    test('spinsRemaining includes bonus spins when free spins exhausted', () {
      final now = DateTime.now();
      // Free spins available, no bonus
      expect(spinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 1, bonusSpins: 0)), 2);
      // Free spins available, with bonus
      expect(spinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 1, bonusSpins: 2)), 4);
      // Free spins exhausted, no bonus
      expect(spinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3, bonusSpins: 0)), 0);
      // Free spins exhausted, with bonus
      expect(spinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3, bonusSpins: 2)), 2);
      // Free spins exceeded, with bonus
      expect(spinsRemaining(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 5, bonusSpins: 1)), 1);
    });

    test('hasFreeSpinsLeft reflects whether free spins remain', () {
      final now = DateTime.now();
      expect(hasFreeSpinsLeft(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 0)), true);
      expect(hasFreeSpinsLeft(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 2)), true);
      expect(hasFreeSpinsLeft(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3)), false);
      expect(hasFreeSpinsLeft(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 5)), false);
    });

    test('canSpin is true when spinsRemaining > 0', () {
      final now = DateTime.now();
      // No spins used, no bonus
      expect(canSpin(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 0, bonusSpins: 0)), true);
      // Free spins used, with bonus
      expect(canSpin(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3, bonusSpins: 2)), true);
      // All exhausted
      expect(canSpin(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 3, bonusSpins: 0)), false);
      // Over limit, no bonus
      expect(canSpin(SpinDataEntity(userId: 'u', lastSpinDate: now, spinsToday: 5, bonusSpins: 0)), false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // SpinHistoryEntry serialization
  // ═══════════════════════════════════════════════════════════

  group('SpinHistoryEntry', () {
    test('toJson / fromJson round-trip', () {
      final now = DateTime(2026, 7, 17, 10, 30, 0);
      final entry = SpinHistoryEntry(amount: 5.0, timestamp: now);
      final json = entry.toJson();
      final restored = SpinHistoryEntry.fromJson({
        ...json,
        'timestamp': Timestamp.fromDate(now),
      });
      expect(restored.amount, 5.0);
      expect(restored.timestamp, now);
    });
  });
}
