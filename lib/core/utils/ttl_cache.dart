/// A simple in-memory cache with time-to-live (TTL) expiry.
/// Useful for caching Firestore list data to reduce reads.
class TtlCache<T> {
  final Duration _ttl;
  final Map<String, _CacheEntry<T>> _store = {};

  TtlCache({Duration? ttl}) : _ttl = ttl ?? const Duration(minutes: 5);

  /// Retrieve a value from cache. Returns null if not found or expired.
  T? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Store a value in cache with the configured TTL.
  void set(String key, T value) {
    _store[key] = _CacheEntry(value, _ttl);
  }

  /// Remove a specific key from cache.
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Clear all cached entries.
  void clear() {
    _store.clear();
  }

  /// Number of valid (non-expired) entries.
  int get validCount => _store.values.where((e) => !e.isExpired).length;

  /// Clean up expired entries.
  void purgeExpired() {
    _store.removeWhere((_, entry) => entry.isExpired);
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime _expiresAt;

  _CacheEntry(this.value, Duration ttl) : _expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(_expiresAt);
}
