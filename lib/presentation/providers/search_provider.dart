import 'dart:async';
import 'package:cashspark/domain/entities/offer_entity.dart';
import 'package:cashspark/domain/entities/project_entity.dart';
import 'package:cashspark/domain/repositories/offer_repository.dart';
import 'package:cashspark/domain/repositories/project_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Category filter for search results
enum SearchCategory { all, offers, projects }

/// Time-based filter for search results
enum SearchTimeFilter { allTime, today, thisWeek, thisMonth }

/// A single search result item (unified across offers, projects, tasks)
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'offer', 'project', 'task'
  final String? category;
  final String? reward;
  final double? rewardAmount;
  final String? iconName;
  final int colorValue;
  final DateTime? date;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.category,
    this.reward,
    this.rewardAmount,
    this.iconName,
    this.colorValue = 0xFF4ADE80,
    this.date,
  });
}

class SearchProvider extends ChangeNotifier {
  final OfferRepository? _offerRepository;
  final ProjectRepository? _projectRepository;
  // Data pools
  List<OfferEntity> _allOffers = [];
  List<ProjectEntity> _allProjects = [];

  // Search state
  String _query = '';
  bool _isLoading = false;
  List<SearchResult> _results = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  SearchCategory _categoryFilter = SearchCategory.all;
  SearchTimeFilter _timeFilter = SearchTimeFilter.allTime;
  double _minReward = 0;
  double _maxReward = 999999;
  bool _showFilters = false;

  // Debounce timer
  Timer? _debounce;

  SearchProvider({
    OfferRepository? offerRepository,
    ProjectRepository? projectRepository,
  })  : _offerRepository = offerRepository,
        _projectRepository = projectRepository;

  // ─── Getters ─────────────────────────────────────────────
  String get query => _query;
  bool get isLoading => _isLoading;
  List<SearchResult> get results => _results;
  List<String> get searchHistory => _searchHistory;
  List<String> get suggestions => _suggestions;
  SearchCategory get categoryFilter => _categoryFilter;
  SearchTimeFilter get timeFilter => _timeFilter;
  double get minReward => _minReward;
  double get maxReward => _maxReward;
  bool get showFilters => _showFilters;

  static const List<String> popularSearches = [
    'Watch ads',
    'Daily check-in',
    'Spin & win',
    'Refer friends',
    'Complete tasks',
    'Top projects',
    'Bonus offers',
    'Instant withdrawal',
  ];

  // ─── Data Loading ────────────────────────────────────────
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Future> futures = [];
      final OfferRepository? offerRepo = _offerRepository;
      final ProjectRepository? projectRepo = _projectRepository;

      if (offerRepo != null) futures.add(offerRepo.getAllOffers());
      if (projectRepo != null) futures.add(projectRepo.getAllProjects());

      if (futures.isEmpty) return;

      final results = await Future.wait(futures);

