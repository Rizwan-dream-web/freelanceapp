import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/models.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProposalAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ProjectAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(InvoiceAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ClientAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(NoteAdapter());

    // Security & Encryption
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString = await secureStorage.read(key: 'hiveKey');
    List<int> encryptionKey;

    if (encryptionKeyString == null) {
      // Check for unencrypted data (Migration support)
      bool hasUnencryptedData = false;
      try {
        var checkSettings = await Hive.openBox('settings');
        if (checkSettings.isNotEmpty) hasUnencryptedData = true;
        await checkSettings.close();
      } catch (e) {
        hasUnencryptedData = false;
      }

      encryptionKey = Hive.generateSecureKey();
      await secureStorage.write(key: 'hiveKey', value: base64UrlEncode(encryptionKey));

      if (hasUnencryptedData) {
        await _performMigration(encryptionKey);
      } else {
        await _openBoxes(encryptionKey);
      }
    } else {
      encryptionKey = base64Url.decode(encryptionKeyString);
      await _openBoxes(encryptionKey);
    }
  }

  static Future<void> _performMigration(List<int> key) async {
    try {
      // Open unencrypted
      var bProposals = await Hive.openBox<Proposal>('proposals');
      var bProjects = await Hive.openBox<Project>('projects');
      var bTasks = await Hive.openBox<TaskItem>('tasks');
      var bInvoices = await Hive.openBox<Invoice>('invoices');
      var bClients = await Hive.openBox<Client>('clients');
      var bNotes = await Hive.openBox<Note>('notes');
      var bSettings = await Hive.openBox('settings');

      final mProposals = Map<dynamic, Proposal>.from(bProposals.toMap());
      final mProjects = Map<dynamic, Project>.from(bProjects.toMap());
      final mTasks = Map<dynamic, TaskItem>.from(bTasks.toMap());
      final mInvoices = Map<dynamic, Invoice>.from(bInvoices.toMap());
      final mClients = Map<dynamic, Client>.from(bClients.toMap());
      final mNotes = Map<dynamic, Note>.from(bNotes.toMap());
      final mSettings = Map<dynamic, dynamic>.from(bSettings.toMap());

      await bProposals.deleteFromDisk();
      await bProjects.deleteFromDisk();
      await bTasks.deleteFromDisk();
      await bInvoices.deleteFromDisk();
      await bClients.deleteFromDisk();
      await bNotes.deleteFromDisk();
      await bSettings.deleteFromDisk();

      await _openBoxes(key);

      await Hive.box<Proposal>('proposals').putAll(mProposals);
      await Hive.box<Project>('projects').putAll(mProjects);
      await Hive.box<TaskItem>('tasks').putAll(mTasks);
      await Hive.box<Invoice>('invoices').putAll(mInvoices);
      await Hive.box<Client>('clients').putAll(mClients);
      await Hive.box<Note>('notes').putAll(mNotes);
      await Hive.box('settings').putAll(mSettings);
    } catch (e) {
      await _openBoxes(key);
    }
  }

  static Future<void> _openBoxes(List<int> key) async {
    final cipher = HiveAesCipher(key);
    await Hive.openBox<Proposal>('proposals', encryptionCipher: cipher);
    await Hive.openBox<Project>('projects', encryptionCipher: cipher);
    await Hive.openBox<TaskItem>('tasks', encryptionCipher: cipher);
    await Hive.openBox<Invoice>('invoices', encryptionCipher: cipher);
    await Hive.openBox<Client>('clients', encryptionCipher: cipher);
    await Hive.openBox<Note>('notes', encryptionCipher: cipher);
    await Hive.openBox('settings', encryptionCipher: cipher);
  }
}
