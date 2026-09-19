// lib/services/notifications/presentation/dialogs/default_permission_dialog.dart
// PRESENTATION | Default permission dialog implementation

import 'package:flutter/material.dart';

import 'i_permission_dialog.dart';

class DefaultPermissionDialog implements IPermissionDialog {
  const DefaultPermissionDialog();

  @override
  Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String openSettingsLabel,
    required String notNowLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(notNowLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(openSettingsLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
