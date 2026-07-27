import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class NotificationFirestoreDataSource {
  final FirebaseFirestore _firestore;

  NotificationFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<void> createNotification(NotificationModel notification) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notification.notificationId)
        .set(notification.toFirestore());
  }

  Future<List<NotificationModel>> getNotifications(String userId,
      {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final notifications = query.docs
          .map((doc) => _safeParseNotification(doc.data()))
          .whereType<NotificationModel>()
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(limit).toList();
    } catch (e) {
      debugPrint('getNotifications error: $e');
      return [];
    }
  }

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => _safeParseNotification(doc.data()))
          .whereType<NotificationModel>()
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(50).toList();
    });
  }

  /// Safely parse a Firestore document into a [NotificationModel], returning
  /// null if the data is malformed or missing required fields. Invalid documents
  /// are silently skipped so a single bad document doesn't crash the entire
  /// notifications stream.
  NotificationModel? _safeParseNotification(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      return NotificationModel.fromFirestore(data);
    } catch (e) {
      debugPrint('NotificationFirestoreDataSource: skipping invalid doc: $e');
      return null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final query = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in query.docs) {
        if (doc.data()['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      if (query.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .delete();
  }

  Future<void> clearAll(String userId) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    if (query.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        if (doc.data()['isRead'] == false) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('getUnreadCount error: $e');
      return 0;
    }
  }

  // FCM Tokens stored in user document or fcm_tokens subcollection
  Future<void> saveFcmToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  Future<String?> getFcmToken(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data()!['fcmToken'] as String?;
  }
}
