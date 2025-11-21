# Claude Development Guidelines - Fangorn Sentinel

This document provides comprehensive guidance for AI assistants working on Fangorn Sentinel - an open-source on-call notification system with mobile apps, web dashboard, Grafana plugin, and extensible API.

## Project Overview

**Fangorn Sentinel** is an open-source replacement for Grafana OnCall, providing comprehensive on-call management with native mobile apps, real-time web dashboard, and plugin ecosystem.

### Core Purpose

Fangorn Sentinel provides:
- **Alert Reception**: Receive alerts from Grafana, webhooks, API
- **Intelligent Routing**: Route alerts based on schedules, escalation policies
- **Multi-channel Notifications**: Push, SMS, phone calls, email, Slack
- **Mobile Apps**: Native iOS and Android apps for on-call engineers
- **Web Dashboard**: Real-time alert management and configuration
- **Plugin System**: Extensible architecture for integrations
- **Grafana Plugin**: Drop-in replacement for Grafana OnCall

### Target Users

- **On-call Engineers**: Receive and respond to alerts on mobile
- **SRE Teams**: Configure schedules, escalation policies
- **DevOps Teams**: Integrate with monitoring systems
- **Open-source Community**: Self-host alternative to PagerDuty/Grafana OnCall

### Core Technologies

**Backend/API**:
- **Language**: Elixir 1.15+ with Phoenix 1.8
- **API**: REST + GraphQL (for mobile apps)
- **Database**: PostgreSQL 14+ (alerts, schedules, users)
- **Queue**: Oban (alert processing, escalations)
- **Real-time**: Phoenix Channels (WebSocket)
- **Push**: FCM (Android) + APNs (iOS)

**Web Dashboard**:
- **Frontend**: Phoenix LiveView 1.1+
- **Styling**: TailwindCSS + DaisyUI
- **Charts**: Chart.js for alert analytics

**Mobile Apps**:
- **iOS**: Swift + SwiftUI (native UI)
- **Android**: Kotlin + Jetpack Compose (native UI)
- **Shared Logic**: GraphQL client for API

**Grafana Plugin**:
- **Type**: Data source plugin
- **Language**: TypeScript
- **Framework**: React (Grafana requirement)

**Deployment**:
- **Docker**: Multi-container setup
- **Cloud**: AWS, GCP, Azure, self-hosted
- **CDN**: CloudFlare for mobile app downloads

### Application Name

The application is called **Fangorn Sentinel** (modules: `FangornSentinel`, `FangornSentinelWeb`)

## Repository Structure

