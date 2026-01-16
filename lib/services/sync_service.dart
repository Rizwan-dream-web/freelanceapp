import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import '../repositories/repository_manager.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // 1. Check if migration is needed
  bool get needsMigration {
    return !(repositoryManager.settings.get(SettingsKeys.isCloudMigrated, defaultValue: false) as bool);
  }

  // 2. Perform Migration (Hive -> Firestore)
  Future<void> performInitialMigration() async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();

    // Migrate Clients
    final clientBox = Hive.box<Client>(HiveBoxes.clients);
    for (var client in clientBox.values) {
      final docRef = _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.clients).doc(client.id);
      batch.set(docRef, client.toMap()..['uid'] = uid);
    }

    // Migrate Projects
    final projectBox = Hive.box<Project>(HiveBoxes.projects);
    for (var project in projectBox.values) {
      final docRef = _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.projects).doc(project.id);
      batch.set(docRef, project.toMap()..['uid'] = uid);
    }

    // Migrate Tasks
    final taskBox = Hive.box<TaskItem>(HiveBoxes.tasks);
    for (var task in taskBox.values) {
      final docRef = _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.tasks).doc(task.id);
      batch.set(docRef, task.toMap()..['uid'] = uid);
    }

    // Migrate Invoices
    final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);
    for (var invoice in invoiceBox.values) {
      final docRef = _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.invoices).doc(invoice.id);
      batch.set(docRef, invoice.toMap()..['uid'] = uid);
    }

    // Migrate Notes
    final noteBox = Hive.box<Note>(HiveBoxes.notes);
    for (var note in noteBox.values) {
      final docRef = _db.collection(FirestoreCollections.users).doc(uid).collection(FirestoreCollections.notes).doc(note.id);
      batch.set(docRef, note.toMap()..['uid'] = uid);
    }

    await batch.commit();

    // Mark as migrated
    await repositoryManager.settings.set(SettingsKeys.isCloudMigrated, true);
  }

  // 3. Sync from Cloud to Local (with error recovery)
  /// Performs a safe sync from Firestore to Hive with rollback on failure
  /// Returns a map with success status and error message if failed
  Future<Map<String, dynamic>> syncFromCloud() async {
    final uid = _uid;
    if (uid == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    print('[SyncService] Starting cloud sync for user: $uid');

    // STEP 1: Fetch all data from cloud FIRST (before touching local data)
    Map<String, List<Map<String, dynamic>>> cloudData = {};

    try {
      print('[SyncService] Fetching data from Firestore...');

      cloudData['clients'] = await _fetchCollection(uid, FirestoreCollections.clients);
      cloudData['projects'] = await _fetchCollection(uid, FirestoreCollections.projects);
      cloudData['invoices'] = await _fetchCollection(uid, FirestoreCollections.invoices);
      cloudData['tasks'] = await _fetchCollection(uid, FirestoreCollections.tasks);
      cloudData['notes'] = await _fetchCollection(uid, FirestoreCollections.notes);

      final totalItems = cloudData.values.fold(0, (sum, list) => sum + list.length);
      print('[SyncService] Fetched $totalItems items from cloud');
    } catch (e) {
      print('[SyncService] ERROR: Failed to fetch cloud data: $e');
      return {'success': false, 'error': 'Failed to fetch cloud data: $e'};
    }

    // STEP 2: Create in-memory backup of current local data
    print('[SyncService] Creating local backup...');
    Map<String, List<dynamic>> backup;
    try {
      backup = await _createLocalBackup();
      final backupSize = backup.values.fold(0, (sum, list) => sum + list.length);
      print('[SyncService] Backed up $backupSize local items');
    } catch (e) {
      print('[SyncService] ERROR: Failed to create backup: $e');
      return {'success': false, 'error': 'Failed to create backup: $e'};
    }

    // STEP 3: Clear local data
    print('[SyncService] Clearing local data...');
    try {
      await Hive.box<Client>(HiveBoxes.clients).clear();
      await Hive.box<Project>(HiveBoxes.projects).clear();
      await Hive.box<Invoice>(HiveBoxes.invoices).clear();
      await Hive.box<TaskItem>(HiveBoxes.tasks).clear();
      await Hive.box<Note>(HiveBoxes.notes).clear();
      print('[SyncService] Local data cleared');
    } catch (e) {
      print('[SyncService] ERROR: Failed to clear local data, restoring backup...');
      await _restoreLocalBackup(backup);
      return {'success': false, 'error': 'Failed to clear local data: $e'};
    }

    // STEP 4: Restore cloud data to local
    print('[SyncService] Restoring cloud data to local storage...');
    try {
      await _restoreCloudData(cloudData);
      final restoredCount = cloudData.values.fold(0, (sum, list) => sum + list.length);
      print('[SyncService] ✓ Successfully synced $restoredCount items from cloud');
      return {'success': true, 'itemsCount': restoredCount};
    } catch (e) {
      print('[SyncService] ERROR: Failed to restore cloud data, rolling back...');
      // ROLLBACK: Restore from backup
      await _restoreLocalBackup(backup);
      print('[SyncService] Rollback completed - local data restored');
      return {'success': false, 'error': 'Failed to restore cloud data, rollback successful: $e'};
    }
  }

  /// Fetch all documents from a Firestore collection
  Future<List<Map<String, dynamic>>> _fetchCollection(String uid, String collection) async {
    final snapshot = await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(collection)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data.remove('uid'); // Remove uid field before storing locally
      return data;
    }).toList();
  }

  /// Create in-memory backup of all local Hive data
  Future<Map<String, List<dynamic>>> _createLocalBackup() async {
    return {
      'clients': Hive.box<Client>(HiveBoxes.clients).values.toList(),
      'projects': Hive.box<Project>(HiveBoxes.projects).values.toList(),
      'invoices': Hive.box<Invoice>(HiveBoxes.invoices).values.toList(),
      'tasks': Hive.box<TaskItem>(HiveBoxes.tasks).values.toList(),
      'notes': Hive.box<Note>(HiveBoxes.notes).values.toList(),
    };
  }

  /// Restore local data from backup (used for rollback)
  Future<void> _restoreLocalBackup(Map<String, List<dynamic>> backup) async {
    // Restore clients
    final clientBox = Hive.box<Client>(HiveBoxes.clients);
    await clientBox.clear();
    for (var client in backup['clients'] as List<Client>) {
      await clientBox.put(client.id, client);
    }

    // Restore projects
    final projectBox = Hive.box<Project>(HiveBoxes.projects);
    await projectBox.clear();
    for (var project in backup['projects'] as List<Project>) {
      await projectBox.put(project.id, project);
    }

    // Restore invoices
    final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);
    await invoiceBox.clear();
    for (var invoice in backup['invoices'] as List<Invoice>) {
      await invoiceBox.put(invoice.id, invoice);
    }

    // Restore tasks
    final taskBox = Hive.box<TaskItem>(HiveBoxes.tasks);
    await taskBox.clear();
    for (var task in backup['tasks'] as List<TaskItem>) {
      await taskBox.put(task.id, task);
    }

    // Restore notes
    final noteBox = Hive.box<Note>(HiveBoxes.notes);
    await noteBox.clear();
    for (var note in backup['notes'] as List<Note>) {
      await noteBox.put(note.id, note);
    }
  }

  /// Restore cloud data to local Hive storage
  Future<void> _restoreCloudData(Map<String, List<Map<String, dynamic>>> cloudData) async {
    // Restore clients
    final clientBox = Hive.box<Client>(HiveBoxes.clients);
    for (var data in cloudData['clients']!) {
      final client = Client.fromMap(data);
      await clientBox.put(client.id, client);
    }

    // Restore projects
    final projectBox = Hive.box<Project>(HiveBoxes.projects);
    for (var data in cloudData['projects']!) {
      final project = Project.fromMap(data);
      await projectBox.put(project.id, project);
    }

    // Restore invoices
    final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);
    for (var data in cloudData['invoices']!) {
      final invoice = Invoice.fromMap(data);
      await invoiceBox.put(invoice.id, invoice);
    }

    // Restore tasks
    final taskBox = Hive.box<TaskItem>(HiveBoxes.tasks);
    for (var data in cloudData['tasks']!) {
      final task = TaskItem.fromMap(data);
      await taskBox.put(task.id, task);
    }

    // Restore notes
    final noteBox = Hive.box<Note>(HiveBoxes.notes);
    for (var data in cloudData['notes']!) {
      final note = Note.fromMap(data);
      await noteBox.put(note.id, note);
    }
  }

  // 4. Background Sync (Future Proofing)
  // This will be expanded in v4.1 for real-time bi-directional sync
  Future<void> pushUpdate(String collection, String id, Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection(FirestoreCollections.users).doc(uid).collection(collection).doc(id).set(data..['uid'] = uid, SetOptions(merge: true));
    } catch (e) {
      print('Warning: Could not push update to cloud: $e');
    }
  }
}
