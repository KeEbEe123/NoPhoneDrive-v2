package com.example.npdf

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import android.util.Log
import android.preference.PreferenceManager
import android.os.Handler
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {

    companion object {
        private const val CHANNEL = "com.example.npdf/missed_calls"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val bundle: Bundle = intent.extras ?: return
        val pdus = bundle["pdus"] as? Array<*> ?: return

        for (pdu in pdus) {
            val sms = SmsMessage.createFromPdu(pdu as ByteArray)
            val message = sms.messageBody
            val sender = sms.originatingAddress

            Log.d("📩 SMSReceiver", "From: $sender, Message: $message")

            // ✅ Start AI Service
            val aiIntent = Intent(context, AiService::class.java).apply {
                putExtra("text", message)
            }
            context.startService(aiIntent)

            // ✅ Check if sender matches last missed call
            val prefs = PreferenceManager.getDefaultSharedPreferences(context)
            val lastMissed = prefs.getString("lastMissedCallNumber", null)

            if (!lastMissed.isNullOrEmpty() && normalize(sender ?: "").contains(normalize(lastMissed))) {
                Log.d("📩 SMSReceiver", "🚨 Emergency confirmed! Storing call.")

                sendToFlutter(context, sender ?: "", true)

                // Clear cache
                prefs.edit().remove("lastMissedCallNumber").apply()
            }
        }
    }

    private fun sendToFlutter(context: Context, number: String, isEmergency: Boolean) {
        val engine: FlutterEngine? = FlutterEngineCache.getInstance().get("main_engine")

        if (engine != null) {
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            val timestamp = System.currentTimeMillis()

            Handler(context.mainLooper).post {
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
            Log.e("📩 SMSReceiver", "❌ FlutterEngine not available.")
        }
    }

    private fun normalize(number: String): String {
        return number.replace(Regex("[^\\d+]"), "")
    }
}
