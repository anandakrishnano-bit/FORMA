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

class DailyActivityWidgetProvider : AppWidgetProvider() {

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
                ComponentName(context, DailyActivityWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, appWidgetManager, id)
            }
        }

        private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val dateStr = prefs.getString("activity_date", "TODAY") ?: "TODAY"
            val steps = prefs.getInt("activity_steps", 0)
            val score = prefs.getString("activity_score", "--") ?: "--"
            val workoutStatus = prefs.getString("activity_workout_status", "Workout: Not started") ?: "Workout: Not started"

            val views = RemoteViews(context.packageName, R.layout.widget_daily_activity)
            views.setTextViewText(R.id.widget_activity_date, dateStr.uppercase())
            views.setTextViewText(R.id.widget_activity_score, if (score == "--") "ENERGY --" else "ENERGY $score")
            views.setTextViewText(R.id.widget_activity_steps, "$steps steps")
            views.setTextViewText(R.id.widget_activity_workout_status, workoutStatus)

            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("forma://app/activity-calendar")
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                101,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            views.setOnClickPendingIntent(R.id.widget_daily_activity_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
