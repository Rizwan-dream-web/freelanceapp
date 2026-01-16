import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class SecurityService {
  static const List<String> _boxesToBackup = [
    'clients',
    'proposals',
    'projects',
    'tasks',
    'invoices',
    'settings',
    'notes',
  ];

  static Future<String> generateBackupJson() async {
    final Map<String, dynamic> backupData = {};

    for (final boxName in _boxesToBackup) {
      try {
        final box = Hive.box(boxName);
        // We convert the box values to a list of maps
        // Since our models are HiveObjects, we use their existing toMap or similar logic if available, 
        // but for standard Hive types, we can just iterate.
        backupData[boxName] = box.values.toList();
      } catch (e) {
        if (e.toString().contains('already open')) {
          print('Box $boxName already open during backup, skipping');
          backupData[boxName] = [];
        } else {
          rethrow;
        }
      }
    }

    return jsonEncode(backupData);
  }

  static Future<void> restoreFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    for (final entry in data.entries) {
      final boxName = entry.key;
      final List<dynamic> items = entry.value;

      if (_boxesToBackup.contains(boxName)) {
        try {
          final box = Hive.box(boxName);
          await box.clear();
        
        for (final item in items) {
          // Re-insert based on ID if available
          if (item is Map && item.containsKey('id')) {
            await box.put(item['id'], _castToModel(boxName, item));
          } else {
            await box.add(_castToModel(boxName, item));
          }
        }
        } catch (e) {
          if (e.toString().contains('already open')) {
            print('Box $boxName already open during restore, skipping');
          } else {
            rethrow;
          }
        }
      }
    }
  }

  static dynamic _castToModel(String boxName, dynamic data) {
    if (data is! Map) return data;
    final map = Map<String, dynamic>.from(data);
    
    switch (boxName) {
      case 'clients': return Client.fromMap(map);
      case 'proposals': return Proposal.fromMap(map);
      case 'projects': return Project.fromMap(map);
      case 'tasks': return TaskItem.fromMap(map);
      case 'invoices': return Invoice.fromMap(map);
      case 'notes': return Note.fromMap(map);
      case 'settings': return map; // Settings is usually a simple map
      default: return data;
    }
  }
}