```
fangorn_sentinel/
├── backend/                      # Elixir/Phoenix backend
│   ├── lib/
│   │   ├── fangorn_sentinel/
│   │   │   ├── accounts/
│   │   │   │   ├── user.ex
│   │   │   │   ├── team.ex
│   │   │   │   └── user_token.ex
│   │   │   ├── alerts/
│   │   │   │   ├── alert.ex              # Alert schema
│   │   │   │   ├── incident.ex           # Grouped alerts
│   │   │   │   ├── acknowledgement.ex
│   │   │   │   └── resolution.ex
│   │   │   ├── schedules/
│   │   │   │   ├── schedule.ex           # On-call schedules
│   │   │   │   ├── rotation.ex           # Rotation patterns
│   │   │   │   ├── override.ex           # Schedule overrides
│   │   │   │   └── shift.ex              # Individual shifts
│   │   │   ├── escalation/
│   │   │   │   ├── policy.ex             # Escalation policies
│   │   │   │   ├── rule.ex               # Escalation rules
│   │   │   │   └── step.ex               # Escalation steps
│   │   │   ├── notifications/
│   │   │   │   ├── channel.ex            # Notification channels
│   │   │   │   ├── preference.ex         # User preferences
│   │   │   │   └── template.ex           # Message templates
│   │   │   ├── integrations/
│   │   │   │   ├── grafana.ex            # Grafana webhook handler
│   │   │   │   ├── prometheus.ex         # Prometheus AlertManager
│   │   │   │   ├── slack.ex              # Slack integration
│   │   │   │   └── plugin.ex             # Plugin behaviour
│   │   │   ├── workers/
│   │   │   │   ├── alert_router.ex       # Route alerts to on-call
│   │   │   │   ├── escalator.ex          # Handle escalations
│   │   │   │   ├── notifier.ex           # Send notifications
│   │   │   │   └── push_sender.ex        # Mobile push notifications
│   │   │   ├── push/
│   │   │   │   ├── apns.ex               # Apple Push Notification
│   │   │   │   ├── fcm.ex                # Firebase Cloud Messaging
│   │   │   │   └── device.ex             # Device registration
│   │   │   ├── telephony/
│   │   │   │   ├── twilio.ex             # Phone calls/SMS
│   │   │   │   └── voice_call.ex         # IVR handling
│   │   │   ├── alerts.ex                 # Alerts context
│   │   │   ├── schedules.ex              # Schedules context
│   │   │   ├── escalation.ex             # Escalation context
│   │   │   ├── application.ex
│   │   │   └── repo.ex
│   │   │
│   │   └── fangorn_sentinel_web/
│   │       ├── components/
│   │       │   ├── core_components.ex
│   │       │   ├── alert_components.ex
│   │       │   ├── schedule_components.ex
│   │       │   └── layouts.ex
│   │       ├── live/
│   │       │   ├── dashboard_live/
│   │       │   │   └── index.ex          # Main dashboard
│   │       │   ├── alerts_live/
│   │       │   │   ├── index.ex          # Alert list
│   │       │   │   └── show.ex           # Alert detail
│   │       │   ├── schedules_live/
│   │       │   │   ├── index.ex          # Schedule management
│   │       │   │   └── calendar.ex       # Schedule calendar view
│   │       │   ├── escalation_live/
│   │       │   │   └── index.ex          # Escalation policies
│   │       │   ├── integrations_live/
│   │       │   │   └── index.ex          # Integration settings
│   │       │   └── settings_live/
│   │       │       └── index.ex          # User settings
│   │       ├── controllers/
│   │       │   ├── api/
│   │       │   │   ├── v1/
│   │       │   │   │   ├── alert_controller.ex
│   │       │   │   │   ├── webhook_controller.ex
│   │       │   │   │   └── mobile_controller.ex
│   │       │   │   └── graphql/
│   │       │   │       ├── schema.ex
│   │       │   │       └── resolvers/
│   │       │   └── page_controller.ex
│   │       ├── channels/
│   │       │   ├── alert_channel.ex      # Real-time alerts
│   │       │   └── presence.ex           # User presence
│   │       ├── endpoint.ex
│   │       ├── router.ex
│   │       └── telemetry.ex
│   │
│   ├── priv/
│   │   ├── repo/
│   │   │   ├── migrations/
│   │   │   └── seeds.exs
│   │   └── static/
│   │
│   ├── test/
│   │   ├── fangorn_sentinel/
│   │   │   ├── alerts_test.exs
│   │   │   ├── schedules_test.exs
│   │   │   ├── escalation_test.exs
│   │   │   └── workers/
│   │   ├── fangorn_sentinel_web/
│   │   │   ├── live/
│   │   │   └── controllers/
│   │   └── support/
│   │
│   ├── config/
│   ├── mix.exs
│   └── README.md
│
├── mobile/                       # Mobile apps
│   ├── ios/                      # iOS app (Swift)
│   │   ├── FangornSentinel/
│   │   │   ├── App/
│   │   │   │   └── FangornSentinelApp.swift
│   │   │   ├── Features/
│   │   │   │   ├── Alerts/
│   │   │   │   │   ├── AlertListView.swift
│   │   │   │   │   ├── AlertDetailView.swift
│   │   │   │   │   └── AlertViewModel.swift
│   │   │   │   ├── OnCall/
│   │   │   │   │   ├── OnCallView.swift
│   │   │   │   │   └── ScheduleView.swift
│   │   │   │   ├── Settings/
│   │   │   │   │   └── SettingsView.swift
│   │   │   │   └── Auth/
│   │   │   │       └── LoginView.swift
│   │   │   ├── Services/
│   │   │   │   ├── API/
│   │   │   │   │   ├── GraphQLClient.swift
│   │   │   │   │   └── Queries.graphql
│   │   │   │   ├── Push/
│   │   │   │   │   └── PushNotificationService.swift
│   │   │   │   └── Local/
│   │   │   │       └── SecureStorage.swift
│   │   │   ├── Models/
│   │   │   │   ├── Alert.swift
│   │   │   │   ├── Schedule.swift
│   │   │   │   └── User.swift
│   │   │   └── UI/
│   │   │       ├── Components/
│   │   │       └── Theme/
│   │   ├── FangornSentinelTests/
│   │   ├── FangornSentinel.xcodeproj
│   │   └── Podfile
│   │
│   └── android/                  # Android app (Kotlin)
│       ├── app/
│       │   ├── src/
│       │   │   ├── main/
│       │   │   │   ├── java/com/notifd/fangornsentinel/
│       │   │   │   │   ├── FangornSentinelApp.kt
│       │   │   │   │   ├── features/
│       │   │   │   │   │   ├── alerts/
│       │   │   │   │   │   │   ├── AlertListScreen.kt
│       │   │   │   │   │   │   ├── AlertDetailScreen.kt
│       │   │   │   │   │   │   └── AlertViewModel.kt
│       │   │   │   │   │   ├── oncall/
│       │   │   │   │   │   │   ├── OnCallScreen.kt
│       │   │   │   │   │   │   └── ScheduleScreen.kt
│       │   │   │   │   │   ├── settings/
│       │   │   │   │   │   │   └── SettingsScreen.kt
│       │   │   │   │   │   └── auth/
│       │   │   │   │   │       └── LoginScreen.kt
│       │   │   │   │   ├── services/
│       │   │   │   │   │   ├── api/
│       │   │   │   │   │   │   └── GraphQLClient.kt
│       │   │   │   │   │   ├── push/
│       │   │   │   │   │   │   └── FCMService.kt
│       │   │   │   │   │   └── local/
│       │   │   │   │   │       └── SecurePreferences.kt
│       │   │   │   │   ├── models/
│       │   │   │   │   │   ├── Alert.kt
│       │   │   │   │   │   ├── Schedule.kt
│       │   │   │   │   │   └── User.kt
│       │   │   │   │   └── ui/
│       │   │   │   │       ├── components/
│       │   │   │   │       └── theme/
│       │   │   │   └── AndroidManifest.xml
│       │   │   └── test/
│       │   └── build.gradle
│       ├── gradle/
│       └── build.gradle
│
├── grafana-plugin/               # Grafana data source plugin
│   ├── src/
│   │   ├── components/
│   │   │   ├── ConfigEditor.tsx       # Plugin configuration
│   │   │   ├── QueryEditor.tsx        # Query builder
│   │   │   └── AnnotationsEditor.tsx
│   │   ├── datasource.ts              # Main data source
│   │   ├── types.ts                   # TypeScript types
│   │   └── module.ts                  # Plugin entry point
│   ├── plugin.json
│   ├── package.json
│   └── README.md
│
├── docs/
│   ├── JOURNAL.md
│   ├── ARCHITECTURE.md
│   ├── API.md                    # API documentation
│   ├── MOBILE.md                 # Mobile app guide
│   ├── GRAFANA_PLUGIN.md        # Plugin development
│   ├── DEPLOYMENT.md             # Deployment guide
│   └── CONTRIBUTING.md
│
├── docker/
│   ├── Dockerfile.backend
│   ├── Dockerfile.mobile-build
│   └── docker-compose.yml
│
├── .github/
│   └── workflows/
│       ├── backend-ci.yml
│       ├── ios-ci.yml
│       ├── android-ci.yml
│       └── grafana-plugin-ci.yml
│
├── LICENSE                       # MIT or Apache 2.0
├── README.md
└── CLAUDE.md
```

