import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    tz.initializeTimeZones();
  }

  static Future<void> scheduleProjectReminders(Project project) async {
    // 1. Cancel existing reminders for this project
    await cancelProjectReminders(project.id);

    if (project.status == 'Completed') return;

    final deadline = project.deadline;
    final now = DateTime.now();

    // Generate unique base ID for project reminders
    final int baseId = project.id.hashCode.abs();

    // Reminder 1: 7 days before
    final reminder7 = deadline.subtract(const Duration(days: 7));
    if (reminder7.isAfter(now)) {
      await _schedule(
        id: baseId + 7,
        title: 'Deadline Approaching',
        body: 'Project "${project.name}" is due in 7 days.',
        scheduledDate: reminder7,
      );
    }

    // Reminder 2: 2 days before
    final reminder2 = deadline.subtract(const Duration(days: 2));
    if (reminder2.isAfter(now)) {
      await _schedule(
        id: baseId + 2,
        title: 'Urgent: Project Due',
        body: 'Project "${project.name}" is due in 2 days.',
        scheduledDate: reminder2,
      );
    }

    // Reminder 3: On deadline day (9 AM)
    final reminder0 = DateTime(deadline.year, deadline.month, deadline.day, 9, 0);
    if (reminder0.isAfter(now)) {
      await _schedule(
        id: baseId + 0,
        title: 'Deadline Today!',
        body: 'Today is the deadline for "${project.name}". Final push!',
        scheduledDate: reminder0,
      );
    }
  }

  static Future<void> cancelProjectReminders(String projectId) async {
    final int baseId = projectId.hashCode.abs();
    await _notifications.cancel(baseId + 7);
    await _notifications.cancel(baseId + 2);
    await _notifications.cancel(baseId + 0);
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'project_deadlines',
            'Project Deadlines',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }
}