      if (results.isNotEmpty && offerRepo != null) _allOffers = results[0] as List<OfferEntity>;
      if (results.length >= 2 && projectRepo != null) _allProjects = results[1] as List<ProjectEntity>;
    } catch (_) {
      // Silently handle — empty data fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Search History (SharedPreferences) ──────────────────
  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    notifyListeners();
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.sublist(0, 20);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', []);
    notifyListeners();
  }

  Future<void> removeSearchItem(int index) async {
    if (index < _searchHistory.length) {
      _searchHistory.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
      notifyListeners();
    }
  }

  // ─── Search ──────────────────────────────────────────────
  void onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });

    // Update suggestions in real-time
    if (value.length >= 2) {
      _suggestions = _generateSuggestions(value);
    } else {
      _suggestions = [];
    }
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    _performSearch();
  }

  void _performSearch() {
    if (_query.trim().isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _saveToHistory(_query.trim());
    _results = _executeSearch(_query.trim());
    notifyListeners();
  }

  List<SearchResult> _executeSearch(String query) {
    final lowerQuery = query.toLowerCase();
    final List<SearchResult> results = [];

    // Search offers
    if (_categoryFilter == SearchCategory.all ||
        _categoryFilter == SearchCategory.offers) {
      for (final offer in _allOffers) {
        if (!offer.isActive) continue;
        if (offer.title.toLowerCase().contains(lowerQuery) ||
            offer.subtitle.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResult(
            id: offer.offerId,
            title: offer.title,
            subtitle: offer.subtitle,
            type: 'offer',
            category: 'Offer',
            reward: offer.reward,
            iconName: offer.iconName,
            colorValue: offer.colorValue,
            date: offer.createdAt,
          ));
        }
      }
    }

    // Search projects
    if (_categoryFilter == SearchCategory.all ||
        _categoryFilter == SearchCategory.projects) {
      for (final project in _allProjects) {
        if (!project.isActive) continue;
        if (project.name.toLowerCase().contains(lowerQuery) ||
            project.description.toLowerCase().contains(lowerQuery) ||
            project.category.toLowerCase().contains(lowerQuery)) {
          final reward = project.rewardAmount;
          if (reward < _minReward || reward > _maxReward) {
            continue;
          }
          if (_timeFilter != SearchTimeFilter.allTime &&
              !_matchesTimeFilter(project.createdAt)) {
            continue;
          }

          results.add(SearchResult(
            id: project.projectId,
            title: project.name,
            subtitle: project.description,
            type: 'project',
            category: project.category,
            reward: project.reward,
            rewardAmount: project.rewardAmount,
            iconName: project.iconName,
            colorValue: project.colorValue,
            date: project.createdAt,
          ));
        }
      }
    }

    // Sort by relevance (title match first, then category match)
    results.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();
      final aExact = aTitle == lowerQuery ? 0 : 1;
      final bExact = bTitle == lowerQuery ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);
      final aStarts = aTitle.startsWith(lowerQuery) ? 0 : 1;
      final bStarts = bTitle.startsWith(lowerQuery) ? 0 : 1;
      return aStarts.compareTo(bStarts);
    });

    return results;
  }

  List<String> _generateSuggestions(String query) {
    final lower = query.toLowerCase();
    final Set<String> suggestions = {};

    // Add from popular searches
    for (final s in popularSearches) {
      if (s.toLowerCase().contains(lower)) {
        suggestions.add(s);
      }
    }
    // Add from offers
    for (final offer in _allOffers) {
      if (offer.title.toLowerCase().contains(lower)) {
        suggestions.add(offer.title);
      }
    }
    // Add from projects
    for (final project in _allProjects) {
      if (project.name.toLowerCase().contains(lower)) {
        suggestions.add(project.name);
      }
    }

    return suggestions.take(8).toList();
  }

  bool _matchesTimeFilter(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_timeFilter) {
      case SearchTimeFilter.allTime:
        return true;
      case SearchTimeFilter.today:
        final d = DateTime(date.year, date.month, date.day);
        return d == today;
      case SearchTimeFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart);
      case SearchTimeFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return date.isAfter(monthStart);
    }
  }

  // ─── Filters ─────────────────────────────────────────────
  void setCategoryFilter(SearchCategory category) {
    _categoryFilter = category;
    if (_query.isNotEmpty) _performSearch();
    notifyListeners();
  }

  void setTimeFilter(SearchTimeFilter filter) {
    _timeFilter = filter;
    if (_query.isNotEmpty) _performSearch();
    notifyListeners();
  }

  void setRewardRange(double min, double max) {
    _minReward = min;
    _maxReward = max;
    if (_query.isNotEmpty) _performSearch();
    notifyListeners();
  }

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = SearchCategory.all;
    _timeFilter = SearchTimeFilter.allTime;
    _minReward = 0;
    _maxReward = 999999;
    _showFilters = false;
    if (_query.isNotEmpty) _performSearch();
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _results = [];
    _suggestions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
