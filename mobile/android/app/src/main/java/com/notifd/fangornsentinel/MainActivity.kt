package com.notifd.fangornsentinel

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.notifd.fangornsentinel.models.Alert
import com.notifd.fangornsentinel.models.AlertSeverity
import com.notifd.fangornsentinel.models.AlertStatus
import com.notifd.fangornsentinel.ui.AlertListScreen
import com.notifd.fangornsentinel.ui.theme.FangornSentinelTheme
import java.time.Instant

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle notification tap
        val alertId = intent.getIntExtra("alert_id", -1)
        if (alertId > 0) {
            // TODO: Navigate to alert detail
            println("Opened from notification: alert_id=$alertId")
        }

        setContent {
            FangornSentinelTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen()
                }
            }
        }
    }
}

@Composable
fun MainScreen() {
    // TODO: Replace with actual ViewModel
    var alerts by remember {
        mutableStateOf(
            listOf(
                Alert(
                    id = "1",
                    title = "High CPU Usage",
                    message = "CPU usage is above 90%",
                    severity = AlertSeverity.CRITICAL,
                    status = AlertStatus.FIRING,
                    firedAt = Instant.now().minusSeconds(300)
                ),
                Alert(
                    id = "2",
                    title = "Memory Warning",
                    message = "Memory usage at 85%",
                    severity = AlertSeverity.WARNING,
                    status = AlertStatus.FIRING,
                    firedAt = Instant.now().minusSeconds(600)
                )
            )
        )
    }

    AlertListScreen(
        alerts = alerts,
        onAlertClick = { alert ->
            // TODO: Navigate to detail screen
            println("Clicked alert: ${alert.id}")
        },
        onRefresh = {
            // TODO: Refresh alerts from API
            println("Refreshing alerts...")
        }
    )
}