## Development Methodology

### Test-Driven Development (TDD)

**TDD is MANDATORY for all code changes. No exceptions.**

1. **Write tests first**: Before implementing a feature, write tests
2. **Run tests**: Verify that the new tests fail (red phase)
3. **Implement**: Write the minimal code needed to make tests pass (green phase)
4. **Refactor**: Clean up the code while keeping tests passing
5. **Verify**: Ensure all tests pass before committing

**Platform-Specific Testing**:
- **Backend**: ExUnit tests
- **iOS**: XCTest for unit tests, XCUITest for UI tests
- **Android**: JUnit + Espresso for UI tests
- **Grafana Plugin**: Jest + React Testing Library

## Core Features & Implementation

### Phase 1: Alert Reception & Routing

**Alert Schema**:

```elixir
# lib/fangorn_sentinel/alerts/alert.ex
defmodule FangornSentinel.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "alerts" do
    field :title, :string
    field :message, :text
    field :severity, Ecto.Enum, values: [:critical, :warning, :info]
    field :source, :string  # grafana, prometheus, api, etc.
    field :source_id, :string
    field :labels, :map
    field :annotations, :map
    field :status, Ecto.Enum, values: [:firing, :acknowledged, :resolved]
    field :fired_at, :utc_datetime
    field :acknowledged_at, :utc_datetime
    field :resolved_at, :utc_datetime

    belongs_to :incident, FangornSentinel.Alerts.Incident
    belongs_to :assigned_to, FangornSentinel.Accounts.User
    has_many :notifications, FangornSentinel.Notifications.Notification

    timestamps()
  end
end
```

