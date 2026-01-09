import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/models.dart';

class CloudSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static void init() {
    // Listen to changes in all relevant boxes
    _listenToBox<Client>('clients');
    _listenToBox<Project>('projects');
    _listenToBox<TaskItem>('tasks');
    _listenToBox<Invoice>('invoices');
    _listenToBox<Note>('notes');
  }

  static void _listenToBox<T extends HiveObject>(String boxName) {
    final box = Hive.box<T>(boxName);
    box.watch().listen((event) async {
      final uid = _uid;
      if (uid == null) return;

      if (event.deleted) {
        // Delete from Firestore
        await _db
            .collection('users')
            .doc(uid)
            .collection(boxName)
            .doc(event.key.toString())
            .delete();
      } else {
        // Push update to Firestore
        final dynamic item = event.value;
        if (item is HiveObject) {
          final data = (item as dynamic).toMap();
          await _db
              .collection('users')
              .doc(uid)
              .collection(boxName)
              .doc(item.key.toString())
              .set(data..['uid'] = uid, SetOptions(merge: true));
        }
      }
    });
  }
}
