package com.khanhromvn.fluency

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONObject

class FluencyNotificationListenerService : NotificationListenerService() {
    companion object {
        private const val TAG = "NotificationListener"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NotificationListenerService created")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            Log.d(TAG, "Received notification from package: ${sbn.packageName}")
            
            val notification = sbn.notification
            val extras = notification.extras
            val title = extras.getString("android.title")
            val text = extras.getString("android.text")
            
            Log.d(TAG, "Raw notification data - Title: $title, Text: $text")
            
            // Try to parse OneSignal custom data
            var customData: JSONObject? = null
            var oneSignalId: String? = null
            
            if (sbn.packageName.contains("onesignal") || extras.getString("custom") != null) {
                try {
                    val customString = extras.getString("custom")
                    Log.d(TAG, "OneSignal custom data: $customString")
                    
                    if (customString != null) {
                        customData = JSONObject(customString)
                        oneSignalId = customData.optString("i")
                        Log.d(TAG, "Parsed OneSignal ID: $oneSignalId")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing OneSignal custom data: ${e.message}")
                }
            }

            val notificationData = mapOf(
                "id" to (oneSignalId ?: sbn.id.toString()),
                "packageName" to sbn.packageName,
                "postTime" to sbn.postTime,
                "title" to title,
                "text" to (text ?: extras.getString("android.bigText")),
                "alert" to extras.getString("alert"),
                "category" to notification.category,
                "extras" to extras.toString()
            )

            Log.d(TAG, "Sending notification to Flutter: $notificationData")
            
            // Send to Flutter through the plugin
            NotificationListenerPlugin.getPluginInstance().sendNotificationToFlutter(notificationData)
            
            Log.d(TAG, "Notification successfully sent to Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListenerService connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListenerService disconnected")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "NotificationListenerService destroyed")
    }
}