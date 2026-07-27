import 'package:cashspark/domain/entities/streak_multiplier_entity.dart';

abstract class StreakMultiplierRepository {
  /// Get the current streak multiplier configuration.
  Future<StreakMultiplierConfigEntity> getConfig();

  /// Save the multiplier configuration.
  Future<void> saveConfig(StreakMultiplierConfigEntity config);
}
