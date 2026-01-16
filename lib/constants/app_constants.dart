/// Application-wide constants
///
/// This file contains all constant values used throughout the app
/// to avoid magic strings and ensure consistency.

/// Hive box names for local storage
class HiveBoxes {
  static const String clients = 'clients';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String invoices = 'invoices';
  static const String proposals = 'proposals';
  static const String notes = 'notes';
  static const String settings = 'settings';
}

/// Invoice status values
class InvoiceStatus {
  static const String paid = 'Paid';
  static const String pending = 'Pending';
  static const String overdue = 'Overdue';
  static const String draft = 'Draft';
}

/// Project status values
class ProjectStatus {
  static const String notStarted = 'Not Started';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String onHold = 'On Hold';
}

/// Client health status values
class ClientHealth {
  static const String vip = 'VIP';
  static const String active = 'Active';
  static const String dormant = 'Dormant';
  static const String inactive = 'Inactive';
}

/// Task status values
class TaskStatus {
  static const String todo = 'To Do';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
}

/// Proposal status values
class ProposalStatus {
  static const String draft = 'Draft';
  static const String sent = 'Sent';
  static const String accepted = 'Accepted';
  static const String rejected = 'Rejected';
}

/// Default application values and thresholds
class AppDefaults {
  /// Minimum LTV amount to be considered VIP client (in USD)
  static const int vipThreshold = 5000;

  /// Number of days to consider a client as recently active
  static const int recentActivityDays = 60;

  /// Timeout duration for cloud sync operations
  static const Duration syncTimeout = Duration(seconds: 30);

  /// Maximum number of retry attempts for failed operations
  static const int maxRetries = 3;

  /// Default currency code
  static const String defaultCurrency = 'USD';

  /// Timer tick interval for task tracking
  static const Duration timerInterval = Duration(seconds: 1);
}

/// Firestore collection names
class FirestoreCollections {
  static const String users = 'users';
  static const String clients = 'clients';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String invoices = 'invoices';
  static const String proposals = 'proposals';
  static const String notes = 'notes';
}

/// Settings keys for Hive settings box
class SettingsKeys {
  static const String isDarkMode = 'isDarkMode';
  static const String primaryColor = 'primaryColor';
  static const String accentColor = 'accentColor';
  static const String globalCurrency = 'globalCurrency';
  static const String isCloudMigrated = 'isCloudMigrated';
  static const String vipThreshold = 'vipThreshold';
  static const String recentActivityDays = 'recentActivityDays';
}

/// Firebase Auth provider IDs
class AuthProviders {
  static const String password = 'password';
  static const String google = 'google.com';
  static const String phone = 'phone';
}
