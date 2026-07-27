import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/referral_level_firestore_datasource.dart';
import 'package:cashspark/data/models/referral_level_model.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/referral_level_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/referral_level_repository.dart';
import 'package:uuid/uuid.dart';

class ReferralLevelRepositoryImpl implements ReferralLevelRepository {
  final ReferralLevelFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final Uuid _uuid;

  ReferralLevelRepositoryImpl({
    required ReferralLevelFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<ReferralLevelEntity>> getAllLevels() async {
    try {
      return await _dataSource.getAllLevels();
    } catch (e) {
      throw FirestoreException('Failed to get referral levels: $e');
    }
  }

  @override
  Future<void> saveLevel(ReferralLevelEntity level) async {
    try {
      await _dataSource.saveLevel(ReferralLevelModel.fromEntity(level));
    } catch (e) {
      throw FirestoreException('Failed to save referral level: $e');
    }
  }

  @override
  Future<void> deleteLevel(String levelId) async {
    try {
      await _dataSource.deleteLevel(levelId);
    } catch (e) {
      throw FirestoreException('Failed to delete referral level: $e');
    }
  }

  @override
  Future<Set<int>> getClaimedLevels(String userId) async {
    try {
      final milestones = await _dataSource.getClaimedMilestones(userId);
      return milestones.map((m) => m.levelNumber).toSet();
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> claimMilestoneReward({
    required String userId,
    required int levelNumber,
    required double rewardAmount,
  }) async {
    try {
      // Credit the reward to user's wallet
      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: rewardAmount,
        earningsChange: rewardAmount,
        withdrawnChange: 0,
      );

      // Create transaction record
      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: rewardAmount,
        source: TransactionSource.reward,
        status: TransactionStatus.completed,
        description: 'Referral Level $levelNumber milestone reward',
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);

      // Record claimed milestone
      final milestone = ClaimedMilestoneModel(
        id: _uuid.v4(),
        userId: userId,
        levelNumber: levelNumber,
        claimedAt: DateTime.now(),
      );
      await _dataSource.claimMilestone(milestone);
    } catch (e) {
      throw FirestoreException('Failed to claim milestone reward: $e');
    }
  }

  @override
  Future<List<ClaimedMilestoneEntity>> getClaimedMilestones(String userId) async {
    try {
      return await _dataSource.getClaimedMilestones(userId);
    } catch (e) {
      return [];
    }
  }
}
