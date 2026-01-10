package com.allapalli.allapalli_ride

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras
            if (bundle != null) {
                try {
                    val pdus = bundle.get("pdus") as Array<*>
                    for (pdu in pdus) {
                        val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray)
                        val messageBody = smsMessage.messageBody
                        
                        // Extract OTP from message (looking for 6-digit codes)
                        val otpPattern = Regex("\\b\\d{6}\\b")
                        val matchResult = otpPattern.find(messageBody)
                        
                        if (matchResult != null) {
                            val otp = matchResult.value
                            Log.d("SmsReceiver", "OTP detected: $otp")
                            
                            // Broadcast OTP to Flutter app
                            val otpIntent = Intent("SMS_OTP_RECEIVED")
                            otpIntent.putExtra("otp", otp)
                            context.sendBroadcast(otpIntent)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("SmsReceiver", "Error processing SMS", e)
                }
            }
        }
    }
}
