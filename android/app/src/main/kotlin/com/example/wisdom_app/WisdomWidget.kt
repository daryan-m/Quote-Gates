package com.example.wisdom_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.wisdom_app.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class WisdomWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )

            // ── خوێندنەوەی داتا لە SharedPreferences ───────────────────
            val tasks   = getCountFromPrefs(prefs, "flutter.wisdom_tasks")
            val notes   = getCountFromPrefs(prefs, "flutter.user_notes")
            val reminders = getCountFromPrefs(prefs, "flutter.user_reminders")
            val label   = getCurrentLabel(prefs)

            // ── ئەپی کردنەوە ──────────────────────────────────────────
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // ── ویدجێتی ئاسۆیی ──────────────────────────────────────
            val viewsH = RemoteViews(context.packageName, R.layout.widget_horizontal)
            viewsH.setOnClickPendingIntent(R.id.widget_root_h, pendingIntent)
            viewsH.setTextViewText(R.id.tv_tasks_h,     tasks.toString())
            viewsH.setTextViewText(R.id.tv_notes_h,     notes.toString())
            viewsH.setTextViewText(R.id.tv_reminders_h, reminders.toString())
            viewsH.setTextViewText(R.id.tv_label_h,     label)

            // ── ویدجێتی ستونی ───────────────────────────────────────
            val viewsV = RemoteViews(context.packageName, R.layout.widget_vertical)
            viewsV.setOnClickPendingIntent(R.id.widget_root_v, pendingIntent)
            viewsV.setTextViewText(R.id.tv_tasks_v,     tasks.toString())
            viewsV.setTextViewText(R.id.tv_notes_v,     notes.toString())
            viewsV.setTextViewText(R.id.tv_reminders_v, reminders.toString())
            viewsV.setTextViewText(R.id.tv_label_v,     label)

            // ── هەڵبژاردنی شێوازی ویدجێت ───────────────────────────
            val widgetInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
            val minW = widgetInfo?.minWidth ?: 0
            val minH = widgetInfo?.minHeight ?: 0
            val views = if (minH > minW) viewsV else viewsH

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // ── ژمارەکردنی دانەکان لە JSON ──────────────────────────────────
        private fun getCountFromPrefs(prefs: SharedPreferences, key: String): Int {
            return try {
                val raw = prefs.getString(key, null) ?: return 0
                JSONArray(raw).length()
            } catch (e: Exception) {
                0
            }
        }

        // ── لەیبڵی ئێستا (وتە یان ڕووداو) ─────────────────────────────
        private fun getCurrentLabel(prefs: SharedPreferences): String {
            val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            val minute = Calendar.getInstance().get(Calendar.MINUTE)

            // کاتژمێرەکانی بەردەست: ٨، ٩:٤٠، ١١:٢٠، ١، ٢:٤٠، ٤:٢٠، ٦، ٧:٤٠، ٩:٢٠
            val slots = listOf(
                8 * 60,        // 08:00
                9 * 60 + 40,   // 09:40
                11 * 60 + 20,  // 11:20
                13 * 60,       // 13:00
                14 * 60 + 40,  // 14:40
                16 * 60 + 20,  // 16:20
                18 * 60,       // 18:00
                19 * 60 + 40,  // 19:40
                21 * 60 + 20   // 21:20
            )

            val currentMinutes = hour * 60 + minute
            val slotIndex = slots.indexOfLast { it <= currentMinutes }
                .coerceAtLeast(0)

            // ٣ وتە، ٣ ڕووداو، ٣ ئاگاداری
            return when (slotIndex % 3) {
                0 -> getRandomQuote(prefs)
                1 -> getHistoryFact(slotIndex / 3)
                else -> getRandomReminder(prefs)
            }
        }

        private fun getRandomQuote(prefs: SharedPreferences): String {
            return try {
                val raw = prefs.getString("flutter.daily_quote", null)
                if (raw != null) {
                    val obj = JSONObject(raw)
                    "\"${obj.getString("text")}\" — ${obj.getString("author")}"
                } else {
                    "✨ Wisdom Gates"
                }
            } catch (e: Exception) {
                "✨ Open the app for today's quote"
            }
        }

        private fun getHistoryFact(index: Int): String {
            val facts = listOf(
                "🗓 On this day in 1969, Apollo 11 launched toward the Moon.",
                "🗓 Einstein published his Theory of Relativity in 1905.",
                "🗓 The first iPhone was unveiled by Steve Jobs in 2007.",
                "🗓 The Berlin Wall fell on November 9, 1989.",
                "🗓 The World Wide Web was invented by Tim Berners-Lee in 1989.",
                "🗓 Nelson Mandela became President of South Africa in 1994.",
            )
            return facts[index % facts.size]
        }

        private fun getRandomReminder(prefs: SharedPreferences): String {
            return try {
                val raw = prefs.getString("flutter.user_reminders", null)
                    ?: return "🔔 No reminders set"
                val arr = JSONArray(raw)
                if (arr.length() == 0) return "🔔 No reminders set"
                val obj = arr.getJSONObject((0 until arr.length()).random())
                "🔔 ${obj.getString("title")}"
            } catch (e: Exception) {
                "🔔 Check your reminders"
            }
        }
    }
}