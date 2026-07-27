import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/repositories/withdrawal_repository_impl.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:flutter/foundation.dart';

class WithdrawalProvider extends ChangeNotifier {
  final WithdrawalRepositoryImpl _withdrawalRepository;
  StreamSubscription? _userWithdrawalsSubscription;
  StreamSubscription? _allWithdrawalsSubscription;

  List<WithdrawalEntity> _userWithdrawals = [];
  List<WithdrawalEntity> _allWithdrawals = [];
  WithdrawalEntity? _selectedWithdrawal;
  bool _hasPendingWithdrawal = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  WithdrawalProvider({
    required WithdrawalRepositoryImpl withdrawalRepository,
  }) : _withdrawalRepository = withdrawalRepository;

  List<WithdrawalEntity> get userWithdrawals => _userWithdrawals;
  List<WithdrawalEntity> get allWithdrawals => _allWithdrawals;
  WithdrawalEntity? get selectedWithdrawal => _selectedWithdrawal;
  bool get hasPendingWithdrawal => _hasPendingWithdrawal;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  double get minWithdrawalAmount =>
      WithdrawalRepositoryImpl.minWithdrawalAmount;

  void listenToUserWithdrawals(String userId) {
    _userWithdrawalsSubscription?.cancel();
    _userWithdrawalsSubscription =
        _withdrawalRepository.streamUserWithdrawals(userId).listen(
      (withdrawals) {
        _userWithdrawals = withdrawals;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void listenToAllWithdrawals({WithdrawalStatus? status}) {
    _allWithdrawalsSubscription?.cancel();
    _allWithdrawalsSubscription =
        _withdrawalRepository.streamAllWithdrawals(status: status).listen(
      (withdrawals) {
        _allWithdrawals = withdrawals;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void cancelSubscriptions() {
    _userWithdrawalsSubscription?.cancel();
    _allWithdrawalsSubscription?.cancel();
  }

  Future<void> initialize(String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      _hasPendingWithdrawal =
          await _withdrawalRepository.hasPendingWithdrawal(userId);
      listenToUserWithdrawals(userId);
    } catch (e) {
      _errorMessage = 'Failed to initialize withdrawals';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> initializeAdmin({WithdrawalStatus? status}) async {
    _setLoading(true);
    _clearMessages();
    try {
      listenToAllWithdrawals(status: status);
    } catch (e) {
      _errorMessage = 'Failed to load withdrawal requests';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> requestWithdrawal({
    required String userId,
    required double amount,
    required WithdrawalMethod method,
    required String accountDetails,
  }) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      await _withdrawalRepository.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: method,
        accountDetails: accountDetails,
      );
      _successMessage =
          'Withdrawal request of ₹${amount.toStringAsFixed(2)} submitted!';
      _hasPendingWithdrawal = true;
      notifyListeners();
      return true;
    } on WithdrawalException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit withdrawal request';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> markAsPaid(String withdrawalId, {String? remarks}) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      final withdrawal =
          await _withdrawalRepository.markAsPaid(
            withdrawalId,
            remarks: remarks,
          );
      _selectedWithdrawal = withdrawal;
      _successMessage = 'Withdrawal marked as paid!';
      notifyListeners();
      return true;
    } on WithdrawalException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to process withdrawal';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> approveWithdrawal(String withdrawalId, {String? remarks}) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      final withdrawal =
          await _withdrawalRepository.approveWithdrawal(
            withdrawalId,
            remarks: remarks,
          );
      _selectedWithdrawal = withdrawal;
      _successMessage = 'Withdrawal approved successfully';
      notifyListeners();
      return true;
    } on WithdrawalException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to approve withdrawal';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> rejectWithdrawal(String withdrawalId,
      {required String remarks}) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      final withdrawal =
          await _withdrawalRepository.rejectWithdrawal(
            withdrawalId,
            remarks: remarks,
          );
      _selectedWithdrawal = withdrawal;
      _successMessage = 'Withdrawal rejected';
      notifyListeners();
      return true;
    } on WithdrawalException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reject withdrawal';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void loadWithdrawal(String withdrawalId) async {
    _setLoading(true);
    _clearMessages();
    try {
      _selectedWithdrawal =
          await _withdrawalRepository.getWithdrawal(withdrawalId);
    } catch (e) {
      _errorMessage = 'Failed to load withdrawal details';
    } finally {
      _setLoading(false);
    }
  }

  void selectWithdrawal(WithdrawalEntity? withdrawal) {
    _selectedWithdrawal = withdrawal;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
