import 'dart:async';
import 'dart:math';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/domain/entities/scratch_card_entity.dart';
import 'package:cashspark/domain/repositories/scratch_card_repository.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ScratchCardProvider extends ChangeNotifier {
  final ScratchCardRepository _scratchCardRepository;
  final Uuid _uuid;
  StreamSubscription<List<ScratchCardEntity>>? _cardsSubscription;

  List<ScratchCardEntity> _scratchCards = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _isScratching = false;
  bool _isEarningFromAd = false;
  String? _errorMessage;
  // Result from last scratch
  double? _lastScratchAmount;

  ScratchCardProvider({
    required ScratchCardRepository scratchCardRepository,
    Uuid? uuid,
  })  : _scratchCardRepository = scratchCardRepository,
        _uuid = uuid ?? const Uuid();

  List<ScratchCardEntity> get scratchCards => _scratchCards;
  bool get isLoading => _isLoading;
  bool get isScratching => _isScratching;
  String? get errorMessage => _errorMessage;
  double? get lastScratchAmount => _lastScratchAmount;

  /// Whether the initial stream data has been received at least once.
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// The number of unused scratch cards available.
  int get availableCards => _scratchCards.where((c) => !c.isUsed).length;
  bool get isEarningFromAd => _isEarningFromAd;

  void listenToCards(String userId) {
    _cardsSubscription?.cancel();
    _cardsSubscription =
        _scratchCardRepository.streamScratchCards(userId).listen(
      (cards) {
        _scratchCards = cards;
        _hasLoadedOnce = true;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        // Resolve loading state even on error so the UI shows the empty/error state
        // instead of an infinite spinner. This handles cases like missing Firestore
        // indexes or existing documents without a 'createdAt' field.
        _scratchCards = [];
        _hasLoadedOnce = true;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadScratchCards(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _scratchCards = await _scratchCardRepository.getScratchCards(userId);
    } catch (e) {
      _errorMessage = 'Failed to load scratch cards';
    } finally {
      _setLoading(false);
    }
  }

  /// Scratch the oldest unused card. Returns the reward amount or null on failure.
  Future<double?> scratchCard(String userId) async {
    if (_isScratching) return null;

    // Find the oldest unused card
    final unused = _scratchCards.where((c) => !c.isUsed).toList();
    if (unused.isEmpty) return null;

    final card = unused.last; // oldest (sorted desc, so last = oldest)
    _isScratching = true;
    notifyListeners();

    // Random reward: 2 pts, 3 pts, 4 pts, 5 pts, 6 pts, or 7 pts
    final possibleRewards = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0];
    final rewardAmount = possibleRewards[Random().nextInt(possibleRewards.length)];

    final updated = card.copyWith(
      rewardAmount: rewardAmount,
      isUsed: true,
      usedAt: DateTime.now(),
    );

    try {
      final success = await _scratchCardRepository.scratchCard(updated);
      if (success) {
        _lastScratchAmount = rewardAmount;
        notifyListeners();
        return rewardAmount;
      } else {
        _errorMessage = 'Card already scratched';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to scratch card';
      return null;
    } finally {
      _isScratching = false;
      notifyListeners();
    }
  }

  void cancelSubscriptions() {
    _cardsSubscription?.cancel();
  }

  void clearError() {
    _clearError();
  }

  /// Show a rewarded ad and create a scratch card on successful completion.
  /// Returns true if the ad was completed and a scratch card was added.
  Future<bool> earnScratchCardFromAd(String userId) async {
    if (_isEarningFromAd) return false;
    _isEarningFromAd = true;
    notifyListeners();
    try {
      // Show rewarded ad via AdMob
      final rewardAmount = await AdMobServiceImpl.instance.showRewardedAd();

      if (rewardAmount == null || rewardAmount <= 0) {
        // Ad was skipped or failed
        return false;
      }

      // Create a new scratch card
      final now = DateTime.now();
      final card = ScratchCardModel(
        scratchCardId: _uuid.v4(),
        userId: userId,
        submissionId: 'ad_scratch_${now.millisecondsSinceEpoch}',
        rewardAmount: 0.0,
        isUsed: false,
        createdAt: now,
      );
      await _scratchCardRepository.createScratchCard(card);

      return true;
    } catch (e) {
      debugPrint('earnScratchCardFromAd error: $e');
      return false;
    } finally {
      _isEarningFromAd = false;
      notifyListeners();
    }
  }

  void clearLastScratchResult() {
    _lastScratchAmount = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
