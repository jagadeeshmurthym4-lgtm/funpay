import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/offer_entity.dart';
import 'package:cashspark/domain/repositories/offer_repository.dart';
import 'package:flutter/foundation.dart';

class OfferProvider extends ChangeNotifier {
  final OfferRepository _offerRepository;
  StreamSubscription<List<OfferEntity>>? _offersSub;

  List<OfferEntity> _offers = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  String? _errorMessage;

  // ─── Auto-retry ───────────────────────────────────────
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;

  // Configurable page size
  static const int _pageSize = 10;

  OfferProvider({
    required OfferRepository offerRepository,
  }) : _offerRepository = offerRepository;

  List<OfferEntity> get offers => _offers;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Subscribe to real-time active offers stream.
  void subscribeToActiveOffers() {
    _cancelRetry();
    _offersSub?.cancel();
    _offersSub = _offerRepository.streamActiveOffers().listen(
      (offers) {
        _offers = offers;
        _errorMessage = null;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load offers. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToActiveOffers());
      },
    );
  }

  /// One-time paginated load (fallback / for screens that don't need real-time).
  Future<void> loadActiveOffers() async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _offerRepository.getActiveOffersPaginated(
        limit: _pageSize,
      );
      _offers = result.items;
      _lastDoc = result.lastDoc;
      _hasMore = result.hasMore;
    } catch (e) {
      _errorMessage = 'Failed to load offers';
    } finally {
      _setLoading(false);
    }
  }

  /// Load the next page of offers using cursor-based pagination.
  Future<void> loadMoreOffers() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    _isLoadingMore = true;
    _clearError();
    notifyListeners();

    try {
      final result = await _offerRepository.getActiveOffersPaginated(
        startAfter: _lastDoc,
        limit: _pageSize,
      );
      _offers = [..._offers, ...result.items];
      _lastDoc = result.lastDoc;
      _hasMore = result.hasMore;
    } catch (e) {
      _errorMessage = 'Failed to load more offers';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOffers() async {
    _setLoading(true);
    _clearError();
    try {
      _offers = await _offerRepository.getAllOffers();
    } catch (e) {
      _errorMessage = 'Failed to load offers';
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh by re-subscribing to the real-time stream.
  Future<void> refresh() async {
    _resetPagination();
    subscribeToActiveOffers();
  }

  void unsubscribe() {
    _cancelRetry();
    _offersSub?.cancel();
    _offersSub = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  // ─── Auto-retry helpers ───────────────────────────────

  void _scheduleRetry(VoidCallback retryFn) {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 1 << _retryCount);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, retryFn);
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  void _resetPagination() {
    _hasMore = true;
    _lastDoc = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
