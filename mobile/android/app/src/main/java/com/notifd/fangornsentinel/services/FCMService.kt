package com.notifd.fangornsentinel.services

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.notifd.fangornsentinel.MainActivity
import com.notifd.fangornsentinel.R

class FCMService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("New FCM token: $token")

        // Register with backend
        // TODO: Get user ID and register device
        val userId = getSharedPreferences("auth", Context.MODE_PRIVATE)
            .getInt("user_id", 0)
        if (userId > 0) {
            registerDevice(token, userId)
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        // Extract alert data
        val alertId = message.data["alert_id"]?.toIntOrNull()
        val severity = message.data["severity"]
        val title = message.notification?.title ?: "New Alert"
        val body = message.notification?.body ?: ""

        // Show notification
        showNotification(alertId, title, body, severity)
    }

    private fun showNotification(
        alertId: Int?,
        title: String,
        body: String,
        severity: String?
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("alert_id", alertId)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, "critical_alerts")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(alertId ?: 0, notification)
    }

    private fun registerDevice(token: String, userId: Int) {
        // TODO: Implement device registration API call
        println("Registering device: token=$token, userId=$userId")
    }
}
