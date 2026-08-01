import 'package:flutter/material.dart';
import 'dart:math';

class Helpers {
  Helpers._();

  /// Maps a string icon name to an Icons constant.
  /// Used to store icon references in Firestore documents.
  static IconData iconFromString(String name) {
    switch (name) {
      case 'download':
        return Icons.download_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'play_circle':
        return Icons.play_circle_outline;
      case 'checklist':
        return Icons.checklist_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'videocam':
        return Icons.videocam_outlined;
      case 'thumb_up':
        return Icons.thumb_up_outlined;
      case 'person_add':
        return Icons.person_add_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'directions_walk':
        return Icons.directions_walk_outlined;
      case 'extension':
        return Icons.extension_outlined;
      case 'music_note':
        return Icons.music_note_outlined;
      case 'stars':
        return Icons.stars_outlined;
      case 'app_shortcut':
        return Icons.app_shortcut_outlined;
      default:
        return Icons.stars_outlined;
    }
  }

  static String generateReferralCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} pts';
  }

  static String formatNumber(dynamic number) {
    final n = (number is num) ? number.toInt() : 0;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    if (name.length <= 2) return '${name[0]}***@${parts[1]}';
    return '${name[0]}${name[1]}***@${parts[1]}';
  }

  static T? safeCast<T>(dynamic value) {
    if (value is T) return value;
    return null;
  }
}
