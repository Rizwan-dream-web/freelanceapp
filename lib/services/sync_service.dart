import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // 1. Check if migration is needed
  bool get needsMigration {
    final box = Hive.box('settings');
    return !(box.get('isCloudMigrated', defaultValue: false) as bool);
  }

  // 2. Perform Migration (Hive -> Firestore)
  Future<void> performInitialMigration() async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();

    // Migrate Clients
    final clientBox = Hive.box<Client>('clients');
    for (var client in clientBox.values) {
      final docRef = _db.collection('users').doc(uid).collection('clients').doc(client.id);
      batch.set(docRef, client.toMap()..['uid'] = uid);
    }

    // Migrate Projects
    final projectBox = Hive.box<Project>('projects');
    for (var project in projectBox.values) {
      final docRef = _db.collection('users').doc(uid).collection('projects').doc(project.id);
      batch.set(docRef, project.toMap()..['uid'] = uid);
    }

    // Migrate Tasks
    final taskBox = Hive.box<TaskItem>('tasks');
    for (var task in taskBox.values) {
      final docRef = _db.collection('users').doc(uid).collection('tasks').doc(task.id);
      batch.set(docRef, task.toMap()..['uid'] = uid);
    }

    // Migrate Invoices
    final invoiceBox = Hive.box<Invoice>('invoices');
    for (var invoice in invoiceBox.values) {
      final docRef = _db.collection('users').doc(uid).collection('invoices').doc(invoice.id);
      batch.set(docRef, invoice.toMap()..['uid'] = uid);
    }

    // Migrate Notes
    final noteBox = Hive.box<Note>('notes');
    for (var note in noteBox.values) {
      final docRef = _db.collection('users').doc(uid).collection('notes').doc(note.id);
      batch.set(docRef, note.toMap()..['uid'] = uid);
    }

    await batch.commit();

    // Mark as migrated
    await Hive.box('settings').put('isCloudMigrated', true);
  }

  // 3. Background Sync (Future Proofing)
  // This will be expanded in v4.1 for real-time bi-directional sync
  Future<void> pushUpdate(String collection, String id, Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection(collection).doc(id).set(data..['uid'] = uid, SetOptions(merge: true));
  }
}
