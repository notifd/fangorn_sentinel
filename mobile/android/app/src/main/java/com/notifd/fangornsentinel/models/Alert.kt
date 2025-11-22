package com.notifd.fangornsentinel.models

import java.time.Instant

data class Alert(
    val id: Int,
    val title: String,
    val message: String?,
    val severity: Severity,
    val status: Status,
    val firedAt: Instant,
    val acknowledgedAt: Instant? = null,
    val source: String? = null
) {
    enum class Severity {
        CRITICAL,
        WARNING,
        INFO;

        fun toColor(): androidx.compose.ui.graphics.Color {
            return when (this) {
                CRITICAL -> androidx.compose.ui.graphics.Color.Red
                WARNING -> androidx.compose.ui.graphics.Color(0xFFFF9800) // Orange
                INFO -> androidx.compose.ui.graphics.Color.Blue
            }
        }
    }

    enum class Status {
        FIRING,
        ACKNOWLEDGED,
        RESOLVED
    }
}
