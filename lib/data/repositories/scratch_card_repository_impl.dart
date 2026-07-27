import 'package:cashspark/data/datasources/scratch_card_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/scratch_card_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/scratch_card_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class ScratchCardRepositoryImpl implements ScratchCardRepository {
  final ScratchCardFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final Uuid _uuid;

  ScratchCardRepositoryImpl({
    required ScratchCardFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<void> createScratchCard(ScratchCardEntity card) async {
    final model = card is ScratchCardModel
        ? card
        : ScratchCardModel.fromEntity(card);
    await _dataSource.createScratchCard(model);
  }

  @override
  Future<bool> hasScratchCardForSubmission(String submissionId) async {
    return await _dataSource.hasScratchCardForSubmission(submissionId);
  }

  @override
  Future<ScratchCardEntity?> getScratchCard(String scratchCardId) async {
    return await _dataSource.getScratchCard(scratchCardId);
  }

  @override
  Future<bool> scratchCard(ScratchCardEntity card) async {
    // 1. Atomically mark the card as used in Firestore
    final success = await _dataSource.scratchCard(
      card is ScratchCardModel
          ? card
          : ScratchCardModel.fromEntity(card),
    );
    if (!success) return false;

    // 2. Credit the reward to the user's wallet
    if (card.rewardAmount > 0) {
      try {
        await _walletDataSource.updateWalletBalance(
          userId: card.userId,
          amountChange: card.rewardAmount,
          earningsChange: card.rewardAmount,
          withdrawnChange: 0,
        );

        final transaction = TransactionModel(
          transactionId: _uuid.v4(),
          userId: card.userId,
          type: TransactionType.credit,
          amount: card.rewardAmount,
          source: TransactionSource.reward,
          status: TransactionStatus.completed,
          description: 'Scratch Card reward',
          createdAt: DateTime.now(),
        );
        await _walletDataSource.createTransaction(transaction);
      } catch (e) {
        debugPrint('scratchCard wallet credit error: $e');
        // Card was marked used but wallet credit failed — return true
        // since the atomic scratch succeeded; wallet can be reconciled
      }
    }

    return true;
  }

  @override
  Future<List<ScratchCardEntity>> getScratchCards(String userId) async {
    return await _dataSource.getScratchCards(userId);
  }

  @override
  Stream<List<ScratchCardEntity>> streamScratchCards(String userId) {
    return _dataSource.streamScratchCards(userId);
  }
}
