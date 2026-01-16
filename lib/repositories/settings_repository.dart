import 'hive_repository.dart';

/// Repository for app settings
class SettingsRepository extends HiveRepository<dynamic> {
  @override
  String get boxName => 'settings';

  /// Get a setting value
  dynamic get(String key, {dynamic defaultValue}) {
    try {
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      print('Error getting setting $key: $e');
      return defaultValue;
    }
  }

  /// Set a setting value
  Future<void> set(String key, dynamic value) async {
    try {
      await box.put(key, value);
    } catch (e) {
      print('Error setting $key: $e');
      rethrow;
    }
  }

  /// Get all settings
  Map<dynamic, dynamic> getAllSettings() {
    try {
      return Map<dynamic, dynamic>.from(box.toMap());
    } catch (e) {
      print('Error getting all settings: $e');
      return {};
    }
  }

  /// Get a stream of changes for specific keys
  Stream<dynamic> watch({List<String>? keys}) {
    try {
      if (keys != null && keys.isNotEmpty) {
        return box.watch(key: keys.first).map((event) => event.value);
      }
      return box.watch().map((event) => event.value);
    } catch (e) {
      print('Error watching settings: $e');
      return Stream.empty();
    }
  }
}