import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/bonus_models.dart';
import 'package:cashspark/data/models/reward_model.dart';
import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class RewardFirestoreDataSource {
  final FirebaseFirestore _firestore;

  RewardFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Reward Config ---

  Future<RewardConfigModel?> getRewardConfig() async {
    final doc = await _firestore
        .collection(AppConstants.rewardsConfigCollection)
        .doc('config')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return RewardConfigModel.fromFirestore(doc.data()!);
  }

  // --- Rewards ---

  Future<void> createReward(RewardModel reward) async {
    await _firestore
        .collection(AppConstants.rewardsCollection)
        .doc(reward.rewardId)
        .set(reward.toFirestore());
  }

  Future<List<RewardModel>> getRewardHistory(String userId,
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final rewards = query.docs
          .map((doc) => RewardModel.fromFirestore(doc.data()))
          .toList();
      // Sort and limit in Dart to avoid needing composite index
      rewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rewards.take(limit).toList();
    } catch (e) {
      debugPrint('getRewardHistory error: $e');
      return [];
    }
  }

  Future<List<RewardModel>> getRewardsByType(String userId,
      RewardType type, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final rewards = query.docs
          .map((doc) => RewardModel.fromFirestore(doc.data()))
          .where((r) => r.rewardType == type)
          .toList();
      rewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rewards.take(limit).toList();
    } catch (e) {
      debugPrint('getRewardsByType error: $e');
      return [];
    }
  }

  Future<double> getTotalRewardAmountByType(
      String userId, RewardType type) async {
    try {
      double total = 0;
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['rewardType'] == type.name && data['status'] == RewardStatus.claimed.name) {
          total += (data['rewardAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTotalRewardAmountByType error: $e');
      return 0.0;
    }
  }

  Stream<List<RewardModel>> streamRewards(String userId) {
    return _firestore
        .collection(AppConstants.rewardsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final rewards = snapshot.docs
          .map((doc) => RewardModel.fromFirestore(doc.data()))
          .toList();
      rewards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rewards.take(50).toList();
    });
  }

  // --- Daily Check-In ---

  Future<DailyCheckInModel?> getTodayCheckIn(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final query = await _firestore
          .collection(AppConstants.dailyCheckInsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in query.docs) {
        final date = (doc.data()['checkInDate'] as dynamic)?.toDate() as DateTime?;
        if (date != null && date.isAfter(startOfDay) && date.isBefore(endOfDay)) {
          return DailyCheckInModel.fromFirestore(doc.data());
        }
      }
      return null;
    } catch (e) {
      debugPrint('getTodayCheckIn error: $e');
      return null;
    }
  }

  Future<void> createCheckIn(DailyCheckInModel checkIn) async {
    await _firestore
        .collection(AppConstants.dailyCheckInsCollection)
        .doc(checkIn.id)
        .set(checkIn.toFirestore());
  }

  Future<List<DailyCheckInModel>> getCheckInHistory(String userId,
      {int limit = 30}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.dailyCheckInsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final checkIns = query.docs
          .map((doc) => DailyCheckInModel.fromFirestore(doc.data()))
          .toList();
      checkIns.sort((a, b) => b.checkInDate.compareTo(a.checkInDate));
      return checkIns.take(limit).toList();
    } catch (e) {
      debugPrint('getCheckInHistory error: $e');
      return [];
    }
  }

  // --- Spin Data ---

  Future<SpinDataModel?> getSpinData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.spinDataCollection)
          .doc(userId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return SpinDataModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getSpinData error: $e');
      return null;
    }
  }

  Future<void> saveSpinData(SpinDataModel data) async {
    await _firestore
        .collection(AppConstants.spinDataCollection)
        .doc(data.userId)
        .set(data.toFirestore());
  }

  Stream<SpinDataModel?> streamSpinData(String userId) {
    return _firestore
        .collection(AppConstants.spinDataCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return SpinDataModel.fromFirestore(snapshot.data()!);
    });
  }

  // --- Streak ---

  Future<StreakModel?> getStreak(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.streaksCollection)
        .doc(userId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return StreakModel.fromFirestore(doc.data()!);
  }

  Future<void> saveStreak(StreakModel streak) async {
    await _firestore
        .collection(AppConstants.streaksCollection)
        .doc(streak.userId)
        .set(streak.toFirestore());
  }

  Stream<StreakModel?> streamStreak(String userId) {
    return _firestore
        .collection(AppConstants.streaksCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return StreakModel.fromFirestore(snapshot.data()!);
    });
  }

  // --- Ad Watch Tracking ---

  Future<int> getTodayAdCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return query.docs.where((doc) {
        final data = doc.data();
        if (data['rewardType'] != RewardType.adReward.name) return false;
        final createdAt = (data['createdAt'] as dynamic)?.toDate() as DateTime?;
        return createdAt != null && createdAt.isAfter(startOfDay);
      }).length;
    } catch (e) {
      debugPrint('getTodayAdCount error: $e');
      return 0;
    }
  }

  Future<double> getTodayAdEarnings(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      double total = 0;
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['rewardType'] != RewardType.adReward.name) continue;
        if (data['status'] != RewardStatus.claimed.name) continue;
        final createdAt = (data['createdAt'] as dynamic)?.toDate() as DateTime?;
        if (createdAt != null && createdAt.isAfter(startOfDay)) {
          total += (data['rewardAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTodayAdEarnings error: $e');
      return 0.0;
    }
  }

  Future<int> getLifetimeAdCount(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      int count = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['rewardType'] == RewardType.adReward.name &&
            data['status'] == RewardStatus.claimed.name) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('getLifetimeAdCount error: $e');
      return 0;
    }
  }

  Future<DateTime?> getLastAdWatchTime(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.rewardsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final adRewards = query.docs.where((doc) {
        return doc.data()['rewardType'] == RewardType.adReward.name;
      }).toList();
      adRewards.sort((a, b) {
        final aDate = (a.data()['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime(2000);
        final bDate = (b.data()['createdAt'] as dynamic)?.toDate() as DateTime? ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      if (adRewards.isEmpty) return null;
      return (adRewards.first.data()['createdAt'] as dynamic)?.toDate() as DateTime?;
    } catch (e) {
      debugPrint('getLastAdWatchTime error: $e');
      return null;
    }
  }

  // --- Weekly Bonus ---

  Future<WeeklyBonusModel?> getWeeklyBonus(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.weeklyBonusesCollection)
          .doc(userId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return WeeklyBonusModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getWeeklyBonus error: $e');
      return null;
    }
  }

  Future<void> saveWeeklyBonus(WeeklyBonusModel bonus) async {
    try {
      await _firestore
          .collection(AppConstants.weeklyBonusesCollection)
          .doc(bonus.userId)
          .set(bonus.toFirestore());
    } catch (e) {
      debugPrint('saveWeeklyBonus error: $e');
      rethrow;
    }
  }

  Stream<WeeklyBonusModel?> streamWeeklyBonus(String userId) {
    return _firestore
        .collection(AppConstants.weeklyBonusesCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return WeeklyBonusModel.fromFirestore(snapshot.data()!);
    });
  }

  // --- Monthly Bonus ---

  Future<MonthlyBonusModel?> getMonthlyBonus(String userId, String monthKey) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.monthlyBonusesCollection)
          .doc(userId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final data = MonthlyBonusModel.fromFirestore(doc.data()!);
      // Return only if month matches; otherwise treat as new month (reset)
      if (data.monthKey != monthKey) return null;
      return data;
    } catch (e) {
      debugPrint('getMonthlyBonus error: $e');
      return null;
    }
  }

  Future<void> saveMonthlyBonus(MonthlyBonusModel bonus) async {
    try {
      await _firestore
          .collection(AppConstants.monthlyBonusesCollection)
          .doc(bonus.userId)
          .set(bonus.toFirestore());
    } catch (e) {
      debugPrint('saveMonthlyBonus error: $e');
      rethrow;
    }
  }

  Stream<MonthlyBonusModel?> streamMonthlyBonus(String userId) {
    return _firestore
        .collection(AppConstants.monthlyBonusesCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return MonthlyBonusModel.fromFirestore(snapshot.data()!);
    });
  }

  // --- Tasks ---

  Future<List<TaskModel>> getTodaysTasks(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final query = await _firestore
          .collection(AppConstants.tasksCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final tasks = query.docs
          .map((doc) => TaskModel.fromFirestore(doc.data()))
          .where((task) => task.createdAt.isAfter(startOfDay))
          .toList();
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    } catch (e) {
      debugPrint('getTodaysTasks error: $e');
      return [];
    }
  }

  Future<void> createTask(TaskModel task) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(task.taskId)
        .set(task.toFirestore());
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(task.taskId)
        .update(task.toFirestore());
  }

  Stream<List<TaskModel>> streamTodaysTasks(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection(AppConstants.tasksCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data()))
          .where((task) => task.createdAt.isAfter(startOfDay))
          .toList();
      tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return tasks;
    });
  }
}
