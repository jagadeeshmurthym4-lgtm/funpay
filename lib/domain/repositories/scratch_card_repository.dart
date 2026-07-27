import 'package:cashspark/domain/entities/scratch_card_entity.dart';

abstract class ScratchCardRepository {
  Future<void> createScratchCard(ScratchCardEntity card);
  Future<bool> hasScratchCardForSubmission(String submissionId);
  Future<ScratchCardEntity?> getScratchCard(String scratchCardId);

  /// Atomically marks a card as used with the reward amount.
  /// Returns true if successful, false if already scratched or failed.
  Future<bool> scratchCard(ScratchCardEntity card);

  Future<List<ScratchCardEntity>> getScratchCards(String userId);
  Stream<List<ScratchCardEntity>> streamScratchCards(String userId);
}
