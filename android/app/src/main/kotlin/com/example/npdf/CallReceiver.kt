package com.example.npdf

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {

    companion object {
        private var ringing = false
    }

    override fun onReceive(context: Context, intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        Log.d("📲 CallReceiver", "State: $state, Number: $incomingNumber")

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                ringing = true
                Log.d("📲 CallReceiver", "📞 Incoming call ringing from: $incomingNumber")

                val serviceIntent = Intent(context, MissedCallService::class.java).apply {
                    putExtra("number", incomingNumber)
                    putExtra("status", "incoming")
                }
                context.startService(serviceIntent)
            }

            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                Log.d("📲 CallReceiver", "✅ Call answered")
                ringing = false
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                if (ringing) {
                    Log.d("📲 CallReceiver", "❌ Missed call from: $incomingNumber")

                    val serviceIntent = Intent(context, MissedCallService::class.java).apply {
                        putExtra("number", incomingNumber)
                        putExtra("status", "missed")
                    }
                    context.startService(serviceIntent)

                    ringing = false
                }
            }
        }
    }
}
