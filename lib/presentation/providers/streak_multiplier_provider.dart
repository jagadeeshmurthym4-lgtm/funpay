import 'package:cashspark/domain/entities/streak_multiplier_entity.dart';
import 'package:cashspark/domain/repositories/streak_multiplier_repository.dart';
import 'package:flutter/foundation.dart';

class StreakMultiplierProvider extends ChangeNotifier {
  final StreakMultiplierRepository _repository;

  StreakMultiplierConfigEntity? _config;
  bool _isLoading = false;
  String? _errorMessage;

  StreakMultiplierProvider({
    required StreakMultiplierRepository repository,
  }) : _repository = repository;

  StreakMultiplierConfigEntity? get config => _config;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEnabled => _config?.isEnabled ?? true;
  bool get streakRecoveryEnabled => _config?.streakRecoveryEnabled ?? true;
  List<StreakMilestoneEntity> get milestones => _config?.milestones ?? [];

  /// Get the current multiplier for a given streak day count.
  double getMultiplierForStreak(int streakDays) {
    if (_config == null) return 1.0;
    double multiplier = 1.0;
    if (!_config!.isEnabled) return multiplier;

    final sorted = [...milestones]
      ..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));

    for (final milestone in sorted) {
      if (!milestone.isActive) continue;
      if (streakDays >= milestone.targetStreakDays) {
        multiplier = milestone.multiplier;
      }
    }
    return multiplier;
  }

  /// Get the next streak milestone the user hasn't reached yet.
  StreakMilestoneEntity? getNextMilestone(int currentStreak) {
    if (_config == null) return null;
    final sorted = [...milestones]
      ..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));
    for (final m in sorted) {
      if (m.isActive && currentStreak < m.targetStreakDays) return m;
    }
    return null;
  }

  /// Get the highest active milestone reached.
  StreakMilestoneEntity? getCurrentMilestone(int currentStreak) {
    StreakMilestoneEntity? current;
    final sorted = [...milestones]
      ..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));
    for (final m in sorted) {
      if (m.isActive && currentStreak >= m.targetStreakDays) {
        current = m;
      }
    }
    return current;
  }

  Future<void> loadConfig() async {
    _setLoading(true);
    _clearError();
    try {
      _config = await _repository.getConfig();
    } catch (e) {
      _errorMessage = 'Failed to load streak multiplier config';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveConfig(StreakMultiplierConfigEntity newConfig) async {
    _setLoading(true);
    _clearError();
    try {
      await _repository.saveConfig(newConfig);
      _config = newConfig;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save streak multiplier config';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
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
