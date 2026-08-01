import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/services/cloudinary_service.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/withdrawal_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/withdrawal_model.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/domain/repositories/withdrawal_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class WithdrawalRepositoryImpl implements WithdrawalRepository {
  final WithdrawalFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final NotificationFirestoreDataSource _notificationDataSource;
  final Uuid _uuid;

  // Configurable withdrawal limits
  static const double minWithdrawalAmount = 45.0;
  static const int maxQrSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedQrFormats = ['png', 'jpg', 'jpeg'];

  WithdrawalRepositoryImpl({
    required WithdrawalFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    required NotificationFirestoreDataSource notificationDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _notificationDataSource = notificationDataSource,
        _uuid = uuid ?? const Uuid();

  // ─── QR Code Management (via Cloudinary) ────────────────

  /// Pick an image from gallery and upload as QR code to Cloudinary.
  /// Returns the download URL on success, null on failure.
  Future<String?> uploadQrCode({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > maxQrSizeBytes) {
        throw WithdrawalException(
          'Image size exceeds 5 MB limit. Please choose a smaller file.',
        );
      }

      // Validate file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!allowedQrFormats.contains(extension)) {
        throw WithdrawalException(
          'Invalid file format. Please upload a PNG, JPG, or JPEG image.',
        );
      }

      // Upload to Cloudinary using bytes (more reliable than file path on Android)
      final cloudinary = CloudinaryService.instance;
      final fileName = 'qr_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final imageBytes = await imageFile.readAsBytes();
      final downloadUrl = await cloudinary.uploadImageBytes(
        imageBytes: imageBytes,
        fileName: fileName,
        folder: 'qr_codes',
      );

      if (downloadUrl == null) {
        throw FirestoreException(
          'Failed to upload QR code. Please try again.',
        );
      }

      debugPrint('QR Code uploaded to Cloudinary for user: $userId');
      return downloadUrl;
    } on WithdrawalException {
      rethrow;
    } catch (e) {
      debugPrint('[QR_DEBUG] Upload error: $e');
      // Never show raw error messages to user
      throw FirestoreException(
        'Failed to upload QR code. Please try again.',
      );
    }
  }

  /// Delete the user's QR code reference.
  /// Cloudinary does not support deletion via unsigned upload presets,
  /// so we simply clear the URL reference. The old image remains in
  /// Cloudinary but will never be served since we overwrite the Firestore
  /// URL on next upload.
  Future<bool> deleteQrCode({required String userId}) async {
    // Cloudinary unsigned uploads don't provide a public delete API.
    // The QR code URL in Firestore will be nulled out by the caller,
    // and the next upload will create a new file.
    return true;
  }

  // ─── Withdrawal Methods ─────────────────────────────────

  @override
  Future<WithdrawalEntity> requestWithdrawal({
    required String userId,
    required double amount,
    required WithdrawalMethod method,
    required String accountDetails,
    String? qrCodeUrl,
    String? userName,
    String? userEmail,
    String? userPhone,
    double walletBalanceAtRequest = 0.0,
  }) async {
    try {
      // Validate withdrawal rules
      await validateWithdrawalRules(userId: userId, amount: amount);

      // Check for duplicate pending request
      final hasPending = await _dataSource.hasPendingWithdrawal(userId);
      if (hasPending) {
        throw WithdrawalException('You already have a pending withdrawal request');
      }

      // Check balance via wallet datasource
      final wallet = await _walletDataSource.getWallet(userId);
      if (wallet == null) {
        throw WithdrawalException('Wallet not found');
      }
      if (wallet.walletBalance < amount) {
        throw WithdrawalException('Insufficient balance');
      }

      final withdrawal = WithdrawalModel(
        withdrawalId: _uuid.v4(),
        userId: userId,
        amount: amount,
        method: method,
        accountDetails: accountDetails,
        qrCodeUrl: qrCodeUrl,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        walletBalanceAtRequest: wallet.walletBalance,
        status: WithdrawalStatus.pending,
        requestedAt: DateTime.now(),
      );

      await _dataSource.createWithdrawal(withdrawal);

      // Send notification for withdrawal submitted
      await _createNotification(
        userId: userId,
        title: '📤 Withdrawal Submitted',
        message: 'Your withdrawal request of ₹${amount.toStringAsFixed(2)} has been submitted and is pending review.',
        type: NotificationType.withdrawal,
      );
      await _sendFcmTargetedPush(
        userId: userId,
        title: '📤 Withdrawal Submitted',
        message: 'Your withdrawal request of ₹${amount.toStringAsFixed(2)} has been submitted and is pending review.',
        type: 'withdrawal',
      );

      return withdrawal;
    } on WithdrawalException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to request withdrawal: $e');
    }
  }

  @override
  Future<List<WithdrawalEntity>> getWithdrawalHistory(String userId,
      {int limit = 20}) async {
    try {
      return await _dataSource.getUserWithdrawals(userId, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get withdrawal history: $e');
    }
  }

  @override
  Future<WithdrawalEntity?> getWithdrawal(String withdrawalId) async {
    try {
      return await _dataSource.getWithdrawal(withdrawalId);
    } catch (e) {
      throw FirestoreException('Failed to get withdrawal: $e');
    }
  }

  @override
  Stream<List<WithdrawalEntity>> streamUserWithdrawals(String userId) {
    return _dataSource.streamUserWithdrawals(userId);
  }

  @override
  Future<bool> hasPendingWithdrawal(String userId) async {
    try {
      return await _dataSource.hasPendingWithdrawal(userId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> validateWithdrawalRules({
    required String userId,
    required double amount,
  }) async {
    if (amount < minWithdrawalAmount) {
      throw WithdrawalException(
          'Minimum withdrawal amount is ₹${minWithdrawalAmount.toStringAsFixed(2)}');
    }
  }

  @override
  Future<List<WithdrawalEntity>> getAllWithdrawals({
    WithdrawalStatus? status,
    int limit = 50,
  }) async {
    try {
      return await _dataSource.getAllWithdrawals(status: status, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get all withdrawals: $e');
    }
  }

  @override
  Stream<List<WithdrawalEntity>> streamAllWithdrawals({
    WithdrawalStatus? status,
  }) {
    return _dataSource.streamAllWithdrawals(status: status);
  }

  @override
  Future<WithdrawalEntity> markAsPaid(
    String withdrawalId, {
    String? remarks,
    String? transactionId,
  }) async {
    try {
      final existing = await _dataSource.getWithdrawal(withdrawalId);
      if (existing == null) {
        throw FirestoreException('Withdrawal not found');
      }
      if (existing.status != WithdrawalStatus.pending) {
        throw WithdrawalException('Withdrawal is not in pending status');
      }

      // Check balance before processing
      final wallet = await _walletDataSource.getWallet(existing.userId);
      if (wallet == null) {
        throw WithdrawalException('Wallet not found');
      }
      if (wallet.walletBalance < existing.amount) {
        throw WithdrawalException('Insufficient balance to process withdrawal');
      }

      // Deduct from wallet
      await _walletDataSource.updateWalletBalance(
        userId: existing.userId,
        amountChange: -existing.amount,
        earningsChange: 0,
        withdrawnChange: existing.amount,
      );

      // Create debit transaction
      final txnId = transactionId ?? _uuid.v4();
      final transaction = TransactionModel(
        transactionId: txnId,
        userId: existing.userId,
        type: TransactionType.debit,
        amount: existing.amount,
        source: TransactionSource.withdrawal,
        status: TransactionStatus.completed,
        description:
            'Withdrawal of ₹${existing.amount.toStringAsFixed(2)} via ${existing.method.name}',
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);

      // Update withdrawal status to paid
      final paid = WithdrawalModel(
        withdrawalId: existing.withdrawalId,
        userId: existing.userId,
        amount: existing.amount,
        method: existing.method,
        accountDetails: existing.accountDetails,
        qrCodeUrl: existing.qrCodeUrl,
        userName: existing.userName,
        userEmail: existing.userEmail,
        userPhone: existing.userPhone,
        walletBalanceAtRequest: existing.walletBalanceAtRequest,
        transactionId: txnId,
        status: WithdrawalStatus.paid,
        adminRemarks: remarks,
        requestedAt: existing.requestedAt,
        processedAt: DateTime.now(),
      );
      await _dataSource.updateWithdrawal(paid);

      return paid;
    } on WithdrawalException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to process withdrawal: $e');
    }
  }

  @override
  Future<WithdrawalEntity> approveWithdrawal(
    String withdrawalId, {
    String? remarks,
    String? transactionId,
  }) async {
    try {
      final existing = await _dataSource.getWithdrawal(withdrawalId);
      if (existing == null) {
        throw FirestoreException('Withdrawal not found');
      }
      if (existing.status != WithdrawalStatus.paid && existing.status != WithdrawalStatus.pending) {
        throw WithdrawalException('Withdrawal is not in a processable status');
      }

      final isAlreadyDeducted = existing.status == WithdrawalStatus.paid;
      final txnId = transactionId ?? existing.transactionId ?? _uuid.v4();

      if (!isAlreadyDeducted) {
        // Check balance before approving
        final wallet = await _walletDataSource.getWallet(existing.userId);
        if (wallet == null) {
          throw WithdrawalException('Wallet not found');
        }
        if (wallet.walletBalance < existing.amount) {
          throw WithdrawalException('Insufficient balance to approve withdrawal');
        }

        // Deduct from wallet
        await _walletDataSource.updateWalletBalance(
          userId: existing.userId,
          amountChange: -existing.amount,
          earningsChange: 0,
          withdrawnChange: existing.amount,
        );

        // Create debit transaction
        final transaction = TransactionModel(
          transactionId: txnId,
          userId: existing.userId,
          type: TransactionType.debit,
          amount: existing.amount,
          source: TransactionSource.withdrawal,
          status: TransactionStatus.completed,
          description:
              'Withdrawal of ₹${existing.amount.toStringAsFixed(2)} via ${existing.method.name}',
          createdAt: DateTime.now(),
        );
        await _walletDataSource.createTransaction(transaction);
      }

      // Update withdrawal status
      final approved = WithdrawalModel(
        withdrawalId: existing.withdrawalId,
        userId: existing.userId,
        amount: existing.amount,
        method: existing.method,
        accountDetails: existing.accountDetails,
        qrCodeUrl: existing.qrCodeUrl,
        userName: existing.userName,
        userEmail: existing.userEmail,
        userPhone: existing.userPhone,
        walletBalanceAtRequest: existing.walletBalanceAtRequest,
        transactionId: txnId,
        status: WithdrawalStatus.approved,
        adminRemarks: remarks,
        requestedAt: existing.requestedAt,
        processedAt: DateTime.now(),
      );
      await _dataSource.updateWithdrawal(approved);

      // Send notification for withdrawal approved (in-app + push)
      await _createNotification(
        userId: existing.userId,
        title: '✅ Withdrawal Approved',
        message: 'Your withdrawal request of ₹${existing.amount.toStringAsFixed(2)} has been approved and is being processed.',
        type: NotificationType.withdrawal,
      );
      await _sendFcmTargetedPush(
        userId: existing.userId,
        title: '✅ Withdrawal Approved',
        message: 'Your withdrawal request of ₹${existing.amount.toStringAsFixed(2)} has been approved and is being processed.',
        type: 'withdrawal',
      );

      return approved;
    } on WithdrawalException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to approve withdrawal: $e');
    }
  }

  @override
  Future<WithdrawalEntity> rejectWithdrawal(
    String withdrawalId, {
    required String remarks,
  }) async {
    try {
      final existing = await _dataSource.getWithdrawal(withdrawalId);
      if (existing == null) {
        throw FirestoreException('Withdrawal not found');
      }
      if (existing.status != WithdrawalStatus.pending) {
        throw WithdrawalException('Withdrawal is not in pending status');
      }

      final rejected = WithdrawalModel(
        withdrawalId: existing.withdrawalId,
        userId: existing.userId,
        amount: existing.amount,
        method: existing.method,
        accountDetails: existing.accountDetails,
        qrCodeUrl: existing.qrCodeUrl,
        userName: existing.userName,
        userEmail: existing.userEmail,
        userPhone: existing.userPhone,
        walletBalanceAtRequest: existing.walletBalanceAtRequest,
        transactionId: existing.transactionId,
        status: WithdrawalStatus.rejected,
        adminRemarks: remarks,
        requestedAt: existing.requestedAt,
        processedAt: DateTime.now(),
      );
      await _dataSource.updateWithdrawal(rejected);

      // Send notification for withdrawal rejected (in-app + push)
      await _createNotification(
        userId: existing.userId,
        title: '❌ Withdrawal Rejected',
        message: 'Your withdrawal request of ₹${existing.amount.toStringAsFixed(2)} was rejected. Reason: $remarks',
        type: NotificationType.withdrawal,
      );
      await _sendFcmTargetedPush(
        userId: existing.userId,
        title: '❌ Withdrawal Rejected',
        message: 'Your withdrawal request of ₹${existing.amount.toStringAsFixed(2)} was rejected. Reason: $remarks',
        type: 'withdrawal',
      );

      return rejected;
    } on WithdrawalException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to reject withdrawal: $e');
    }
  }

  // ─── Notification Helpers ───────────────────────────

  /// Send an FCM push notification to the targeted user.
  /// FcmService.sendTargetedPush() already handles errors internally.
  Future<void> _sendFcmTargetedPush({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    await FcmService.sendTargetedPush(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: _uuid.v4(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationDataSource.createNotification(notification);
    } catch (e) {
      debugPrint('Failed to create withdrawal notification: $e');
    }
  }
}
