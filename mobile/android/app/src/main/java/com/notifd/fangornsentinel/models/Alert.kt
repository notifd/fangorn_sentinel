package com.notifd.fangornsentinel.models

import androidx.compose.ui.graphics.Color
import java.time.Instant

enum class AlertSeverity {
    CRITICAL,
    WARNING,
    INFO;

    fun toColor(): Color {
        return when (this) {
            CRITICAL -> Color.Red
            WARNING -> Color(0xFFFF9800) // Orange
            INFO -> Color.Blue
        }
    }
}

enum class AlertStatus {
    FIRING,
    ACKNOWLEDGED,
    RESOLVED
}

data class Alert(
    val id: String,
    val title: String,
    val message: String? = null,
    val severity: AlertSeverity,
    val status: AlertStatus,
    val source: String? = null,
    val sourceId: String? = null,
    val labels: Map<String, String> = emptyMap(),
    val annotations: Map<String, String> = emptyMap(),
    val firedAt: Instant,
    val acknowledgedAt: Instant? = null,
    val resolvedAt: Instant? = null,
    val assignedToId: String? = null
)
