package com.notifd.fangornsentinel.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.font.FontWeight
import com.notifd.fangornsentinel.models.Alert
import com.notifd.fangornsentinel.models.AlertStatus
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertListScreen(
    alerts: List<Alert>,
    onAlertClick: (Alert) -> Unit,
    onRefresh: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Alerts") },
                actions = {
                    IconButton(onClick = { /* TODO: Show filter */ }) {
                        Icon(Icons.Default.FilterList, contentDescription = "Filter")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            items(alerts) { alert ->
                AlertRow(
                    alert = alert,
                    onClick = { onAlertClick(alert) }
                )
                Divider()
            }
        }
    }
}

@Composable
fun AlertRow(
    alert: Alert,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Severity indicator
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(
                        color = alert.severity.toColor(),
                        shape = CircleShape
                    )
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Alert info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = alert.title,
                    style = MaterialTheme.typography.titleMedium
                )

                if (alert.message != null) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = alert.message,
                        style = MaterialTheme.typography.bodyMedium,
                        maxLines = 2,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = alert.firedAt.toRelativeTime(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Status icon
            if (alert.status == AlertStatus.FIRING) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "Firing",
                    tint = Color.Red
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertDetailScreen(
    alert: Alert,
    onAcknowledge: () -> Unit,
    onBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Alert Details") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            // Header
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .background(
                            color = alert.severity.toColor(),
                            shape = CircleShape
                        )
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = alert.title,
                    style = MaterialTheme.typography.headlineSmall
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Message
            if (alert.message != null) {
                Text(
                    text = alert.message,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Metadata
            Card {
                Column(modifier = Modifier.padding(16.dp)) {
                    MetadataRow("Severity", alert.severity.name.lowercase().capitalize())
                    Divider(modifier = Modifier.padding(vertical = 8.dp))
                    MetadataRow("Status", alert.status.name.lowercase().capitalize())
                    Divider(modifier = Modifier.padding(vertical = 8.dp))
                    MetadataRow("Fired At", alert.firedAt.toFormattedString())
                    if (alert.source != null) {
                        Divider(modifier = Modifier.padding(vertical = 8.dp))
                        MetadataRow("Source", alert.source)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Actions
            if (alert.status == AlertStatus.FIRING) {
                Button(
                    onClick = onAcknowledge,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Acknowledge Alert")
                }
            }
        }
    }
}

@Composable
fun MetadataRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

// Extension functions
fun Instant.toRelativeTime(): String {
    val now = Instant.now()
    val seconds = now.epochSecond - this.epochSecond

    return when {
        seconds < 60 -> "just now"
        seconds < 3600 -> "${seconds / 60}m ago"
        seconds < 86400 -> "${seconds / 3600}h ago"
        else -> "${seconds / 86400}d ago"
    }
}

fun Instant.toFormattedString(): String {
    val formatter = DateTimeFormatter.ofPattern("MMM dd, yyyy HH:mm")
        .withZone(ZoneId.systemDefault())
    return formatter.format(this)
}
