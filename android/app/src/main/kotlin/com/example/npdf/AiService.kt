package com.example.npdf

import android.app.IntentService
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.ToneGenerator
import android.util.Log
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject
import android.app.NotificationManager

class AiService : IntentService("AiService") {

    override fun onHandleIntent(intent: Intent?) {
        val text = intent?.getStringExtra("text") ?: return

        try {
            val url = URL("https://msme.mlritcie.in/api/check-emergency") // Replace with the actual URL
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            conn.doOutput = true

            val json = JSONObject().apply {
                put("text", text)
            }

            OutputStreamWriter(conn.outputStream).use { writer ->
                writer.write(json.toString())
                writer.flush()
            }

            val code = conn.responseCode
            if (code == 200) {
                Log.d("🚨 AiService", "Emergency confirmed. Playing alert tone...")

                val emergencyIntent = Intent(this, MissedCallService::class.java).apply {
                    putExtra("isEmergency", true)
                }
                startService(emergencyIntent)

                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?
                if (nm != null && nm.isNotificationPolicyAccessGranted) {
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
                    Thread.sleep(500)

                    val toneGen = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                    repeat(3) {
                        toneGen.startTone(ToneGenerator.TONE_CDMA_ABBR_ALERT, 1000)
                        Thread.sleep(1500)
                    }

                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                    Log.d("🔕 AiService", "DND restored after alert.")
                } else {
                    Log.e("🚨 AiService", "No DND access – can't override to play alert.")
                }
            } else {
                Log.d("🤖 AiService", "Message not classified as emergency (code $code)")
            }

        } catch (e: Exception) {
            Log.e("🔥 AiService", "Error calling AI or playing alert", e)
        }
    }
}
