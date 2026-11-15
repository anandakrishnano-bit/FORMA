package com.forma.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.forma.app.widgets.BudgetWidgetProvider
import com.forma.app.widgets.DailyActivityWidgetProvider
import com.forma.app.widgets.WorkoutWidgetProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val LIVE_UPDATES_CHANNEL = "com.forma.app/live_updates"
    private val WIDGETS_CHANNEL = "com.forma.app/home_widgets"
    private val APP_ICON_CHANNEL = "com.forma.app/app_icon"

    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "forma_live_workout"
    private val WIDGET_PREFS = "forma_widget_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        // 1. Android 16 Live Workout Notifications Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_UPDATES_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startWorkoutLiveUpdate" -> {
                    val title = call.argument<String>("title") ?: "Active Workout"
                    val exerciseName = call.argument<String>("exerciseName") ?: "Workout in progress"
                    val progressFraction = call.argument<Double>("progressFraction") ?: 0.0
                    val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0

                    showLiveWorkoutNotification(title, exerciseName, progressFraction, elapsedSeconds)
                    result.success(true)
                }
                "updateWorkoutLiveUpdate" -> {
                    val title = call.argument<String>("title") ?: "Active Workout"
                    val exerciseName = call.argument<String>("exerciseName") ?: "Workout in progress"
                    val progressFraction = call.argument<Double>("progressFraction") ?: 0.0
                    val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0

                    showLiveWorkoutNotification(title, exerciseName, progressFraction, elapsedSeconds)
                    result.success(true)
                }
                "stopWorkoutLiveUpdate" -> {
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancel(NOTIFICATION_ID)
                    result.success(true)
                }
                "getDiagnostics" -> {
                    val areNotificationsEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
                    val isAndroid16 = Build.VERSION.SDK_INT >= 36
                    val diagnostics = mapOf(
                        "apiLevel" to Build.VERSION.SDK_INT,
                        "isAndroid16" to isAndroid16,
                        "promotedSupported" to isAndroid16,
                        "notificationsEnabled" to areNotificationsEnabled,
                        "channelId" to CHANNEL_ID
                    )
                    result.success(diagnostics)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Android Native Home Screen Widgets Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGETS_CHANNEL).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
            when (call.method) {
                "updateDailyActivityWidget" -> {
                    val date = call.argument<String>("date") ?: "TODAY"
                    val steps = call.argument<Int>("steps") ?: 0
                    val score = call.argument<String>("energyScore") ?: "--"
                    val workoutStatus = call.argument<String>("workoutStatus") ?: "Workout: Not started"

                    prefs.edit()
                        .putString("activity_date", date)
                        .putInt("activity_steps", steps)
                        .putString("activity_score", score)
                        .putString("activity_workout_status", workoutStatus)
                        .apply()

                    DailyActivityWidgetProvider.updateAll(this)
                    result.success(true)
                }
                "updateWorkoutWidget" -> {
                    val name = call.argument<String>("workoutName") ?: "Rest & Recovery"
                    val sub = call.argument<String>("workoutSub") ?: "No session scheduled"
                    val isActive = call.argument<Boolean>("isActive") ?: false

                    prefs.edit()
                        .putString("workout_name", name)
                        .putString("workout_sub", sub)
                        .putBoolean("workout_is_active", isActive)
                        .apply()

                    WorkoutWidgetProvider.updateAll(this)
                    result.success(true)
                }
                "updateBudgetWidget" -> {
                    val allowance = call.argument<String>("allowance") ?: "₹0/day"
                    val details = call.argument<String>("details") ?: "0 days remaining • ₹0 balance"
                    val isRedacted = call.argument<Boolean>("isRedacted") ?: false

                    prefs.edit()
                        .putString("budget_allowance", allowance)
                        .putString("budget_details", details)
                        .putBoolean("budget_is_redacted", isRedacted)
                        .apply()

                    BudgetWidgetProvider.updateAll(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Dynamic App Icon Channel (Activity Aliases)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_ICON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAppIcon" -> {
                    val iconName = call.argument<String>("iconName") ?: "Default"
                    val success = setDynamicAppIcon(iconName)
                    result.success(success)
                }
                "getCurrentAppIcon" -> {
                    val current = getCurrentAppIcon()
                    result.success(current)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setDynamicAppIcon(targetName: String): Boolean {
        val aliases = listOf("Default", "Chest", "Back", "Legs", "Arms", "Rest")
        val safeTarget = if (aliases.contains(targetName)) targetName else "Default"
        val targetComponent = "com.forma.app.MainActivity$safeTarget"

        try {
            for (alias in aliases) {
                val fullAliasName = "com.forma.app.MainActivity$alias"
                val component = ComponentName(packageName, fullAliasName)
                val targetState = if (fullAliasName == targetComponent) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }
                packageManager.setComponentEnabledSetting(
                    component,
                    targetState,
                    PackageManager.DONT_KILL_APP
                )
            }
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun getCurrentAppIcon(): String {
        val aliases = listOf("Default", "Chest", "Back", "Legs", "Arms", "Rest")
        for (alias in aliases) {
            val component = ComponentName(packageName, "com.forma.app.MainActivity$alias")
            val state = packageManager.getComponentEnabledSetting(component)
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                return alias
            }
        }
        return "Default"
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Live Workout Tracker"
            val descriptionText = "Promoted real-time live updates for active FORMA workouts"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showLiveWorkoutNotification(
        title: String,
        exerciseName: String,
        progressFraction: Double,
        elapsedSeconds: Int
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val progressPercent = (progressFraction * 100).toInt().coerceIn(0, 100)
        val chronometerBase = SystemClock.elapsedRealtime() - (elapsedSeconds * 1000L)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(exerciseName)
            .setSubText("$progressPercent% complete")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setWhen(chronometerBase)
            .setProgress(100, progressPercent, false)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)

        // Android 16 (API 36+) Promoted notification configuration
        if (Build.VERSION.SDK_INT >= 36) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }
}
