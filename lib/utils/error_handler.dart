import 'package:flutter/material.dart';
import '../widgets/forms.dart';

/// Error severity levels
enum ErrorSeverity {
  info,     // Informational messages
  warning,  // Non-critical warnings
  error,    // Standard errors
  critical, // Critical errors that need immediate attention
}

/// Application error model
class AppError {
  final String message;
  final String? details;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    this.details,
    this.severity = ErrorSeverity.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final severityStr = severity.name.toUpperCase();
    final detailsStr = details != null ? ' - $details' : '';
    return '[$severityStr] $message$detailsStr';
  }
}

/// Centralized error handling service
class ErrorHandler {
  static final List<AppError> _errorLog = [];
  static const int maxLogSize = 100;

  /// Handle an error with optional user notification
  static void handle(
    AppError error, {
    BuildContext? context,
    bool showSnackbar = true,
    VoidCallback? onRetry,
  }) {
    // Log error
    _logError(error);

    // Print to console
    print('[${error.timestamp}] ${error.toString()}');
    if (error.stackTrace != null) {
      print('Stack trace: ${error.stackTrace}');
    }

    // Show to user if context provided
    if (context != null && showSnackbar) {
      _showErrorSnackbar(context, error, onRetry);
    }

    // TODO: Send critical errors to crash reporting service
    // if (error.severity == ErrorSeverity.critical) {
    //   FirebaseCrashlytics.instance.recordError(error, error.stackTrace);
    // }
  }

  /// Log error to internal error log
  static void _logError(AppError error) {
    _errorLog.add(error);

    // Maintain max log size
    if (_errorLog.length > maxLogSize) {
      _errorLog.removeAt(0);
    }
  }

  /// Show error snackbar to user
  static void _showErrorSnackbar(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    final snackBar = SnackBar(
      content: Text(error.message),
      backgroundColor: _getColorForSeverity(error.severity),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      duration: _getDurationForSeverity(error.severity),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Get color based on severity
  static Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.deepPurple;
    }
  }

  /// Get snackbar duration based on severity
  static Duration _getDurationForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return const Duration(seconds: 2);
      case ErrorSeverity.warning:
        return const Duration(seconds: 3);
      case ErrorSeverity.error:
        return const Duration(seconds: 4);
      case ErrorSeverity.critical:
        return const Duration(seconds: 6);
    }
  }

  /// Get error log (for debugging/error screen)
  static List<AppError> get errorLog => List.unmodifiable(_errorLog);

  /// Clear error log
  static void clearLog() => _errorLog.clear();

  /// Get errors by severity
  static List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorLog.where((e) => e.severity == severity).toList();
  }

  /// Get critical errors count
  static int get criticalErrorCount {
    return _errorLog.where((e) => e.severity == ErrorSeverity.critical).length;
  }
}

/// Extension methods for easier error handling in BuildContext
extension ErrorHandlerContext on BuildContext {
  /// Show error with animated dialog
  void showAnimatedError(
    String title,
    String message, {
    String? details,
    List<Widget>? actions,
    IconData icon = Icons.error_outline,
  }) {
    showDialog(
      context: this,
      builder: (context) => AnimatedErrorDialog(
        title: title,
        message: message,
        details: details,
        actions: actions,
        icon: icon,
      ),
    );
  }

  /// Show success with animated dialog
  void showAnimatedSuccess(
    String title,
    String message, {
    List<Widget>? actions,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: this,
      builder: (context) => AnimatedSuccessDialog(
        title: title,
        message: message,
        actions: actions,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Show animated error snackbar
  void showAnimatedErrorSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(this);
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: theme.colorScheme.error,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show animated success snackbar
  void showAnimatedSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(this);
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show animated warning snackbar
  void showAnimatedWarningSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(this);
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error to user
  void showError(AppError error, {VoidCallback? onRetry}) {
    ErrorHandler.handle(error, context: this, onRetry: onRetry);
  }

  /// Show success message
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show info message
  void showInfo(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show warning message
  void showWarning(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
