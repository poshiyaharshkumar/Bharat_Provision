import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_strings.dart';

typedef ErrorHandler = void Function(BuildContext context, String message);

class AppErrorHandler {
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    bool hasCloseButton = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red[700],
        action: hasCloseButton
            ? SnackBarAction(
                label: AppStrings.cancelButton,
                textColor: Colors.white,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green[700],
      ),
    );
  }

  static void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancelButton),
          ),
        ],
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('SQLITE_NOTADB')) {
        return AppStrings.databaseError;
      }
      if (message.contains('wrong password')) {
        return AppStrings.wrongPinError;
      }
      if (message.contains('locked')) {
        return AppStrings.pinLocked;
      }
    }
    return AppStrings.errorGeneric;
  }
}

/// Exception for transaction rollback scenarios
class TransactionRollbackException implements Exception {
  final String message;
  final List<String> actions;

  TransactionRollbackException({
    required this.message,
    this.actions = const [],
  });

  @override
  String toString() => message;
}

/// Exception for authentication failures
class AuthenticationException implements Exception {
  final String message;
  final int? attemptNumber;
  final int? lockoutSeconds;

  AuthenticationException({
    required this.message,
    this.attemptNumber,
    this.lockoutSeconds,
  });

  @override
  String toString() => message;
}

/// Exception for database operations
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  DatabaseException({required this.message, this.originalError});

  @override
  String toString() => message;
}

/// Exception for bill operations
class BillException implements Exception {
  final String message;
  final int? billId;

  BillException({required this.message, this.billId});

  @override
  String toString() => message;
}

/// Enum for error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Error handler provider
final errorHandlerProvider = Provider<AppErrorHandler>((ref) {
  return AppErrorHandler();
});
