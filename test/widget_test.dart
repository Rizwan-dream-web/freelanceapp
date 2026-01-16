// This is a basic Flutter widget test for the Freelancer Invoicing App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freelancer_app/main.dart';
import 'package:freelancer_app/models/models.dart';
import 'package:freelancer_app/models/user_profile.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(ProposalAdapter());
    Hive.registerAdapter(UserProfileAdapter());
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FreelancerApp());

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify that the app launched without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Dashboard screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FreelancerApp());

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify dashboard elements are present
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Ready to crush your goals today?'), findsOneWidget);
  });

  testWidgets('Navigation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FreelancerApp());

    // Wait for initialization
    await tester.pumpAndSettle();

    // Test navigation to different screens
    // Note: This would require more complex setup with mock data
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
