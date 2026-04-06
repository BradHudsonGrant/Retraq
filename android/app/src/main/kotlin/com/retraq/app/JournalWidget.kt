package com.retraq.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class JournalWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.journal_widget)

            val streak = widgetData.getInt("streak", 0)
            val totalEntries = widgetData.getInt("totalEntries", 0)
            val mood = widgetData.getInt("mood", -1)

            // Streak text
            val streakText = if (streak == 1) "1 day streak" else "$streak day streak"
            views.setTextViewText(R.id.widget_streak, streakText)

            // Total entries
            val entriesText = if (totalEntries == 1) "1 traq" else "$totalEntries traqs"
            views.setTextViewText(R.id.widget_entries, entriesText)

            // Mood (show only when set)
            if (mood in 1..5) {
                val moodEmojis = arrayOf("😢", "😔", "😐", "😊", "🤩")
                val moodLabels = arrayOf("Rough", "Low", "Neutral", "Good", "Amazing")
                views.setTextViewText(
                    R.id.widget_mood,
                    "Today: ${moodEmojis[mood - 1]} ${moodLabels[mood - 1]}"
                )
                views.setViewVisibility(R.id.widget_mood, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_mood, View.GONE)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
