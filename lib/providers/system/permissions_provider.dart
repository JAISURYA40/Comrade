/*
 *
 *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comrade/core/enums/permission_type.dart';
import 'package:comrade/core/services/method_channel_service.dart';
import 'package:comrade/models/permissions_model.dart';

/// A Riverpod state notifier provider that manages and requests various permissions required by the app.
final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionsModel>(
  (ref) => PermissionNotifier(),
);

/// This class manages the state of app permissions and handles permission requests.
class PermissionNotifier extends StateNotifier<PermissionsModel>
    with WidgetsBindingObserver {
  PermissionNotifier() : super(const PermissionsModel()) {
    WidgetsBinding.instance.addObserver(this);
    fetchPermissionsStatus();
  }

  /// Tracks the last requested permission type for handling lifecycle changes.
  PermissionType _askedPermission = PermissionType.none;

  /// Create [PermissionsModel] and initializes with permission state by fetching initial permission status then updated state.
  Future<PermissionsModel> fetchPermissionsStatus() async {
    Future<bool> safe(Future<bool> Function() call) async {
      try {
        return await call();
      } catch (e) {
        debugPrint('PermissionNotifier.fetchPermissionsStatus: $e');
        return false;
      }
    }

    final cache = PermissionsModel(
      haveNotificationPermission: await safe(
        () => MethodChannelService.instance.getAndAskNotificationPermission(),
      ),
      haveUsageAccessPermission: await safe(
        () => MethodChannelService.instance.getAndAskUsageAccessPermission(),
      ),
      haveDisplayOverlayPermission: await safe(
        () =>
            MethodChannelService.instance.getAndAskDisplayOverlayPermission(),
      ),
      haveDndPermission: await safe(
        () => MethodChannelService.instance.getAndAskDndPermission(),
      ),
      haveAccessibilityPermission: await safe(
        () => MethodChannelService.instance.getAndAskAccessibilityPermission(),
      ),
      haveVpnPermission: await safe(
        () => MethodChannelService.instance.getAndAskVpnPermission(),
      ),
      haveAlarmsPermission: await safe(
        () => MethodChannelService.instance.getAndAskExactAlarmPermission(),
      ),
      haveIgnoreOptimizationPermission: await safe(
        () => MethodChannelService.instance
            .getAndAskIgnoreBatteryOptimizationPermission(),
      ),
      haveAdminPermission: await safe(
        () => MethodChannelService.instance.getAndAskAdminPermission(),
      ),
      haveNotificationAccessPermission: await safe(
        () => MethodChannelService.instance
            .getAndAskNotificationAccessPermission(),
      ),
    );

    state = cache;
    return cache;
  }

  /// Removes the lifecycle observer when the widget is disposed.
  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Handles permission updates when the app resumes from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) async {
    if (appState != AppLifecycleState.resumed) return;

    state = switch (_askedPermission) {
      PermissionType.none => state,
      PermissionType.notification => state.copyWith(
          haveNotificationPermission: await MethodChannelService.instance
              .getAndAskNotificationPermission(),
        ),
      PermissionType.usageAccess => state.copyWith(
          haveUsageAccessPermission: await MethodChannelService.instance
              .getAndAskUsageAccessPermission(),
        ),
      PermissionType.displayOverlay => state.copyWith(
          haveDisplayOverlayPermission: await MethodChannelService.instance
              .getAndAskDisplayOverlayPermission(),
        ),
      PermissionType.doNotDisturb => state.copyWith(
          haveDndPermission:
              await MethodChannelService.instance.getAndAskDndPermission(),
        ),
      PermissionType.accessibility => state.copyWith(
          haveAccessibilityPermission: await MethodChannelService.instance
              .getAndAskAccessibilityPermission(),
        ),
      PermissionType.vpn => state.copyWith(
          haveVpnPermission:
              await MethodChannelService.instance.getAndAskVpnPermission(),
        ),
      PermissionType.exactAlarm => state.copyWith(
          haveAlarmsPermission: await MethodChannelService.instance
              .getAndAskExactAlarmPermission(),
        ),
      PermissionType.ignoreOptimization => state.copyWith(
          haveIgnoreOptimizationPermission: await MethodChannelService.instance
              .getAndAskIgnoreBatteryOptimizationPermission(),
          haveAlarmsPermission: await MethodChannelService.instance
              .getAndAskExactAlarmPermission(),
        ),
      PermissionType.admin => state.copyWith(
          haveAdminPermission:
              await MethodChannelService.instance.getAndAskAdminPermission(),
        ),
      PermissionType.notificationAccess => state.copyWith(
          haveNotificationAccessPermission: await MethodChannelService.instance
              .getAndAskNotificationAccessPermission(),
        ),
    };

    _askedPermission = PermissionType.none;
  }

  /// Requests the notification permission and updates the internal state.
  void askNotificationPermission() async {
    _askedPermission = PermissionType.notification;
    final granted = await MethodChannelService.instance
        .getAndAskNotificationPermission(askPermissionToo: true);
    state = state.copyWith(haveNotificationPermission: granted);
  }

  /// Requests the usage access permission and updates the internal state.
  void askUsageAccessPermission() async {
    _askedPermission = PermissionType.usageAccess;
    final granted = await MethodChannelService.instance
        .getAndAskUsageAccessPermission(askPermissionToo: true);
    state = state.copyWith(haveUsageAccessPermission: granted);
  }

  /// Requests the display overlay permission and updates the internal state.
  void askDisplayOverlayPermission() async {
    _askedPermission = PermissionType.displayOverlay;
    final granted = await MethodChannelService.instance
        .getAndAskDisplayOverlayPermission(askPermissionToo: true);
    state = state.copyWith(haveDisplayOverlayPermission: granted);
  }

  /// Requests the accessibility permission and updates the internal state.
  void askAccessibilityPermission() async {
    _askedPermission = PermissionType.accessibility;
    final granted = await MethodChannelService.instance
        .getAndAskAccessibilityPermission(askPermissionToo: true);
    state = state.copyWith(haveAccessibilityPermission: granted);
  }

  /// Requests the VPN permission and updates the internal state.
  void askVpnPermission() async {
    _askedPermission = PermissionType.vpn;
    final granted = await MethodChannelService.instance
        .getAndAskVpnPermission(askPermissionToo: true);
    state = state.copyWith(haveVpnPermission: granted);
  }

  /// Requests the Do Not Disturb permission and updates the internal state.
  void askDndPermission() async {
    _askedPermission = PermissionType.doNotDisturb;
    final granted = await MethodChannelService.instance
        .getAndAskDndPermission(askPermissionToo: true);
    state = state.copyWith(haveDndPermission: granted);
  }

  /// Requests the Set Exact Alarm permission and updates the internal state.
  void askExactAlarmPermission() async {
    _askedPermission = PermissionType.exactAlarm;
    final granted = await MethodChannelService.instance
        .getAndAskExactAlarmPermission(askPermissionToo: true);
    state = state.copyWith(haveAlarmsPermission: granted);
  }

  /// Requests the Ignore Battery Optimization permission and updates the internal state.
  void askIgnoreBatteryOptimizationPermission() async {
    _askedPermission = PermissionType.ignoreOptimization;
    final granted = await MethodChannelService.instance
        .getAndAskIgnoreBatteryOptimizationPermission(askPermissionToo: true);
    state = state.copyWith(
      haveIgnoreOptimizationPermission: granted,
      haveAlarmsPermission: await MethodChannelService.instance
          .getAndAskExactAlarmPermission(),
    );
  }

  /// Requests the Admin permission and updates the internal state.
  void askAdminPermission() async {
    _askedPermission = PermissionType.admin;
    final granted = await MethodChannelService.instance
        .getAndAskAdminPermission(askPermissionToo: true);
    state = state.copyWith(haveAdminPermission: granted);
  }

  /// Request the device to disable admin if already enabled
  void disableAdminPermission() async {
    await MethodChannelService.instance.disableDeviceAdmin();
    await Future.delayed(500.ms);
    state = state.copyWith(
      haveAdminPermission:
          await MethodChannelService.instance.getAndAskAdminPermission(),
    );
  }

  /// Requests the Admin permission and updates the internal state.
  void askNotificationAccessPermission() async {
    _askedPermission = PermissionType.notificationAccess;
    final granted = await MethodChannelService.instance
        .getAndAskNotificationAccessPermission(askPermissionToo: true);
    state = state.copyWith(haveNotificationAccessPermission: granted);
  }
}
