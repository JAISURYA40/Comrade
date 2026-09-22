package com.comrade.android

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.VpnService
import androidx.activity.result.ActivityResultLauncher
import com.comrade.android.enums.DndWakeLock
import com.comrade.android.generics.SafeServiceConnection
import com.comrade.android.generics.ServiceBinder
import com.comrade.android.helpers.AlarmTasksSchedulingHelper.cancelBedtimeRoutineTasks
import com.comrade.android.helpers.AlarmTasksSchedulingHelper.cancelNotificationBatchTask
import com.comrade.android.helpers.AlarmTasksSchedulingHelper.scheduleBedtimeRoutineTasks
import com.comrade.android.helpers.AlarmTasksSchedulingHelper.scheduleNotificationBatchTask
import com.comrade.android.helpers.device.DeviceAppsHelper.getDeviceAppInfos
import com.comrade.android.helpers.device.NewActivitiesLaunchHelper
import com.comrade.android.helpers.device.NotificationHelper
import com.comrade.android.helpers.device.PermissionsHelper
import com.comrade.android.helpers.storage.SharedPrefsHelper
import com.comrade.android.helpers.usages.AppsUsageHelper.getAppsUsageForInterval
import com.comrade.android.models.AppRestriction
import com.comrade.android.models.BedtimeSchedule
import com.comrade.android.models.FocusSession
import com.comrade.android.models.Notification
import com.comrade.android.models.NotificationSettings
import com.comrade.android.models.RestrictionGroup
import com.comrade.android.services.notification.ComradeNotificationListenerService
import com.comrade.android.services.timer.EmergencyPauseService
import com.comrade.android.services.timer.FocusSessionService
import com.comrade.android.services.tracking.ComradeTrackerService
import com.comrade.android.services.vpn.ComradeVpnService
import com.comrade.android.utils.AppUtils
import com.comrade.android.utils.JsonUtils
import com.comrade.android.utils.Utils
import com.comrade.android.widgets.FocusModeWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.Locale

