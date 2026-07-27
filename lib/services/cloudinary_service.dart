import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class CloudinaryService {
  final CloudinaryPublic _cloudinary;
  static CloudinaryService? _instance;

  CloudinaryService._(String cloudName, String uploadPreset)
      : _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  /// Initialize the singleton with your Cloudinary cloud name and unsigned upload preset.
  /// Call once at app startup (e.g., in main.dart).
  static void initialize({
    required String cloudName,
    required String uploadPreset,
  }) {
    _instance = CloudinaryService._(cloudName, uploadPreset);
  }

  /// Get the singleton instance. Throws [StateError] if not initialized.
  static CloudinaryService get instance {
    if (_instance == null) {
      throw StateError(
        'CloudinaryService not initialized. Call CloudinaryService.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Upload a screenshot (Uint8List) to Cloudinary and return the secure URL.
  /// Returns null on failure.
  Future<String?> uploadScreenshot({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final byteData = ByteData.view(imageBytes.buffer, 0, imageBytes.length);
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          byteData,
          identifier: fileName,
          resourceType: CloudinaryResourceType.Image,
          folder: 'task_proofs',
        ),
      );
      debugPrint('Cloudinary upload success: ${response.secureUrl}');
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint('Cloudinary upload failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}