**Grafana Webhook Handler**:

```elixir
# lib/fangorn_sentinel_web/controllers/api/v1/webhook_controller.ex
defmodule FangornSentinelWeb.API.V1.WebhookController do
  use FangornSentinelWeb, :controller

  alias FangornSentinel.Alerts

  def grafana(conn, params) do
    # Parse Grafana AlertManager webhook
    alerts = parse_grafana_alerts(params)

    Enum.each(alerts, fn alert_data ->
      # Create or update alert
      {:ok, alert} = Alerts.create_or_update_alert(alert_data)

      # Enqueue routing job
      %{alert_id: alert.id}
      |> FangornSentinel.Workers.AlertRouter.new()
      |> Oban.insert()
    end)

    json(conn, %{status: "ok", received: length(alerts)})
  end

  defp parse_grafana_alerts(%{"alerts" => grafana_alerts}) do
    Enum.map(grafana_alerts, fn alert ->
      %{
        title: alert["labels"]["alertname"],
        message: alert["annotations"]["summary"],
        severity: parse_severity(alert["labels"]["severity"]),
        source: "grafana",
        source_id: alert["fingerprint"],
        labels: alert["labels"],
        annotations: alert["annotations"],
        fired_at: parse_datetime(alert["startsAt"])
      }
    end)
  end
end
```

### Phase 2: Schedule Management

**On-Call Schedule**:

```elixir
# lib/fangorn_sentinel/schedules/schedule.ex
defmodule FangornSentinel.Schedules.Schedule do
  use Ecto.Schema

  schema "schedules" do
    field :name, :string
    field :timezone, :string
    field :description, :text

    belongs_to :team, FangornSentinel.Accounts.Team
    has_many :rotations, FangornSentinel.Schedules.Rotation

    timestamps()
  end

  def who_is_on_call?(schedule, datetime \\ DateTime.utc_now()) do
    # 1. Check for overrides
    # 2. Calculate from rotations
    # 3. Return current on-call user(s)
  end
end
```

**Rotation Calculation**:

```elixir
# lib/fangorn_sentinel/schedules/rotation.ex
defmodule FangornSentinel.Schedules.Rotation do
  use Ecto.Schema

  schema "rotations" do
    field :name, :string
    field :type, Ecto.Enum, values: [:daily, :weekly, :custom]
    field :start_time, :time
    field :duration_hours, :integer
    field :participants, {:array, :integer}  # User IDs in rotation order
    field :rotation_start_date, :date

    belongs_to :schedule, FangornSentinel.Schedules.Schedule

    timestamps()
  end

  def current_on_call(rotation, datetime) do
    # Calculate who is on call at given datetime
    # Based on rotation type, start date, participants
    days_since_start = Date.diff(DateTime.to_date(datetime), rotation.rotation_start_date)

    case rotation.type do
      :daily ->
        participant_index = rem(days_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :weekly ->
        weeks_since_start = div(days_since_start, 7)
        participant_index = rem(weeks_since_start, length(rotation.participants))
        Enum.at(rotation.participants, participant_index)

      :custom ->
        # Custom rotation logic
        calculate_custom_rotation(rotation, datetime)
    end
  end
end
```

