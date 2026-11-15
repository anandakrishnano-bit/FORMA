package com.forma.app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.forma.app.MainActivity
import com.forma.app.R

class WorkoutWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "forma_widget_prefs"

        fun updateAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, WorkoutWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, appWidgetManager, id)
            }
        }

        private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val workoutName = prefs.getString("workout_name", "Rest & Recovery") ?: "Rest & Recovery"
            val workoutSub = prefs.getString("workout_sub", "No session scheduled") ?: "No session scheduled"
            val isWorkoutActive = prefs.getBoolean("workout_is_active", false)

            val views = RemoteViews(context.packageName, R.layout.widget_workout)
            views.setTextViewText(R.id.widget_workout_name, workoutName)
            views.setTextViewText(R.id.widget_workout_sub, workoutSub)
            views.setTextViewText(R.id.widget_workout_action, if (isWorkoutActive) "Resume Session →" else "Start Workout →")

            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("forma://app/workout")
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                102,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            views.setOnClickPendingIntent(R.id.widget_workout_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
