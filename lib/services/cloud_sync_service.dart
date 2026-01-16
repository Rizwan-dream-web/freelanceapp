import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';

/// CloudSyncService provides background sync from Hive to Firestore
/// This is a singleton service that watches for local changes and syncs them to cloud
class CloudSyncService {
  static CloudSyncService? _instance;
  static bool _isInitialized = false;

  final List<StreamSubscription> _subscriptions = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CloudSyncService._();

  /// Get singleton instance
  static CloudSyncService get instance {
    _instance ??= CloudSyncService._();
    return _instance!;
  }

  /// Initialize the cloud sync service (only once)
  /// Call this after user logs in and cloud migration is complete
  static Future<void> init() async {
    if (_isInitialized) {
      print('[CloudSyncService] Already initialized, skipping');
      return;
    }

    print('[CloudSyncService] Initializing background sync');
    final service = CloudSyncService.instance;
    await service._startListeners();
    _isInitialized = true;
  }

  /// Dispose the cloud sync service
  /// Call this when user logs out
  static Future<void> dispose() async {
    if (!_isInitialized) {
      print('[CloudSyncService] Not initialized, nothing to dispose');
      return;
    }

    print('[CloudSyncService] Disposing background sync');
    final service = CloudSyncService.instance;
    await service._cancelListeners();
    _isInitialized = false;
    _instance = null;
  }

  /// Start listening to all Hive boxes
  Future<void> _startListeners() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('[CloudSyncService] No user authenticated, cannot start listeners');
      return;
    }

    print('[CloudSyncService] Starting listeners for user: $uid');

    // Listen to clients box
    _subscriptions.add(
      Hive.box<Client>(HiveBoxes.clients).watch().listen((event) {
        _syncItem(uid, FirestoreCollections.clients, event);
      }),
    );

    // Listen to projects box
    _subscriptions.add(
      Hive.box<Project>(HiveBoxes.projects).watch().listen((event) {
        _syncItem(uid, FirestoreCollections.projects, event);
      }),
    );

    // Listen to tasks box
    _subscriptions.add(
      Hive.box<TaskItem>(HiveBoxes.tasks).watch().listen((event) {
        _syncItem(uid, FirestoreCollections.tasks, event);
      }),
    );

    // Listen to invoices box
    _subscriptions.add(
      Hive.box<Invoice>(HiveBoxes.invoices).watch().listen((event) {
        _syncItem(uid, FirestoreCollections.invoices, event);
      }),
    );

    // Listen to notes box
    _subscriptions.add(
      Hive.box<Note>(HiveBoxes.notes).watch().listen((event) {
        _syncItem(uid, FirestoreCollections.notes, event);
      }),
    );

    print('[CloudSyncService] Started ${_subscriptions.length} listeners');
  }

  /// Cancel all listeners
  Future<void> _cancelListeners() async {
    print('[CloudSyncService] Cancelling ${_subscriptions.length} listeners');
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Sync a single item to Firestore
  void _syncItem(String uid, String collection, BoxEvent event) async {
    try {
      if (event.deleted) {
        // Delete from Firestore
        print('[CloudSyncService] Deleting $collection/${event.key}');
        await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(collection)
            .doc(event.key.toString())
            .delete();
      } else {
        // Push update to Firestore
        final item = event.value;
        if (item != null) {
          print('[CloudSyncService] Syncing $collection/${event.key}');
          final data = (item as dynamic).toMap() as Map<String, dynamic>;
          await _db
              .collection(FirestoreCollections.users)
              .doc(uid)
              .collection(collection)
              .doc(event.key.toString())
              .set(data..['uid'] = uid, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('[CloudSyncService] Error syncing $collection: $e');
      // TODO: Add to retry queue (Phase 3 enhancement)
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
}
