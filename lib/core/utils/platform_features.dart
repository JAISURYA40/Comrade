import 'dart:io';

import 'package:comrade/models/permissions_model.dart';

/// Platform capability flags. Android behavior stays unchanged.
/// iOS uses public APIs and in-app reminders; it does not use Family Controls.
abstract final class PlatformFeatures {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  static bool get hasBatteryOptimization => Platform.isAndroid;
  static bool get hasAutostartWhitelist => Platform.isAndroid;
  static bool get hasDeviceAdmin => Platform.isAndroid;
  static bool get hasNotificationListener => Platform.isAndroid;
  static bool get hasVpnPermissionPrompt => Platform.isAndroid;
  static bool get hasQuickFocusTile => Platform.isAndroid;
  static bool get hasDisplayOverlay => Platform.isAndroid;
  static bool get usesScreenTime => false;
  static bool get usesInAppReminders => Platform.isIOS;

  static bool haveEssentialPermissions(PermissionsModel perms) {
    if (Platform.isAndroid) {
      return perms.haveUsageAccessPermission &&
          perms.haveDisplayOverlayPermission &&
          perms.haveAlarmsPermission &&
          perms.haveNotificationPermission;
    }
    return perms.haveNotificationPermission;
  }
}
