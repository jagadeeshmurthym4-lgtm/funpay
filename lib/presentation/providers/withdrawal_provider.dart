import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/repositories/withdrawal_repository_impl.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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
  bool _isQrUploading = false;
  String? _qrCodeUrl;
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
  bool get isQrUploading => _isQrUploading;
  String? get qrCodeUrl => _qrCodeUrl;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  double get minRedemptionAmount =>
      WithdrawalRepositoryImpl.minRedemptionAmount;

  void setQrCodeUrl(String? url) {
    _qrCodeUrl = url;
    notifyListeners();
  }

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
      _errorMessage = 'Failed to initialize redemptions';
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
      _errorMessage = 'Failed to load redemption requests';
    } finally {
      _setLoading(false);
    }
  }

  // ─── QR Code Management ─────────────────────────────────

  /// Pick an image from gallery and upload as UPI QR Code.
  Future<bool> uploadQrCode({
    required String userId,
    required XFile imageFile,
  }) async {
    _setQrUploading(true);
    _clearMessages();
    try {
      final url = await _withdrawalRepository.uploadQrCode(
        userId: userId,
        imageFile: imageFile,
      );
      if (url != null) {
        _qrCodeUrl = url;
        _successMessage = '✅ QR Code uploaded successfully!';
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to upload QR Code. Please try again.';
        notifyListeners();
        return false;
      }
    } on WithdrawalException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      // Never show raw Firebase errors to the user
      debugPrint('[WithdrawalProvider] QR upload error: $e');
      _errorMessage = 'Failed to upload QR Code. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setQrUploading(false);
    }
  }

  /// Delete the user's QR Code from Firebase Storage.
  Future<bool> deleteQrCode({required String userId}) async {
    _setQrUploading(true);
    _clearMessages();
    try {
      final success = await _withdrawalRepository.deleteQrCode(userId: userId);
      if (success) {
        _qrCodeUrl = null;
        _successMessage = '🗑️ QR Code deleted successfully';
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete QR Code.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete QR Code: $e';
      notifyListeners();
      return false;
    } finally {
      _setQrUploading(false);
    }
  }

  // ─── Withdrawal Request ─────────────────────────────────

  Future<bool> requestWithdrawal({
    required String userId,
    required double amount,
    required RedemptionMethod method,
    required String accountDetails,
    String? qrCodeUrl,
    String? userName,
    String? userEmail,
    String? userPhone,
    double walletBalanceAtRequest = 0.0,
  }) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      await _withdrawalRepository.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: method,
        accountDetails: accountDetails,
        qrCodeUrl: qrCodeUrl,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        walletBalanceAtRequest: walletBalanceAtRequest,
      );
      _successMessage =
          'Redemption request of ₹${amount.toStringAsFixed(2)} submitted!';
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
      _errorMessage = 'Failed to submit redemption request';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // ─── Admin Actions ──────────────────────────────────────

  Future<bool> markAsPaid(String withdrawalId, {String? remarks, String? transactionId}) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      final withdrawal =
          await _withdrawalRepository.markAsPaid(
            withdrawalId,
            remarks: remarks,
            transactionId: transactionId,
          );
      _selectedWithdrawal = withdrawal;
      _successMessage = 'Redemption marked as granted!';
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

  Future<bool> approveWithdrawal(String withdrawalId, {String? remarks, String? transactionId}) async {
    _setSubmitting(true);
    _clearMessages();
    try {
      final withdrawal =
          await _withdrawalRepository.approveWithdrawal(
            withdrawalId,
            remarks: remarks,
            transactionId: transactionId,
          );
      _selectedWithdrawal = withdrawal;
      _successMessage = 'Redemption approved successfully';
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
      _successMessage = 'Redemption rejected';
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
      _errorMessage = 'Failed to load redemption details';
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

  void _setQrUploading(bool value) {
    _isQrUploading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
