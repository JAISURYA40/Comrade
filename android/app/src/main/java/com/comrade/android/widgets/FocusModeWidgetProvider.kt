package com.comrade.android.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.comrade.android.R
import com.comrade.android.helpers.storage.SharedPrefsHelper
import com.comrade.android.models.FocusSession
import com.comrade.android.services.timer.FocusSessionService
import com.comrade.android.utils.AppUtils
import com.comrade.android.utils.Utils
import java.util.Locale
import kotlin.math.max

class FocusModeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "Comrade.FocusModeWidget"

        const val ACTION_START_FOCUS = "com.comrade.android.action.START_FOCUS_FROM_WIDGET"
        const val ACTION_STOP_FOCUS = "com.comrade.android.action.STOP_FOCUS_FROM_WIDGET"
        const val ACTION_REFRESH_WIDGET = "com.comrade.android.action.REFRESH_FOCUS_WIDGET"

        /**
         * Updates all instances of the Focus Mode widget on the user's home screen.
         */
        fun updateAllWidgets(context: Context, isActive: Boolean? = null, session: FocusSession? = null) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, FocusModeWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                if (appWidgetIds.isEmpty()) return

                val active = isActive ?: Utils.isServiceRunning(context, FocusSessionService::class.java)
                val views = buildRemoteViews(context, active, session)

                for (appWidgetId in appWidgetIds) {
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
            } catch (e: Exception) {
                Log.e(TAG, "updateAllWidgets: Failed to update widgets", e)
            }
        }

        private fun buildRemoteViews(
            context: Context,
            isActive: Boolean,
            session: FocusSession?,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_focus_mode_layout)

            val durationSecs = session?.durationSecs ?: SharedPrefsHelper.getFocusDurationSecs(context)
            val startTimeMs = session?.startTimeMsEpoch ?: SharedPrefsHelper.getActiveFocusStartTime(context)

            if (isActive) {
                // Active / Focusing state
                views.setTextViewText(
                    R.id.focus_status_text,
                    context.getString(R.string.widget_focus_mode_focusing)
                )

                if (durationSecs > 0) {
                    // Finite session countdown
                    val remainingMs = max(
                        0L,
                        (startTimeMs + durationSecs * 1000L) - System.currentTimeMillis()
                    )
                    val base = SystemClock.elapsedRealtime() + remainingMs

                    views.setViewVisibility(R.id.focus_time_text, View.GONE)
                    views.setViewVisibility(R.id.focus_chronometer, View.VISIBLE)
                    views.setChronometer(R.id.focus_chronometer, base, "%s", true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.focus_chronometer, true)
                    }
                } else {
                    // Infinite / count-up session
                    val elapsedMs = max(0L, System.currentTimeMillis() - startTimeMs)
                    val base = SystemClock.elapsedRealtime() - elapsedMs

                    views.setViewVisibility(R.id.focus_time_text, View.GONE)
                    views.setViewVisibility(R.id.focus_chronometer, View.VISIBLE)
                    views.setChronometer(R.id.focus_chronometer, base, "%s", true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.focus_chronometer, false)
                    }
                }

                // STOP Button
                views.setTextViewText(R.id.btn_focus_action, "⏹  " + context.getString(R.string.widget_focus_mode_stop))
                val stopPendingIntent = getBroadcastPendingIntent(context, ACTION_STOP_FOCUS)
                views.setOnClickPendingIntent(R.id.btn_focus_action, stopPendingIntent)

                // Root opens active session screen
                val rootPendingIntent = AppUtils.getPendingIntentForComradeUri(
                    context,
                    "com.comrade.android://open/activeSession"
                )
                views.setOnClickPendingIntent(R.id.widget_focus_root, rootPendingIntent)

            } else {
                // Inactive / Ready state
                views.setTextViewText(
                    R.id.focus_status_text,
                    context.getString(R.string.widget_focus_mode_label)
                )

                views.setViewVisibility(R.id.focus_chronometer, View.GONE)
                views.setChronometer(R.id.focus_chronometer, SystemClock.elapsedRealtime(), "%s", false)

                views.setViewVisibility(R.id.focus_time_text, View.VISIBLE)
                val minutes = durationSecs / 60
                val seconds = durationSecs % 60
                val formattedTime = String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)
                views.setTextViewText(R.id.focus_time_text, formattedTime)

                // START Button
                views.setTextViewText(R.id.btn_focus_action, "▶  " + context.getString(R.string.widget_focus_mode_start))
                val startPendingIntent = getBroadcastPendingIntent(context, ACTION_START_FOCUS)
                views.setOnClickPendingIntent(R.id.btn_focus_action, startPendingIntent)

                // Root opens focus mode settings screen
                val rootPendingIntent = AppUtils.getPendingIntentForComradeUri(
                    context,
                    "com.comrade.android://open/focus"
                )
                views.setOnClickPendingIntent(R.id.widget_focus_root, rootPendingIntent)
            }

            return views
        }

        private fun getBroadcastPendingIntent(context: Context, action: String): PendingIntent {
            val intent = Intent(context, FocusModeWidgetProvider::class.java).apply {
                this.action = action
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getBroadcast(context, action.hashCode(), intent, flags)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val isActive = Utils.isServiceRunning(context, FocusSessionService::class.java)
        val views = buildRemoteViews(context, isActive, null)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.d(TAG, "onReceive: action=$action")

        when (action) {
            ACTION_START_FOCUS -> {
                handleStartFocus(context)
            }

            ACTION_STOP_FOCUS -> {
                handleStopFocus(context)
            }

            ACTION_REFRESH_WIDGET,
            AppWidgetManager.ACTION_APPWIDGET_UPDATE,
            -> {
                updateAllWidgets(context)
            }

            else -> super.onReceive(context, intent)
        }
    }

    private fun handleStartFocus(context: Context) {
        if (Utils.isServiceRunning(context, FocusSessionService::class.java)) {
            updateAllWidgets(context, isActive = true)
            return
        }

        val durationSecs = SharedPrefsHelper.getFocusDurationSecs(context)
        val toggleDnd = SharedPrefsHelper.getFocusToggleDnd(context)
        val distractingApps = SharedPrefsHelper.getFocusDistractingApps(context)

        // If no distracting apps configured yet, open focus settings so the user can configure them
        if (distractingApps.isEmpty()) {
            val openIntent = AppUtils.getIntentForComradeUri(context, "com.comrade.android://open/focus").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(openIntent)
            return
        }

        val serviceIntent = Intent(context, FocusSessionService::class.java).apply {
            action = ACTION_START_FOCUS
            putExtra("durationSecs", durationSecs)
            putExtra("toggleDnd", toggleDnd)
            putStringArrayListExtra("distractingApps", ArrayList(distractingApps))
            putExtra("startTimeMsEpoch", System.currentTimeMillis())
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }

        // Optimistically update widget to active state
        val tempSession = FocusSession(
            toggleDnd = toggleDnd,
            startTimeMsEpoch = System.currentTimeMillis(),
            durationSecs = durationSecs,
            distractingApps = distractingApps
        )
        SharedPrefsHelper.setActiveFocusSession(context, tempSession.startTimeMsEpoch, tempSession.durationSecs)
        updateAllWidgets(context, isActive = true, session = tempSession)
    }

    private fun handleStopFocus(context: Context) {
        if (!Utils.isServiceRunning(context, FocusSessionService::class.java)) {
            SharedPrefsHelper.clearActiveFocusSession(context)
            updateAllWidgets(context, isActive = false)
            return
        }

        val stopIntent = Intent(context, FocusSessionService::class.java).apply {
            action = ACTION_STOP_FOCUS
        }

        context.startService(stopIntent)

        // Optimistically update widget to inactive state
        SharedPrefsHelper.clearActiveFocusSession(context)
        updateAllWidgets(context, isActive = false)
    }
}
