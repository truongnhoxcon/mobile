/// Core Utilities
/// 
/// Helper functions and utilities.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date and Time Utilities
class DateUtils {
  DateUtils._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format date to string
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format time to string
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Format date and time to string
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Get relative time string
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

/// Validation Utilities
class ValidationUtils {
  ValidationUtils._();

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password (min 6 chars)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate phone number (Vietnamese)
  static bool isValidPhone(String phone) {
    return RegExp(r'^(0|\+84)(3|5|7|8|9)[0-9]{8}$').hasMatch(phone);
  }
}

/// UI Utilities
class UIUtils {
  UIUtils._();

  /// Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
