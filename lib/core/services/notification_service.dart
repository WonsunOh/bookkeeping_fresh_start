// lib/core/services/notification_service.dart

import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class NotificationService {
  static void showSnackBar(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    switch (type) {
      case NotificationType.success:
        backgroundColor = colorScheme.primary;
        textColor = colorScheme.onPrimary;
        icon = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        backgroundColor = colorScheme.error;
        textColor = colorScheme.onError;
        icon = Icons.error_outline;
        break;
      case NotificationType.warning:
        backgroundColor = colorScheme.tertiary;
        textColor = colorScheme.onTertiary;
        icon = Icons.warning_outlined;
        break;
      case NotificationType.info:
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message: message, type: NotificationType.success);
  }

  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    showSnackBar(
      context,
      message: message,
      type: NotificationType.error,
      duration: const Duration(seconds: 6),
      actionLabel: onRetry != null ? '다시 시도' : null,
      onAction: onRetry,
    );
  }

  static void showWarning(BuildContext context, String message) {
    showSnackBar(context, message: message, type: NotificationType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    showSnackBar(context, message: message, type: NotificationType.info);
  }
}

// 확인 다이얼로그 개선
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '확인',
    String cancelText = '취소',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (destructive)
              Icon(
                Icons.warning_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            if (destructive) const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}