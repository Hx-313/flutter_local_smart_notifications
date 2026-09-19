// lib/services/notifications/presentation/dialogs/i_permission_dialog.dart
// PRESENTATION | Permission dialog interface (consumer can override)

import 'package:flutter/material.dart';

abstract interface class IPermissionDialog {
  Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String openSettingsLabel,
    required String notNowLabel,
  });
}