### Phase 3: Escalation Policies

```elixir
# lib/fangorn_sentinel/workers/escalator.ex
defmodule FangornSentinel.Workers.Escalator do
  use Oban.Worker, queue: :escalations, max_attempts: 10

  alias FangornSentinel.{Alerts, Escalation}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"alert_id" => alert_id, "step" => step}}) do
    alert = Alerts.get_alert!(alert_id)

    # Don't escalate if already acknowledged/resolved
    if alert.status == :firing do
      policy = Escalation.get_policy_for_alert(alert)
      escalation_step = Enum.at(policy.steps, step)

      # Notify users in this escalation step
      Enum.each(escalation_step.users, fn user ->
        send_notification(alert, user, escalation_step.channels)
      end)

      # Schedule next escalation if not acknowledged
      if escalation_step.wait_minutes do
        %{alert_id: alert_id, step: step + 1}
        |> __MODULE__.new(schedule_in: escalation_step.wait_minutes * 60)
        |> Oban.insert()
      end
    end

    :ok
  end
end
```

### Phase 4: Mobile Push Notifications

**APNs (iOS)**:

```elixir
# lib/fangorn_sentinel/push/apns.ex
defmodule FangornSentinel.Push.APNS do
  def send_alert_notification(device_token, alert) do
    notification = %{
      aps: %{
        alert: %{
          title: alert.title,
          body: alert.message,
          sound: "critical.caf"  # Critical alert sound
        },
        badge: 1,
        "content-available": 1,
        "interruption-level": "critical"  # iOS 15+ critical alerts
      },
      alert_id: alert.id,
      severity: alert.severity
    }

    Pigeon.APNS.push(notification, to: device_token)
  end
end
```

**FCM (Android)**:

```elixir
# lib/fangorn_sentinel/push/fcm.ex
defmodule FangornSentinel.Push.FCM do
  def send_alert_notification(device_token, alert) do
    message = %{
      token: device_token,
      notification: %{
        title: alert.title,
        body: alert.message
      },
      android: %{
        priority: "high",
        notification: %{
          channel_id: "critical_alerts",
          sound: "critical_alert.mp3",
          priority: "max"
        }
      },
      data: %{
        alert_id: to_string(alert.id),
        severity: to_string(alert.severity),
        action: "view_alert"
      }
    }

    Pigeon.FCM.push(message)
  end
end
```

### Phase 5: GraphQL API (Mobile Apps)

```elixir
# lib/fangorn_sentinel_web/graphql/schema.ex
defmodule FangornSentinelWeb.GraphQL.Schema do
  use Absinthe.Schema

  import_types FangornSentinelWeb.GraphQL.Types.Alert
  import_types FangornSentinelWeb.GraphQL.Types.Schedule
  import_types FangornSentinelWeb.GraphQL.Types.User

  query do
    field :alerts, list_of(:alert) do
      arg :status, :alert_status
      arg :limit, :integer, default_value: 50

      resolve &Resolvers.Alert.list_alerts/3
    end

    field :alert, :alert do
      arg :id, non_null(:id)

      resolve &Resolvers.Alert.get_alert/3
    end

    field :my_schedule, :schedule do
      resolve &Resolvers.Schedule.my_current_schedule/3
    end

    field :who_is_on_call, list_of(:user) do
      arg :team_id, :id

      resolve &Resolvers.Schedule.who_is_on_call/3
    end
  end

  mutation do
    field :acknowledge_alert, :alert do
      arg :alert_id, non_null(:id)
      arg :note, :string

      resolve &Resolvers.Alert.acknowledge/3
    end

    field :resolve_alert, :alert do
      arg :alert_id, non_null(:id)
      arg :resolution_note, :string

      resolve &Resolvers.Alert.resolve/3
    end

    field :register_device, :device do
      arg :token, non_null(:string)
      arg :platform, non_null(:device_platform)

      resolve &Resolvers.Device.register/3
    end
  end

  subscription do
    field :alert_created, :alert do
      config fn _args, %{context: %{current_user: user}} ->
        {:ok, topic: "user:#{user.id}:alerts"}
      end
    end
  end
end
```

### Phase 6: iOS App (SwiftUI)

