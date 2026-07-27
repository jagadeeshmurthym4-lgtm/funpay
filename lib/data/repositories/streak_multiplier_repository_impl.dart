import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/streak_multiplier_firestore_datasource.dart';
import 'package:cashspark/data/models/streak_multiplier_model.dart';
import 'package:cashspark/domain/entities/streak_multiplier_entity.dart';
import 'package:cashspark/domain/repositories/streak_multiplier_repository.dart';

class StreakMultiplierRepositoryImpl implements StreakMultiplierRepository {
  final StreakMultiplierFirestoreDataSource _dataSource;

  StreakMultiplierRepositoryImpl({
    required StreakMultiplierFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<StreakMultiplierConfigEntity> getConfig() async {
    try {
      final config = await _dataSource.getConfig();
      if (config == null) {
        return const StreakMultiplierConfigEntity(
          id: 'config',
          milestones: [
            StreakMilestoneEntity(
              id: 'ms1', targetStreakDays: 7, multiplier: 1.2, label: '7-Day Streak', isActive: true,
            ),
            StreakMilestoneEntity(
              id: 'ms2', targetStreakDays: 15, multiplier: 1.3, label: '15-Day Streak', isActive: true,
            ),
            StreakMilestoneEntity(
              id: 'ms3', targetStreakDays: 30, multiplier: 1.5, label: '30-Day Streak', isActive: true,
            ),
            StreakMilestoneEntity(
              id: 'ms4', targetStreakDays: 60, multiplier: 2.0, label: '60-Day Streak', isActive: true,
            ),
          ],
        );
      }
      return config;
    } catch (e) {
      throw FirestoreException('Failed to get streak multiplier config: $e');
    }
  }

  @override
  Future<void> saveConfig(StreakMultiplierConfigEntity config) async {
    try {
      await _dataSource.saveConfig(StreakMultiplierConfigModel.fromEntity(config));
    } catch (e) {
      throw FirestoreException('Failed to save streak multiplier config: $e');
    }
  }
}
