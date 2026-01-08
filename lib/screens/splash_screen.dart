import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/models.dart';
import 'onboarding_screen.dart';
import '../main.dart'; // To access MainContainer

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial delay for the "Premium Feel" (min 3 seconds as requested)
    final delayFuture = Future.delayed(const Duration(seconds: 3));
    
    // Actual Initialization Logic
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
      // Logic from main.dart refactored here
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
        // Migration Logic (Simplified for Splash)
        // Note: For brevity, we assume migration is fast or already done. 
        // A full migration might need a specialized UI update, but here we proceed.
        await _performMigration(encryptionKey);
      } else {
         await _openBoxes(encryptionKey);
      }
    } else {
      encryptionKey = base64Url.decode(encryptionKeyString);
      await _openBoxes(encryptionKey);
    }

    // Wait for both init and delay
    await delayFuture;

    if (mounted) {
      _checkFirstRun();
    }
  }

  Future<void> _performMigration(List<int> key) async {
      try {
         // Migration implementation (Same as before)
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

        var boxProposals = Hive.box<Proposal>('proposals');
        var boxProjects = Hive.box<Project>('projects');
        var boxTasks = Hive.box<TaskItem>('tasks');
        var boxInvoices = Hive.box<Invoice>('invoices');
        var boxClients = Hive.box<Client>('clients');
        var boxNotes = Hive.box<Note>('notes');
        var boxSettings = Hive.box('settings');

        await boxProposals.putAll(mProposals);
        await boxProjects.putAll(mProjects);
        await boxTasks.putAll(mTasks);
        await boxInvoices.putAll(mInvoices);
        await boxClients.putAll(mClients);
        await boxNotes.putAll(mNotes);
        await boxSettings.putAll(mSettings);
      } catch (e) {
        // Fallback
        await _openBoxes(key);
      }
  }

  Future<void> _openBoxes(List<int> key) async {
    final cipher = HiveAesCipher(key);
    await Hive.openBox<Proposal>('proposals', encryptionCipher: cipher);
    await Hive.openBox<Project>('projects', encryptionCipher: cipher);
    await Hive.openBox<TaskItem>('tasks', encryptionCipher: cipher);
    await Hive.openBox<Invoice>('invoices', encryptionCipher: cipher);
    await Hive.openBox<Client>('clients', encryptionCipher: cipher);
    await Hive.openBox<Note>('notes', encryptionCipher: cipher);
    await Hive.openBox('settings', encryptionCipher: cipher);
  }

  void _checkFirstRun() {
    final settingsBox = Hive.box('settings');
    final bool hasSeenOnboarding = settingsBox.get('hasSeenOnboarding', defaultValue: false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasSeenOnboarding ? const MainContainer() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)], // Brand Colors
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 20,
                           spreadRadius: 5,
                         )
                       ]
                    ),
                    child: const Icon(Icons.flash_on_rounded, size: 60, color: Color(0xFF2196F3)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Freelancer App',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 50),
              
              // Premium Progress Shimmer (No Spinner)
              Shimmer.fromColors(
                baseColor: Colors.white.withOpacity(0.4),
                highlightColor: Colors.white,
                child: Container(
                  width: 150,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
