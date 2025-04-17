package com.example.npdf

import android.app.IntentService
import android.content.Intent
import android.util.Log
import android.app.NotificationManager
import android.content.Context
import android.telephony.SmsManager
import android.content.SharedPreferences
import android.os.Handler
import android.preference.PreferenceManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MissedCallService : IntentService("MissedCallService") {

    companion object {
        private const val CHANNEL = "com.example.npdf/missed_calls"
    }

    override fun onHandleIntent(intent: Intent?) {
        if (intent == null) return

        val number = intent.getStringExtra("number")
        val status = intent.getStringExtra("status")
        val isEmergency = intent.getBooleanExtra("isEmergency", false)
        Log.e("Emergency: ", isEmergency.toString())

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?

        if (number == null || status == null) {
            Log.e("📲 MissedCallService", "⚠️ Missing number or status")
            return
        }

        if (notificationManager != null &&
            notificationManager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE
        ) {
            Log.d("📲 MissedCallService", "🔕 DND is ON. Sending SMS to $number")

            try {
                val prefs = PreferenceManager.getDefaultSharedPreferences(this)
                val message = prefs.getString(
                    "customReply",
                    "I'm driving right now. If it's an emergency, reply with details."
                )

                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(number, null, message, null, null)

                Log.d("📲 MissedCallService", "📤 SMS sent.")
            } catch (e: Exception) {
                Log.e("📲 MissedCallService", "❌ SMS sending failed", e)
            }
        }

        Log.e("Emergency: ", isEmergency.toString())

        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        prefs.edit().putString("lastMissedCallNumber", number).apply()

        sendMissedCallToFlutter(number, isEmergency)
    }

    private fun sendMissedCallToFlutter(number: String?, isEmergency: Boolean) {
        val engine: FlutterEngine? = FlutterEngineCache.getInstance().get("main_engine")

        if (engine != null) {
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val timestamp = System.currentTimeMillis()

            Handler(mainLooper).post {
                channel.invokeMethod("storeMissedCall", hashMapOf(
                    "id" to timestamp.toString(),
                    "type" to "call",
                    "name" to null,
                    "number" to number,
                    "timestamp" to timestamp,
                    "isEmergency" to isEmergency
                ))
            }
        } else {
            Log.e("📲 MissedCallService", "❌ FlutterEngine not available. Missed call not stored.")
        }
    }
}
