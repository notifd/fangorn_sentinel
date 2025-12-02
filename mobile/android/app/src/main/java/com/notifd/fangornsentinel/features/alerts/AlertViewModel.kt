package com.notifd.fangornsentinel.features.alerts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.notifd.fangornsentinel.models.Alert
import com.notifd.fangornsentinel.models.AlertSeverity
import com.notifd.fangornsentinel.models.AlertStatus
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.Instant
import javax.inject.Inject

data class AlertsUiState(
    val alerts: List<Alert> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class AlertViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow(AlertsUiState())
    val uiState: StateFlow<AlertsUiState> = _uiState.asStateFlow()

    init {
        loadAlerts()
    }

    fun loadAlerts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)

            // TODO: Replace with actual API call
            val mockAlerts = listOf(
                Alert(
                    id = "1",
                    title = "High CPU Usage",
                    message = "Server prod-web-01 CPU usage exceeded 90%",
                    severity = AlertSeverity.CRITICAL,
                    status = AlertStatus.FIRING,
                    source = "prometheus",
                    firedAt = Instant.now().minusSeconds(300)
                ),
                Alert(
                    id = "2",
                    title = "Disk Space Warning",
                    message = "Server prod-db-01 disk usage at 85%",
                    severity = AlertSeverity.WARNING,
                    status = AlertStatus.FIRING,
                    source = "grafana",
                    firedAt = Instant.now().minusSeconds(1800)
                ),
                Alert(
                    id = "3",
                    title = "Service Health Check",
                    message = "API endpoint /health returned 200",
                    severity = AlertSeverity.INFO,
                    status = AlertStatus.RESOLVED,
                    source = "grafana",
                    firedAt = Instant.now().minusSeconds(7200)
                )
            )

            _uiState.value = AlertsUiState(alerts = mockAlerts, isLoading = false)
        }
    }

    fun acknowledgeAlert(alertId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                alerts = _uiState.value.alerts.map { alert ->
                    if (alert.id == alertId) {
                        alert.copy(status = AlertStatus.ACKNOWLEDGED)
                    } else {
                        alert
                    }
                }
            )
            // TODO: Call API to acknowledge alert
        }
    }

    fun resolveAlert(alertId: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                alerts = _uiState.value.alerts.map { alert ->
                    if (alert.id == alertId) {
                        alert.copy(status = AlertStatus.RESOLVED)
                    } else {
                        alert
                    }
                }
            )
            // TODO: Call API to resolve alert
        }
    }
}
