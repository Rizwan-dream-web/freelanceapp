import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'base_repository.dart';

/// Hive-based implementation of the base repository
///
/// This class provides a concrete implementation of BaseRepository using Hive
/// for local data persistence. It handles all CRUD operations and provides
/// reactive streams for UI updates.
abstract class HiveRepository<T> implements BaseRepository<T> {
  /// The Hive box name for this repository
  String get boxName;

  /// Convert an item to a map for storage (if needed for adapters)
  Map<String, dynamic>? toMap(T item) => null;

  /// Convert a map back to an item (if needed for adapters)
  T? fromMap(Map<String, dynamic> map) => null;

  /// Get the Hive box for this repository
  Box get box {
    // First check if box is already open
    if (Hive.isBoxOpen(boxName)) {
      try {
        return Hive.box<T>(boxName);
      } catch (e) {
        // If there's still an error even though box is open,
        // there might be a type mismatch or corruption
        print('Box $boxName is open but inaccessible: $e');
        rethrow;
      }
    }

    // Box is not open - this should not happen in normal operation
    // since boxes are opened in main.dart
    throw StateError('Box $boxName is not open. Make sure HiveService.init() is called before accessing repositories.');
  }

  // Stream needs to start with current data to avoid waiting for a change event
  @override
  Stream<List<T>> getAll() async* {
    yield _getAllItems();
    yield* box.watch().map((event) => _getAllItems());
  }

  @override
  Future<List<T>> getAllOnce() async {
    return _getAllItems();
  }

  @override
  List<T> getAllSync() {
    return _getAllItems();
  }

  @override
  Future<T?> getById(String id) async {
    final item = box.get(id);
    if (item == null) return null;

    // If item is already of type T, return it
    if (item is T) return item;

    // If we have a fromMap converter, use it
    if (fromMap != null && item is Map<String, dynamic>) {
      return fromMap!(item);
    }

    // Try to cast directly
    try {
      return item as T;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(T item) async {
    // For items with IDs, use the ID as key
    if (item is dynamic && item.id != null) {
      await box.put(item.id, item);
    } else {
      // For items without IDs, generate one
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(id, item);
    }
  }

  @override
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  @override
  Future<bool> exists(String id) async {
    return box.containsKey(id);
  }

  @override
  Future<int> count() async {
    return box.length;
  }

  @override
  Future<void> clear() async {
    await box.clear();
  }

  @override
  Future<List<T>> search(String query) async {
    final allItems = _getAllItems();
    final lowercaseQuery = query.toLowerCase();

    return allItems.where((item) {
      // Search in common fields
      if (item is dynamic) {
        final searchableText = _getSearchableText(item);
        return searchableText.toLowerCase().contains(lowercaseQuery);
      }
      return false;
    }).toList();
  }

  @override
  Future<List<T>> getPaginated({int limit = 20, int offset = 0}) async {
    final allItems = _getAllItems();
    final start = offset;
    final end = (offset + limit).clamp(0, allItems.length);

    if (start >= allItems.length) return [];

    return allItems.sublist(start, end);
  }

  /// Get all items from the box
  List<T> _getAllItems() {
    return box.values.whereType<T>().toList();
  }

  /// Extract searchable text from an item
  String _getSearchableText(dynamic item) {
    final buffer = StringBuffer();

    // Try common fields that might contain searchable text
    if (item.name != null) buffer.write(item.name);
    if (item.title != null) buffer.write(' ${item.title}');
    if (item.description != null) buffer.write(' ${item.description}');
    if (item.notes != null) buffer.write(' ${item.notes}');
    if (item.company != null) buffer.write(' ${item.company}');
    if (item.email != null) buffer.write(' ${item.email}');

    return buffer.toString().trim();
  }
}