package com.notifd.fangornsentinel

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.google.firebase.messaging.FirebaseMessaging

class FangornSentinelApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // Create notification channel for critical alerts
        createNotificationChannel()

        // Get FCM token
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                println("Failed to get FCM token: ${task.exception}")
                return@addOnCompleteListener
            }

            val token = task.result
            println("FCM token: $token")

            // Register device with backend
            // TODO: Get actual user ID from auth
            val userId = getSharedPreferences("auth", MODE_PRIVATE)
                .getInt("user_id", 0)
            if (userId > 0) {
                registerDevice(token, userId)
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "critical_alerts",
                "Critical Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical on-call alerts"
                enableVibration(true)
                setShowBadge(true)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun registerDevice(token: String, userId: Int) {
        // TODO: Implement device registration
        println("Registering device: token=$token, userId=$userId")
    }
}
