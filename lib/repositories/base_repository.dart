/// Base repository interface defining common data operations
///
/// This abstract class provides a consistent interface for all data repositories
/// in the application, ensuring clean architecture and testability.
abstract class BaseRepository<T> {
  /// Get all items as a stream for reactive UI updates
  Stream<List<T>> getAll();

  /// Get all items as a future for one-time operations
  Future<List<T>> getAllOnce();

  /// Get all items synchronously (requires loaded data source)
  List<T> getAllSync();

  /// Get a single item by ID
  Future<T?> getById(String id);

  /// Add or update an item
  Future<void> save(T item);

  /// Delete an item by ID
  Future<void> delete(String id);

  /// Check if an item exists by ID
  Future<bool> exists(String id);

  /// Get the count of items
  Future<int> count();

  /// Clear all items
  Future<void> clear();

  /// Search items by query
  Future<List<T>> search(String query);

  /// Get items with pagination
  Future<List<T>> getPaginated({int limit = 20, int offset = 0});
}

/// Repository result wrapper for operations that might fail
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const RepositoryResult.success(T data)
      : data = data,
        error = null,
        success = true;

  const RepositoryResult.error(String error)
      : data = null,
        error = error,
        success = false;

  bool get hasError => !success;
  bool get hasData => success && data != null;
}

/// Extension methods for easier repository result handling
extension RepositoryResultExtensions<T> on RepositoryResult<T> {
  /// Execute callback if successful
  void onSuccess(void Function(T data) callback) {
    if (success && data != null) {
      callback(data!);
    }
  }

  /// Execute callback if failed
  void onError(void Function(String error) callback) {
    if (!success && error != null) {
      callback(error!);
    }
  }

  /// Transform successful result
  RepositoryResult<R> map<R>(R Function(T data) transform) {
    if (success && data != null) {
      return RepositoryResult.success(transform(data!));
    } else {
      return RepositoryResult.error(error ?? 'Unknown error');
    }
  }
}