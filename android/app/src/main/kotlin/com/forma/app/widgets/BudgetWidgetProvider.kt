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

class BudgetWidgetProvider : AppWidgetProvider() {

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
                ComponentName(context, BudgetWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, appWidgetManager, id)
            }
        }

        private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val isRedacted = prefs.getBoolean("budget_is_redacted", false)
            val allowance = prefs.getString("budget_allowance", "₹0/day") ?: "₹0/day"
            val details = prefs.getString("budget_details", "0 days remaining • ₹0 balance") ?: "0 days remaining • ₹0 balance"

            val views = RemoteViews(context.packageName, R.layout.widget_budget)
            if (isRedacted) {
                views.setTextViewText(R.id.widget_budget_allowance, "₹ ••• /day")
                views.setTextViewText(R.id.widget_budget_details, "Biometric privacy protected")
            } else {
                views.setTextViewText(R.id.widget_budget_allowance, allowance)
                views.setTextViewText(R.id.widget_budget_details, details)
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("forma://app/expenses")
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                103,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )
            views.setOnClickPendingIntent(R.id.widget_budget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