```swift
// mobile/ios/FangornSentinel/Features/Alerts/AlertListView.swift
import SwiftUI

struct AlertListView: View {
    @StateObject private var viewModel = AlertViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.alerts) { alert in
                    NavigationLink(destination: AlertDetailView(alert: alert)) {
                        AlertRow(alert: alert)
                    }
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        viewModel.showFilter.toggle()
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showFilter) {
                AlertFilterView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadAlerts()
        }
    }
}

struct AlertRow: View {
    let alert: Alert

    var body: some View {
        HStack {
            Circle()
                .fill(severityColor(alert.severity))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(alert.firedAt.relativeTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if alert.status == .firing {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    func severityColor(_ severity: AlertSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}
```

### Phase 7: Android App (Jetpack Compose)

```kotlin
// mobile/android/app/src/main/java/com/notifd/fangornsentinel/features/alerts/AlertListScreen.kt
package com.notifd.fangornsentinel.features.alerts

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun AlertListScreen(
    viewModel: AlertViewModel = hiltViewModel(),
    onAlertClick: (String) -> Unit
) {
    val alerts by viewModel.alerts.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Alerts") },
                actions = {
                    IconButton(onClick = { viewModel.showFilter() }) {
                        Icon(Icons.Default.FilterList, contentDescription = "Filter")
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                items(alerts, key = { it.id }) { alert ->
                    AlertRow(
                        alert = alert,
                        onClick = { onAlertClick(alert.id) }
                    )
                    Divider()
                }
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
                .fillMaxWidth()
        ) {
            // Severity indicator
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .background(
                        color = when (alert.severity) {
                            AlertSeverity.CRITICAL -> Color.Red
                            AlertSeverity.WARNING -> Color(0xFFFF9800)
                            AlertSeverity.INFO -> Color.Blue
                        },
                        shape = CircleShape
                    )
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = alert.title,
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = alert.message,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 2,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = alert.firedAt.toRelativeTime(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

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
```

### Phase 8: Grafana Plugin

```typescript
// grafana-plugin/src/datasource.ts
import { DataSourceInstanceSettings, DataQueryRequest, DataQueryResponse } from '@grafana/data';
import { DataSourceWithBackend } from '@grafana/runtime';

export class FangornSentinelDataSource extends DataSourceWithBackend<FangornQuery, FangornOptions> {
  constructor(instanceSettings: DataSourceInstanceSettings<FangornOptions>) {
    super(instanceSettings);
  }

  async testDatasource() {
    // Test connection to Fangorn Sentinel API
    const response = await this.getResource('health');

    if (response.status === 'ok') {
      return {
        status: 'success',
        message: 'Successfully connected to Fangorn Sentinel',
      };
    }

    return {
      status: 'error',
      message: 'Failed to connect to Fangorn Sentinel',
    };
  }

  // Send alerts to Fangorn Sentinel
  async sendAlert(alert: GrafanaAlert) {
    return this.postResource('alerts', {
      title: alert.title,
      message: alert.message,
      severity: alert.severity,
      labels: alert.labels,
      annotations: alert.annotations,
    });
  }
}
```

## Database Schema

