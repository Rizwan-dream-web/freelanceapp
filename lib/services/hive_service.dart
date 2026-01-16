import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/models.dart';

class HiveService {
  static bool _initialized = false;

  /// Public getter to check initialization status
  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) {
      print('HiveService already initialized, skipping');
      return;
    }

    // HARD BLOCK: If any box is already open, skip initialization
    if (Hive.isBoxOpen('proposals') || 
        Hive.isBoxOpen('projects') || 
        Hive.isBoxOpen('tasks') || 
        Hive.isBoxOpen('invoices') || 
        Hive.isBoxOpen('clients') || 
        Hive.isBoxOpen('notes') || 
        Hive.isBoxOpen('settings')) {
      print('Hive boxes already open, skipping initialization');
      _initialized = true;
      return;
    }

    await Hive.initFlutter();

    // Close any lingering boxes from previous web sessions
    await Hive.close();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProposalAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ProjectAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TaskAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(InvoiceAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ClientAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(NoteAdapter());

    // Security & Encryption
    const secureStorage = FlutterSecureStorage();
    String? encryptionKeyString;
    try {
      encryptionKeyString = await secureStorage.read(key: 'hiveKey');
    } catch (e) {
      // If secure storage fails, use unencrypted
      encryptionKeyString = null;
    }
    List<int> encryptionKey;

    if (encryptionKeyString == null) {
      // Check for unencrypted data (Migration support)
      bool hasUnencryptedData = false;
      try {
        var checkSettings = Hive.isBoxOpen('settings') ? Hive.box('settings') : await Hive.openBox('settings');
        if (checkSettings.isNotEmpty) hasUnencryptedData = true;
        await checkSettings.close();
      } catch (e) {
        hasUnencryptedData = false;
      }

      encryptionKey = Hive.generateSecureKey();
      try {
        await secureStorage.write(key: 'hiveKey', value: base64UrlEncode(encryptionKey));
      } catch (e) {
        // If write fails, continue without encryption
      }

      if (hasUnencryptedData) {
        await _performMigration(encryptionKey);
      } else {
        await _openIfNeeded(encryptionKey);
      }
    } else {
      encryptionKey = base64Url.decode(encryptionKeyString);
      await _openIfNeeded(encryptionKey);
    }

    _initialized = true;
  }

  static Future<void> _performMigration(List<int> key) async {
    try {
      // Open unencrypted
      var bProposals = Hive.isBoxOpen('proposals') ? Hive.box<Proposal>('proposals') : await Hive.openBox<Proposal>('proposals');
      var bProjects = Hive.isBoxOpen('projects') ? Hive.box<Project>('projects') : await Hive.openBox<Project>('projects');
      var bTasks = Hive.isBoxOpen('tasks') ? Hive.box<TaskItem>('tasks') : await Hive.openBox<TaskItem>('tasks');
      var bInvoices = Hive.isBoxOpen('invoices') ? Hive.box<Invoice>('invoices') : await Hive.openBox<Invoice>('invoices');
      var bClients = Hive.isBoxOpen('clients') ? Hive.box<Client>('clients') : await Hive.openBox<Client>('clients');
      var bNotes = Hive.isBoxOpen('notes') ? Hive.box<Note>('notes') : await Hive.openBox<Note>('notes');
      var bSettings = Hive.isBoxOpen('settings') ? Hive.box('settings') : await Hive.openBox('settings');

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

      await _openIfNeeded(key);

      await Hive.box<Proposal>('proposals').putAll(mProposals);
      await Hive.box<Project>('projects').putAll(mProjects);
      await Hive.box<TaskItem>('tasks').putAll(mTasks);
      await Hive.box<Invoice>('invoices').putAll(mInvoices);
      await Hive.box<Client>('clients').putAll(mClients);
      await Hive.box<Note>('notes').putAll(mNotes);
      await Hive.box('settings').putAll(mSettings);
    } catch (e) {
      await _openIfNeeded(key);
    }
  }

  static Future<void> _openIfNeeded(List<int> key) async {
    if (kIsWeb) {
      // On web, open without encryption to avoid IndexedDB issues
      try {
        await Hive.openBox<Proposal>('proposals');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open proposals: $e');
      }
      try {
        await Hive.openBox<Project>('projects');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open projects: $e');
      }
      try {
        await Hive.openBox<TaskItem>('tasks');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open tasks: $e');
      }
      try {
        await Hive.openBox<Invoice>('invoices');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open invoices: $e');
      }
      try {
        await Hive.openBox<Client>('clients');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open clients: $e');
      }
      try {
        await Hive.openBox<Note>('notes');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open notes: $e');
      }
      try {
        await Hive.openBox('settings');
      } catch (e) {
        if (!e.toString().contains('already open')) print('Failed to open settings: $e');
      }
    } else {
      // On mobile, use encryption
      final cipher = HiveAesCipher(key);

      // Helper function to open box with fallback
      Future<void> openBox(String name, Future<Box> Function() openWithCipher, Future<Box> Function() openWithoutCipher) async {
        try {
          await openWithCipher();
        } catch (e) {
          if (e.toString().contains('already open')) {
            // Box is already open, skip
            return;
          }
          print('Failed to open encrypted box $name: $e. Falling back to unencrypted.');
          try {
            await openWithoutCipher();
          } catch (e2) {
            if (e2.toString().contains('already open')) {
              // Box is already open, skip
              return;
            }
            print('Failed to open unencrypted box $name: $e2');
            rethrow;
          }
        }
      }

      await openBox('proposals', () => Hive.openBox<Proposal>('proposals', encryptionCipher: cipher), () => Hive.openBox<Proposal>('proposals'));
      await openBox('projects', () => Hive.openBox<Project>('projects', encryptionCipher: cipher), () => Hive.openBox<Project>('projects'));
      await openBox('tasks', () => Hive.openBox<TaskItem>('tasks', encryptionCipher: cipher), () => Hive.openBox<TaskItem>('tasks'));
      await openBox('invoices', () => Hive.openBox<Invoice>('invoices', encryptionCipher: cipher), () => Hive.openBox<Invoice>('invoices'));
      await openBox('clients', () => Hive.openBox<Client>('clients', encryptionCipher: cipher), () => Hive.openBox<Client>('clients'));
      await openBox('notes', () => Hive.openBox<Note>('notes', encryptionCipher: cipher), () => Hive.openBox<Note>('notes'));
      await openBox('settings', () => Hive.openBox('settings', encryptionCipher: cipher), () => Hive.openBox('settings'));
    }
  }
}
