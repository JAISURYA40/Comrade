/*
 *
 *  *
 *  *  * Copyright (c) 2024 Comrade (https://github.com/akaMrNagar/Comrade)
 *  *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *  *
 *  *  * This source code is licensed under the GPL-2.0 license license found in the
 *  *  * LICENSE file in the root directory of this source tree.
 *  *
 *
 */
package com.comrade.android.services.timer

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import com.comrade.android.AppConstants.EMERGENCY_PAUSE_SERVICE_NOTIFICATION_ID
import com.comrade.android.R
import com.comrade.android.generics.SafeServiceConnection
import com.comrade.android.generics.ServiceBinder
import com.comrade.android.helpers.device.NotificationHelper.CRITICAL_CHANNEL_ID
import com.comrade.android.helpers.storage.SharedPrefsHelper
import com.comrade.android.services.tracking.ComradeTrackerService
import com.comrade.android.utils.AppUtils
import com.comrade.android.utils.DateTimeUtils

class EmergencyPauseService : Service() {
    private lateinit var mNotificationTimer: NotificationTimer
    private lateinit var mTrackerServiceConn: SafeServiceConnection<ComradeTrackerService>

    override fun onCreate() {
        mTrackerServiceConn = SafeServiceConnection(
            context = this,
            serviceClass = ComradeTrackerService::class.java
        )
        mNotificationTimer = NotificationTimer(
            context = this,
            ongoingPendingIntent = AppUtils.getPendingIntentForComradeUri(this),
            title = getString(R.string.emergency_pause_notification_title),
            timerDurationSeconds = DEFAULT_EMERGENCY_PASS_PERIOD_SECONDS,
            notificationId = EMERGENCY_PAUSE_SERVICE_NOTIFICATION_ID,
            notificationChannelId = CRITICAL_CHANNEL_ID,
            onTicked = { remainingTime ->
                getString(
                    R.string.emergency_pause_notification_info,
                    DateTimeUtils.secondsToTimeStr(remainingTime)
                )
            },
            onFinished = { getString(R.string.emergency_pause_ended_notification_info) },
            onDispose = {
                Log.d(
                    TAG,
                    "startEmergencyTimer: Emergency pause is over. App blocker is resumed successfully"
                )
                stopSelf()
            }
        )
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ServiceBinder.ACTION_START_COMRADE_SERVICE) {
            startEmergencyTimer()
            return START_STICKY
        }

        stopSelf()
        return START_NOT_STICKY
    }

    private fun startEmergencyTimer() {
        try {
            startForeground(
                EMERGENCY_PAUSE_SERVICE_NOTIFICATION_ID,
                mNotificationTimer.getInitialNotification
            )

            mTrackerServiceConn.setOnConnectedCallback { service: ComradeTrackerService ->
                service.getLaunchTrackingManager.pauseResumeTracking(true)
            }
            mTrackerServiceConn.bindService()
            mNotificationTimer.startTimer()
            Log.d(TAG, "startEmergencyTimer: EMERGENCY service started successfully")
        } catch (e: Exception) {
            Log.d(TAG, "startEmergencyTimer: Failed to start EMERGENCY service: ", e)
            SharedPrefsHelper.insertCrashLogToPrefs(this, e)
            stopSelf()
        }
    }


    override fun onDestroy() {
        mTrackerServiceConn.service?.getLaunchTrackingManager?.pauseResumeTracking(false)
        mTrackerServiceConn.unBindService()
        stopForeground(STOP_FOREGROUND_REMOVE)
        Log.d(TAG, "onDestroy: EMERGENCY service destroyed successfully")
        super.onDestroy()
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    companion object {
        private const val DEFAULT_EMERGENCY_PASS_PERIOD_SECONDS: Long = 5 * 60L
        private const val TAG = "Comrade.EmergencyPauseService"
    }
}