```sql
-- Users and Teams
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  name VARCHAR,
  phone VARCHAR,
  timezone VARCHAR DEFAULT 'UTC',
  encrypted_password VARCHAR,
  role VARCHAR,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE teams (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  slug VARCHAR NOT NULL UNIQUE,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE team_members (
  team_id BIGINT REFERENCES teams(id),
  user_id BIGINT REFERENCES users(id),
  role VARCHAR,
  PRIMARY KEY (team_id, user_id)
);

-- Alerts
CREATE TABLE alerts (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  message TEXT,
  severity VARCHAR NOT NULL,
  source VARCHAR NOT NULL,
  source_id VARCHAR,
  labels JSONB,
  annotations JSONB,
  status VARCHAR NOT NULL,
  fired_at TIMESTAMP NOT NULL,
  acknowledged_at TIMESTAMP,
  acknowledged_by_id BIGINT REFERENCES users(id),
  resolved_at TIMESTAMP,
  resolved_by_id BIGINT REFERENCES users(id),
  assigned_to_id BIGINT REFERENCES users(id),
  incident_id BIGINT REFERENCES incidents(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX alerts_status_idx ON alerts(status);
CREATE INDEX alerts_fired_at_idx ON alerts(fired_at DESC);
CREATE INDEX alerts_assigned_to_idx ON alerts(assigned_to_id);

-- Incidents (grouped alerts)
CREATE TABLE incidents (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  status VARCHAR NOT NULL,
  severity VARCHAR NOT NULL,
  started_at TIMESTAMP NOT NULL,
  acknowledged_at TIMESTAMP,
  resolved_at TIMESTAMP,
  assigned_to_id BIGINT REFERENCES users(id),
  team_id BIGINT REFERENCES teams(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Schedules
CREATE TABLE schedules (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  timezone VARCHAR NOT NULL,
  team_id BIGINT REFERENCES teams(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE rotations (
  id BIGSERIAL PRIMARY KEY,
  schedule_id BIGINT REFERENCES schedules(id),
  name VARCHAR NOT NULL,
  type VARCHAR NOT NULL,
  start_time TIME,
  duration_hours INTEGER,
  participants INTEGER[] NOT NULL,
  rotation_start_date DATE NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE schedule_overrides (
  id BIGSERIAL PRIMARY KEY,
  schedule_id BIGINT REFERENCES schedules(id),
  user_id BIGINT REFERENCES users(id),
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  note TEXT,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Escalation Policies
CREATE TABLE escalation_policies (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  team_id BIGINT REFERENCES teams(id),
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE escalation_steps (
  id BIGSERIAL PRIMARY KEY,
  policy_id BIGINT REFERENCES escalation_policies(id),
  step_number INTEGER NOT NULL,
  wait_minutes INTEGER,
  notify_users INTEGER[] NOT NULL,
  notify_schedules INTEGER[],
  channels VARCHAR[] NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Notifications
CREATE TABLE notification_channels (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  type VARCHAR NOT NULL,
  config JSONB NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE push_devices (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  platform VARCHAR NOT NULL,
  device_token VARCHAR NOT NULL,
  device_name VARCHAR,
  last_active_at TIMESTAMP,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX push_devices_token_idx ON push_devices(device_token);
```

## Development Journal

**REQUIRED**: Maintain `docs/JOURNAL.md` after each significant task.

Format remains the same as other projects.

## Agent Decision-Making Authority

### ✅ Can Decide Independently
- UI component design (mobile and web)
- Alert routing logic optimizations
- GraphQL schema structure
- Mobile app architecture patterns
- Push notification formatting
- Schedule calculation algorithms

### ⚠️ Should Ask First
- Escalation policy defaults
- Mobile app navigation structure
- Grafana plugin capabilities
- Telephony provider selection (Twilio vs alternatives)
- Multi-tenancy approach
- Data retention policies

### 🚫 Must Always Ask
- Changing open-source license
- Adding paid/premium features
- Third-party service dependencies (cost implications)
- Breaking API changes for plugin ecosystem
- Data privacy policies

## Platform-Specific Guidelines

### iOS Development
- Use SwiftUI for all UI (iOS 15+ minimum)
- Follow Apple Human Interface Guidelines
- Request critical alert permissions
- Background fetch for silent updates
- Secure credential storage with Keychain

### Android Development
- Use Jetpack Compose for UI (Android 8.0+ minimum)
- Follow Material Design 3 guidelines
- Foreground service for alert monitoring
- WorkManager for background tasks
- Encrypted SharedPreferences for credentials

### Grafana Plugin
- Follow Grafana plugin guidelines
- Use Grafana UI components
- Support Grafana 9.0+
- Provide clear configuration UX
- Test with different Grafana themes

## Useful Resources

- [Phoenix Framework](https://hexdocs.pm/phoenix)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Absinthe GraphQL](https://hexdocs.pm/absinthe)
- [Oban Background Jobs](https://hexdocs.pm/oban)
- [Apple Push Notifications](https://developer.apple.com/notifications/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Grafana Plugin Development](https://grafana.com/docs/grafana/latest/developers/plugins/)
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)

---

**Last Updated**: 2025-11-21
**Project Phase**: Foundation
**Lead**: Chaos
**License**: MIT (Open Source)
**Motto**: "Always watching, never sleeping"