class FgMethodCallHandler(
    private val context: Context,
    private val activity: Activity? = null,
    private val vpnPermLauncher: ActivityResultLauncher<Intent>? = null,
) : MethodCallHandler {

    private val focusServiceConn =
        SafeServiceConnection(
            context = context,
            serviceClass = FocusSessionService::class.java
        )

    private val trackerServiceConn =
        SafeServiceConnection(
            context = context,
            serviceClass = ComradeTrackerService::class.java
        )

    private val vpnServiceConn =
        SafeServiceConnection(
            context = context,
            serviceClass = ComradeVpnService::class.java
        )

    private val notificationServiceConn =
        SafeServiceConnection(
            context = context,
            serviceClass = ComradeNotificationListenerService::class.java
        )


    init {
        // Bind to Services if they are already running
        trackerServiceConn.bindService()
        vpnServiceConn.bindService()
        notificationServiceConn.bindService()
        focusServiceConn.bindService()
    }


    fun dispose() {
        // Unbind all services
        trackerServiceConn.unBindService()
        vpnServiceConn.unBindService()
        notificationServiceConn.unBindService()
        focusServiceConn.unBindService()
    }

    private fun updateLocale(languageCode: String) {
        if (languageCode.isNotEmpty()) {
            val newLocale = Locale(languageCode)
            Locale.setDefault(newLocale)
            val config = Configuration()
            config.setLocale(newLocale)
            context.resources.updateConfiguration(config, context.resources.displayMetrics)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // ==============================================================================================================
            // ====================================== SYSTEM =================================================================
            // ==============================================================================================================

            "updateLocale" -> {
                updateLocale(call.arguments() ?: "en")
                result.success(true)
            }

            "updateExcludedApps" -> {
                SharedPrefsHelper.getSetExcludedApps(context, call.arguments() ?: "")
                result.success(true)
            }

            "getDeviceInfo" -> {
                result.success(AppUtils.getDeviceInfoMap(context))
            }

            "getDeviceAppsInfo" -> {
                getDeviceAppInfos(
                    context = context,
                    onSuccess = { data -> result.success(data) }
                )
            }

            "getAppsUsageForInterval" -> {
                getAppsUsageForInterval(
                    context = context,
                    startMsEpoch = call.argument("startDateTime"),
                    endMsEpoch = call.argument("endDateTime"),
                    onSuccess = { data -> result.success(data) }
                )
            }

            "getAppsLaunchCount" -> {
                result.success(
                    trackerServiceConn.service?.getRestrictionManager?.getAppsLaunchCount
                        ?: mapOf<String, Int>()
                )
            }

            "getShortsScreenTimeMs" -> {
                result.success(SharedPrefsHelper.getSetShortsScreenTimeMs(context, null))
            }

            "getNativeCrashLogs" -> {
                result.success(SharedPrefsHelper.getCrashLogsArrayJsonString(context))
            }

            "clearNativeCrashLogs" -> {
                SharedPrefsHelper.clearCrashLogs(context)
                result.success(true)
            }

            // ==============================================================================================================
            // ====================================== SERVICES =================================================================
            // ==============================================================================================================

            "updateAppRestrictions" -> {
                val appRestrictions = JsonUtils.parseAppRestrictionsMap(
                    call.arguments() ?: ""
                )
                updateTrackerServiceRestrictions(appRestrictions, null)
                result.success(true)
            }

            "updateRestrictionsGroups" -> {
                val restrictionGroups = JsonUtils.parseRestrictionGroupsMap(
                    call.arguments() ?: ""
                )
                updateTrackerServiceRestrictions(null, restrictionGroups)
                result.success(true)
            }

            "updateInternetBlockedApps" -> {
                val blockedApps =
                    JsonUtils.parseStringSet(call.arguments() ?: "")
                if (vpnServiceConn.isActive) {
                    vpnServiceConn.service?.updateBlockedApps(blockedApps)
                } else if (blockedApps.isNotEmpty() && getAndAskVpnPermission(false)) {
                    vpnServiceConn.setOnConnectedCallback { service ->
                        service.updateBlockedApps(
                            blockedApps
                        )
                    }
                    vpnServiceConn.startAndBind()
                }
                result.success(true)
            }

            "updateWellBeingSettings" -> {
                // NOTE: Only updating shared prefs because accessibility service have onSharedPrefsChange listener registered which will eventually reload needed data
                SharedPrefsHelper.getSetWellBeingSettings(
                    context,
                    call.arguments() ?: ""
                )
                result.success(true)
            }

            "updateBedtimeSchedule" -> {
                val jsonBedtimeSettings = call.arguments() ?: ""
                val bedtimeSettings = BedtimeSchedule.fromJson(jsonBedtimeSettings)
                if (bedtimeSettings.isScheduleOn) {
                    scheduleBedtimeRoutineTasks(context, jsonBedtimeSettings)
                } else {
                    cancelBedtimeRoutineTasks(context)
                    if (bedtimeSettings.shouldStartDnd) {
                        NotificationHelper.toggleDnd(context, DndWakeLock.BEDTIME_MODE, false)
                    }
                }
                result.success(true)
            }

            "activeEmergencyPause" -> {
                if (!Utils.isServiceRunning(context, EmergencyPauseService::class.java)
                    && Utils.isServiceRunning(context, ComradeTrackerService::class.java)
                ) {
                    context.startService(
                        Intent(context, EmergencyPauseService::class.java).setAction(
                            ServiceBinder.ACTION_START_COMRADE_SERVICE
                        )
                    )
                    result.success(true)
                } else {
                    result.success(false)
                }
            }

            "updateFocusSession" -> {
                val focusSession = FocusSession.fromJson(call.arguments() ?: "")
                if (focusServiceConn.isActive) {
                    focusServiceConn.service?.updateFocusSession(focusSession)
                } else {
                    focusServiceConn.setOnConnectedCallback { service: FocusSessionService ->
                        service.startFocusSession(
                            focusSession
                        )
                    }
                    focusServiceConn.startAndBind()
                }
                result.success(true)
            }

            "giveUpOrFinishFocusSession" -> {
                if (focusServiceConn.isActive) {
                    focusServiceConn.service?.giveUpOrStopFocusSession(call.arguments() ?: false)
                    focusServiceConn.unBindService()
                }
                result.success(true)
            }

            "syncFocusWidgetConfig" -> {
                val jsonString = call.arguments<String>() ?: ""
                try {
                    val jsonObject = org.json.JSONObject(jsonString)
                    val durationSecs = jsonObject.optInt("durationSecs", 1500)
                    val toggleDnd = jsonObject.optBoolean("toggleDnd", false)
                    val distractingApps = JsonUtils.parseStringSet(
                        jsonObject.optJSONArray("distractingApps")?.toString()
                    )
                    SharedPrefsHelper.setFocusWidgetConfig(
                        context,
                        durationSecs,
                        toggleDnd,
                        distractingApps
                    )
                    FocusModeWidgetProvider.updateAllWidgets(context)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            "isFocusSessionRunning" -> {
                val isRunning = Utils.isServiceRunning(context, FocusSessionService::class.java)
                result.success(isRunning)
            }

            "getActiveFocusSessionInfo" -> {
                val isRunning = Utils.isServiceRunning(context, FocusSessionService::class.java)
                if (isRunning) {
                    val startTime = SharedPrefsHelper.getActiveFocusStartTime(context)
                    val duration = SharedPrefsHelper.getActiveFocusDuration(context)
                    val map = mapOf(
                        "isRunning" to true,
                        "startTimeMsEpoch" to startTime,
                        "durationSecs" to duration
                    )
                    result.success(map)
                } else {
                    result.success(mapOf("isRunning" to false))
                }
            }

            "updateNotificationSettings" -> {
                val settingsJson = call.arguments() ?: ""
                val settings = NotificationSettings.fromJson(settingsJson)

                /// Update service
                if (notificationServiceConn.isActive) {
                    notificationServiceConn.service?.updateNotificationSettings(settings)
                } else if (settings.batchedApps.isNotEmpty() || settings.storeNonBatchedToo) {
                    notificationServiceConn.setOnConnectedCallback { service: ComradeNotificationListenerService ->
                        service.updateNotificationSettings(settings)
                    }
                    notificationServiceConn.bindService()
                }

                /// Schedule batches
                if (settings.schedules.isNotEmpty()) {
                    scheduleNotificationBatchTask(context, settingsJson)
                } else {
                    cancelNotificationBatchTask(context)
                }

                result.success(true)
            }

            // ==============================================================================================================
            // ===================================== PERMISSIONS ============================================================
            // ==============================================================================================================

            "getAndAskAccessibilityPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskAccessibilityPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskAdminPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskAdminPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskUsageAccessPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskUsageAccessPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskIgnoreBatteryOptimizationPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskIgnoreBatteryOptimizationPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskDisplayOverlayPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskDisplayOverlayPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskExactAlarmPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskExactAlarmPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskNotificationPermission" -> {
                result.success(
                    activity?.let {
                        return@let PermissionsHelper.getAndAskNotificationPermission(
                            it,
                            call.arguments() ?: false
                        )
                    } ?: false
                )
            }

            "getAndAskDndPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskDndPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskNotificationAccessPermission" -> {
                result.success(
                    PermissionsHelper.getAndAskNotificationAccessPermission(
                        context,
                        call.arguments() ?: false
                    )
                )
            }

            "getAndAskVpnPermission" -> {
                result.success(getAndAskVpnPermission(call.arguments() ?: false))
            }

            // ==============================================================================================================
            // ====================================== UTILS =================================================================
            // ==============================================================================================================

            "disableDeviceAdmin" -> {
                NewActivitiesLaunchHelper.disableDeviceAdmin(context)
                result.success(true)
            }

            "promptForQuickTile" -> {
                NewActivitiesLaunchHelper.promptForQuickFocusTile(context, result)
            }

            "openAppWithPackage" -> {
                NewActivitiesLaunchHelper.openAppWithPackage(
                    context,
                    call.arguments() ?: ""
                )
                result.success(true)
            }

            "openAppWithNotificationThread" -> {
                val notification = Notification.fromJson(call.arguments() ?: "")
                NewActivitiesLaunchHelper.openAppWithNotificationThread(
                    context = context,
                    notification = notification,
                    pendingIntent = notificationServiceConn.service?.getPendingIntentForKey(
                        notification.key
                    ),
                )
                result.success(true)
            }

            "openAppSettingsForPackage" -> {
                NewActivitiesLaunchHelper.openSettingsForPackage(
                    context,
                    call.arguments() ?: ""
                )
                result.success(true)
            }

            "openDeviceDndSettings" -> {
                NewActivitiesLaunchHelper.openDeviceDndSettings(context)
                result.success(true)
            }

            "openAutoStartSettings" -> {
                result.success(NewActivitiesLaunchHelper.openAutoStartSettings(context))
            }

            "restartApp" -> {
                activity?.let {
                    NewActivitiesLaunchHelper.restartComrade(it)
                }
                result.success(true)
            }

            "launchUrl" -> {
                NewActivitiesLaunchHelper.launchUrl(context, call.arguments() ?: "")
                result.success(true)
            }

            "parseHostFromUrl" -> {
                result.success(Utils.parseHostNameFromUrl(call.arguments() ?: "") ?: "")
            }

            else -> result.notImplemented()
        }
    }


    /**
     * Updates app and group restrictions in the tracker service.
     * If the service is connected, sends updates directly; otherwise,
     * sets a callback to update once the connection is established and starts the service.
     *
     * @param appRestrictions   a map of app package names to their respective restrictions,
     * or null if only group restrictions are being updated.
     * @param restrictionGroups a map of restriction group IDs to their respective restrictions,
     * or null if only app-specific restrictions are being updated.
     */
    private fun updateTrackerServiceRestrictions(
        appRestrictions: HashMap<String, AppRestriction>?,
        restrictionGroups: HashMap<Int, RestrictionGroup>?,
    ) {
        if (trackerServiceConn.isActive) {
            trackerServiceConn.service?.getRestrictionManager?.updateRestrictions(
                appRestrictions,
                restrictionGroups
            )
        } else if (appRestrictions?.isNotEmpty() == true || restrictionGroups?.isNotEmpty() == true) {
            trackerServiceConn.setOnConnectedCallback { service ->
                service.getRestrictionManager.updateRestrictions(
                    appRestrictions,
                    restrictionGroups
                )
            }
            trackerServiceConn.startAndBind()
        }
    }

    /**
     * Checks if the Create VPN permission is granted and optionally asks for it if not granted.
     *
     * @param askPermissionToo Whether to prompt the user to enable Create VPN permission if not granted.
     * @return True if Create VPN permission is granted, false otherwise.
     */
    private fun getAndAskVpnPermission(askPermissionToo: Boolean): Boolean {
        val intent = VpnService.prepare(context)
        if (askPermissionToo && intent != null) {
            vpnPermLauncher?.launch(intent)
        }
        return intent == null
    }

}