# Fangorn Sentinel

**Open-source on-call management for the modern era**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Backend CI](https://github.com/notifd/fangorn_sentinel/workflows/Backend%20CI/badge.svg)](https://github.com/notifd/fangorn_sentinel/actions)
[![iOS CI](https://github.com/notifd/fangorn_sentinel/workflows/iOS%20CI/badge.svg)](https://github.com/notifd/fangorn_sentinel/actions)
[![Android CI](https://github.com/notifd/fangorn_sentinel/workflows/Android%20CI/badge.svg)](https://github.com/notifd/fangorn_sentinel/actions)

Fangorn Sentinel is a comprehensive, open-source on-call notification system with native mobile apps, real-time web dashboard, and Grafana integration. Built as a modern replacement for Grafana OnCall.

## Why Fangorn Sentinel?

Grafana OnCall is being deprecated. The SRE/DevOps community needs a robust, open-source alternative. Fangorn Sentinel provides:

- ✅ **Drop-in Grafana replacement** via data source plugin
- 📱 **Native mobile apps** for iOS and Android (not wrapped web views)
- 🔔 **Smart alert routing** based on schedules and escalation policies
- 🌐 **Real-time web dashboard** with Phoenix LiveView
- 🔌 **Extensible plugin system** for integrations
- 🚀 **Self-hostable** - own your infrastructure
- 🆓 **Fully open-source** - MIT licensed

## Features

### 🚨 Alert Management

- **Multi-source ingestion**: Grafana, Prometheus, webhooks, custom APIs
- **Intelligent deduplication**: Group related alerts into incidents
- **Severity levels**: Critical, warning, info
- **Rich metadata**: Labels, annotations, runbooks
- **Real-time updates**: WebSocket push to all clients

### 📅 On-Call Scheduling

- **Flexible rotations**: Daily, weekly, custom patterns
- **Multiple schedules**: Per team, per service
- **Override support**: Swap shifts or take time off
- **Timezone aware**: Works globally
- **Visual calendar**: See who's on call at a glance

### 📞 Multi-Channel Notifications

- **Mobile push**: Critical alerts via APNs (iOS) and FCM (Android)
- **Phone calls**: Voice alerts via Twilio
- **SMS**: Text message fallback
- **Email**: Professional alert emails
- **Slack**: Team notifications
- **Webhook**: Custom integrations

### 🎯 Escalation Policies

- **Multi-step escalation**: Notify → Wait → Escalate
- **Parallel notifications**: Alert multiple people simultaneously
- **Fallback chains**: Ensure someone always responds
- **Schedule-based**: Escalate to current on-call
- **Custom rules**: Flexible policy engine

### 📱 Mobile Apps

**iOS (Swift + SwiftUI)**:
- Native iOS design (iOS 15+)
- Critical alert support (breaks Do Not Disturb)
- Background fetch for updates
- Rich notifications with actions
- Biometric authentication

**Android (Kotlin + Jetpack Compose)**:
- Material Design 3
- Persistent notification for monitoring
- Foreground service for reliability
- Quick action buttons
- Encrypted storage

### 🌐 Web Dashboard

**Phoenix LiveView** (real-time, no JavaScript framework):
- Alert timeline and detail views
- On-call schedule management
- Escalation policy configuration
- Team and user management
- Integration settings
- Analytics and reporting

### 🔌 Grafana Plugin

**Data Source Plugin**:
- Configure Fangorn Sentinel as alert destination
- Send alerts from Grafana Alerting
- Query alert status in dashboards
- Annotation support
- Compatible with Grafana 9.0+

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile Apps                              │
│         iOS (Swift/SwiftUI)  │  Android (Kotlin/Compose)    │
│              APNs Push        │        FCM Push             │
└──────────────────────┬──────────────────────────────────────┘
                       │ GraphQL API
┌──────────────────────▼──────────────────────────────────────┐
│                Phoenix LiveView Web Dashboard                │
│   Alerts │ Schedules │ Escalations │ Teams │ Settings       │
└──────────────────────┬──────────────────────────────────────┘
                       │ WebSocket + REST
┌──────────────────────▼──────────────────────────────────────┐
│              Elixir/Phoenix Backend (API)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Alerts     │  │  Schedules   │  │  Escalation  │     │
│  │   Context    │  │   Context    │  │   Context    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│  ┌────────────────────────────────────────────────────┐   │
│  │   Oban Workers (Background Jobs)                   │   │
│  │   - AlertRouter (route to on-call)                 │   │
│  │   - Escalator (handle escalations)                 │   │
│  │   - PushSender (mobile notifications)              │   │
│  │   - PhoneCaller (voice calls)                      │   │
│  └────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
       ┌───────────────┼───────────────┬──────────────┐
       │               │               │              │
  ┌────▼────┐    ┌────▼────┐    ┌────▼────┐   ┌────▼─────┐
  │   PG    │    │  Redis  │    │  Twilio │   │APNs/FCM  │
  │  (DB)   │    │ (Oban)  │    │(Phone)  │   │  (Push)  │
  └─────────┘    └─────────┘    └─────────┘   └──────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Alert Sources                             │
│  Grafana Plugin │ Prometheus │ Webhooks │ Custom API        │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Backend (Elixir/Phoenix)

```bash
# Clone repository
git clone https://github.com/notifd/fangorn_sentinel
cd fangorn_sentinel/backend

# Install dependencies
mix deps.get

# Set up database
mix ecto.setup

# Configure (see config/runtime.exs)
export DATABASE_URL="postgresql://localhost/fangorn_sentinel_dev"
export SECRET_KEY_BASE="$(mix phx.gen.secret)"
export TWILIO_ACCOUNT_SID="your_twilio_sid"
export TWILIO_AUTH_TOKEN="your_twilio_token"

# Start server
mix phx.server

# Open http://localhost:4000
```

### Mobile Apps

**iOS**:
```bash
cd mobile/ios
pod install
open FangornSentinel.xcworkspace

# Configure API endpoint in Config.swift
# Build and run in Xcode
```

**Android**:
```bash
cd mobile/android
./gradlew assembleDebug

# Configure API endpoint in app/src/main/res/values/config.xml
# Build and run in Android Studio
```

### Grafana Plugin

```bash
cd grafana-plugin
npm install
npm run build

# Install in Grafana
# 1. Copy dist/ to Grafana plugins directory
# 2. Restart Grafana
# 3. Add Fangorn Sentinel as data source
```

### Docker (All-in-One)

```bash
docker-compose up -d

# Services:
# - Backend: http://localhost:4000
# - PostgreSQL: localhost:5432
# - Redis: localhost:6379
```

## Usage

### 1. Create Team and Users

```bash
# Via web dashboard
http://localhost:4000/teams/new

# Or via API
curl -X POST http://localhost:4000/api/v1/teams \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SRE Team",
    "slug": "sre"
  }'
```

### 2. Set Up On-Call Schedule

```elixir
# Create schedule
schedule = %{
  name: "Primary On-Call",
  timezone: "America/New_York",
  team_id: team.id
}

# Add rotation
rotation = %{
  name: "Weekly Rotation",
  type: "weekly",
  start_time: ~T[09:00:00],
  duration_hours: 168,  # 1 week
  participants: [user1_id, user2_id, user3_id],
  rotation_start_date: ~D[2025-11-24]
}
```

**Result**: Users rotate weekly starting Monday 9 AM.

### 3. Configure Escalation Policy

```elixir
policy = %{
  name: "Critical Incidents",
  steps: [
    %{
      step_number: 1,
      wait_minutes: 5,
      notify_users: [],  # Use schedule
      notify_schedules: [primary_schedule.id],
      channels: ["push", "sms"]
    },
    %{
      step_number: 2,
      wait_minutes: 10,
      notify_users: [manager_id],
      channels: ["push", "sms", "phone"]
    }
  ]
}
```

**Flow**: Alert → On-call engineer (push+SMS) → Wait 5 min → Manager (push+SMS+call)

### 4. Send Alert from Grafana

**Install Plugin**:
```bash
# In Grafana UI
Configuration → Data Sources → Add Fangorn Sentinel
URL: http://localhost:4000
API Key: <your_api_key>
```

**Configure Alert**:
```yaml
# In Grafana Alert Rule
Contact point: Fangorn Sentinel
Severity: Critical
Labels:
  service: api
  environment: production
```

**Webhook Alternative**:
```bash
curl -X POST http://localhost:4000/api/v1/webhooks/grafana \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {
        "alertname": "HighCPU",
        "severity": "critical",
        "instance": "api-01"
      },
      "annotations": {
        "summary": "CPU usage above 90% for 5 minutes"
      },
      "startsAt": "2025-11-21T12:00:00Z"
    }]
  }'
```

### 5. Respond on Mobile

**iOS/Android App Flow**:

1. **Receive Push Notification**:
   ```
   🔴 [CRITICAL] HighCPU
   CPU usage above 90% for 5 minutes
   Instance: api-01

   [Acknowledge] [View] [Escalate]
   ```

2. **Tap "Acknowledge"**:
   - Alert marked as acknowledged
   - Stops escalation
   - Notifies team via Slack

3. **View Alert Details**:
   - Full alert metadata
   - Runbook links
   - Related alerts
   - Timeline of events

4. **Resolve**:
   - Add resolution note
   - Mark as resolved
   - Incident closes

### 6. Web Dashboard

**Alert Timeline**:
```
┌─────────────────────────────────────────────────────┐
│  Alerts                                    [Filter] │
├─────────────────────────────────────────────────────┤
│  🔴 HighCPU                      ACKNOWLEDGED       │
│     CPU above 90%                                   │
│     api-01 | 2 min ago           @john              │
│                                                     │
│  🟡 SlowResponse                 FIRING             │
│     API latency > 2s                                │
│     api-02 | 5 min ago           Unassigned         │
│                                                     │
│  🔵 DiskSpace                    RESOLVED           │
│     Disk usage 85%                                  │
│     db-01 | 1 hour ago           @sarah             │
└─────────────────────────────────────────────────────┘
```

**On-Call Calendar**:
```
┌─────────────────────────────────────────────────────┐
│  Primary On-Call Schedule              Nov 2025    │
├─────────────────────────────────────────────────────┤
│  Mon  │  Tue  │  Wed  │  Thu  │  Fri  │  Sat  │ Sun│
│  18   │  19   │  20   │  21   │  22   │  23   │ 24 │
│  John │  John │  John │  John │  John │  John │ John│
│       │       │       │       │       │       │     │
│  25   │  26   │  27   │  28   │  29   │  30   │  1 │
│ Sarah │ Sarah │ Sarah │ Sarah │ Sarah │ Sarah │Sarah│
└─────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables

```bash
# Backend
DATABASE_URL=postgresql://localhost/fangorn_sentinel_prod
SECRET_KEY_BASE=<generate with: mix phx.gen.secret>
PHX_HOST=sentinel.example.com

# Push Notifications
APNS_KEY_ID=<apple_key_id>
APNS_TEAM_ID=<apple_team_id>
APNS_KEY_FILE=<path_to_p8_file>
FCM_SERVER_KEY=<firebase_server_key>

# Telephony (Twilio)
TWILIO_ACCOUNT_SID=<twilio_sid>
TWILIO_AUTH_TOKEN=<twilio_token>
TWILIO_PHONE_NUMBER=<twilio_number>

# Email
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=<sendgrid_api_key>

# Slack (optional)
SLACK_WEBHOOK_URL=<slack_webhook>
```

### config/runtime.exs

```elixir
config :fangorn_sentinel, FangornSentinel.Push.APNS,
  cert: System.get_env("APNS_CERT_PATH"),
  key: System.get_env("APNS_KEY_PATH"),
  mode: :prod  # or :dev

config :fangorn_sentinel, FangornSentinel.Push.FCM,
  server_key: System.get_env("FCM_SERVER_KEY")

config :fangorn_sentinel, Oban,
  repo: FangornSentinel.Repo,
  queues: [
    alerts: 50,
    escalations: 25,
    notifications: 100
  ]
```

## Deployment

### Docker

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  backend:
    build:
      context: ./backend
      dockerfile: ../docker/Dockerfile.backend
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db/fangorn_sentinel
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    depends_on:
      - db
      - redis

volumes:
  pgdata:
```

### Kubernetes

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fangorn-sentinel
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fangorn-sentinel
  template:
    metadata:
      labels:
        app: fangorn-sentinel
    spec:
      containers:
      - name: backend
        image: notifd/fangorn-sentinel:latest
        ports:
        - containerPort: 4000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: fangorn-secrets
              key: database-url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: fangorn-secrets
              key: secret-key-base
```

### Cloud Platforms

**Fly.io** (recommended for Elixir):
```bash
fly launch
fly deploy
```

**Heroku**:
```bash
heroku create fangorn-sentinel
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create heroku-redis:hobby-dev
git push heroku main
```

**AWS ECS**: See `docs/DEPLOYMENT.md`

## API Documentation

### REST API

**Base URL**: `http://localhost:4000/api/v1`

**Authentication**: Bearer token in `Authorization` header

```bash
# Create alert
POST /api/v1/alerts
{
  "title": "High CPU Usage",
  "message": "CPU above 90% for 5 minutes",
  "severity": "critical",
  "labels": {"service": "api", "env": "prod"}
}

# List alerts
GET /api/v1/alerts?status=firing&limit=50

# Acknowledge alert
POST /api/v1/alerts/{id}/acknowledge
{
  "note": "Investigating the issue"
}

# Resolve alert
POST /api/v1/alerts/{id}/resolve
{
  "resolution_note": "Scaled up instances, CPU back to normal"
}
```

### GraphQL API (Mobile)

**Endpoint**: `http://localhost:4000/api/graphql`

```graphql
# Query alerts
query GetAlerts($status: AlertStatus, $limit: Int) {
  alerts(status: $status, limit: $limit) {
    id
    title
    message
    severity
    status
    firedAt
    assignedTo {
      id
      name
      email
    }
  }
}

# Acknowledge alert
mutation AcknowledgeAlert($alertId: ID!, $note: String) {
  acknowledgeAlert(alertId: $alertId, note: $note) {
    id
    status
    acknowledgedAt
    acknowledgedBy {
      name
    }
  }
}

# Subscribe to new alerts
subscription OnAlertCreated {
  alertCreated {
    id
    title
    severity
    message
  }
}
```

### Webhooks

**Grafana AlertManager**:
```bash
POST /api/v1/webhooks/grafana
```

**Prometheus AlertManager**:
```bash
POST /api/v1/webhooks/prometheus
```

**Generic Webhook**:
```bash
POST /api/v1/webhooks/generic
```

## Plugin Development

### Creating a Custom Integration Plugin

```elixir
# lib/fangorn_sentinel/integrations/my_plugin.ex
defmodule FangornSentinel.Integrations.MyPlugin do
  @behaviour FangornSentinel.Integrations.Plugin

  @impl true
  def handle_webhook(params) do
    # Parse webhook payload
    alert_data = parse_my_service(params)

    # Create alert
    FangornSentinel.Alerts.create_alert(alert_data)
  end

  @impl true
  def send_notification(alert, config) do
    # Send notification to your service
    MyService.API.send_alert(
      api_key: config.api_key,
      alert: format_alert(alert)
    )
  end

  defp parse_my_service(params) do
    %{
      title: params["alert"]["name"],
      message: params["alert"]["description"],
      severity: parse_severity(params["alert"]["level"]),
      source: "my_service"
    }
  end
end
```

Register in `lib/fangorn_sentinel/integrations/registry.ex`:

```elixir
@plugins [
  grafana: FangornSentinel.Integrations.Grafana,
  prometheus: FangornSentinel.Integrations.Prometheus,
  my_service: FangornSentinel.Integrations.MyPlugin
]
```

## Development

### Prerequisites

- Elixir 1.15+
- Erlang/OTP 26+
- PostgreSQL 14+
- Node.js 18+ (for Grafana plugin)
- Xcode 15+ (for iOS)
- Android Studio (for Android)

### Running Tests

```bash
# Backend
cd backend
mix test

# iOS
cd mobile/ios
xcodebuild test -workspace FangornSentinel.xcworkspace -scheme FangornSentinel

# Android
cd mobile/android
./gradlew test

# Grafana Plugin
cd grafana-plugin
npm test
```

### Code Quality

```bash
# Backend
mix format
mix credo

# iOS
swiftlint

# Android
./gradlew ktlintCheck

# Grafana Plugin
npm run lint
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

**Key areas**:
- ✨ New integrations (PagerDuty, Datadog, etc.)
- 📱 Mobile app improvements
- 🎨 UI/UX enhancements
- 📚 Documentation
- 🐛 Bug fixes
- 🧪 Test coverage

## Roadmap

### Phase 1: Core Platform (Current)
- [x] Project structure
- [ ] Alert reception and routing
- [ ] Schedule management
- [ ] Escalation policies
- [ ] Web dashboard (LiveView)
- [ ] REST + GraphQL APIs

### Phase 2: Mobile Apps
- [ ] iOS app (Swift/SwiftUI)
- [ ] Android app (Kotlin/Compose)
- [ ] Push notifications (APNs/FCM)
- [ ] Offline support
- [ ] Background fetch

### Phase 3: Integrations
- [ ] Grafana plugin
- [ ] Prometheus AlertManager
- [ ] Slack bot
- [ ] Twilio (phone/SMS)
- [ ] Email (SMTP)
- [ ] Webhook system

### Phase 4: Advanced Features
- [ ] Incident management
- [ ] Post-mortem templates
- [ ] Analytics dashboard
- [ ] SLA tracking
- [ ] Alert noise reduction (ML)
- [ ] Custom workflows

### Phase 5: Enterprise
- [ ] Multi-tenancy
- [ ] SSO (SAML, OAuth)
- [ ] Audit logs
- [ ] Role-based access control
- [ ] High availability setup
- [ ] Compliance (SOC2, etc.)

## Comparison

| Feature | Fangorn Sentinel | PagerDuty | Grafana OnCall | Opsgenie |
|---------|------------------|-----------|----------------|----------|
| **Open Source** | ✅ Yes | ❌ No | ⚠️ Deprecated | ❌ No |
| **Self-hosted** | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| **Native Mobile** | ✅ Yes | ✅ Yes | ❌ Web only | ✅ Yes |
| **Real-time Web** | ✅ LiveView | ✅ React | ✅ React | ✅ React |
| **Grafana Plugin** | ✅ Yes | ✅ Yes | ✅ Native | ✅ Yes |
| **Phone Calls** | ✅ Twilio | ✅ Built-in | ✅ Twilio | ✅ Built-in |
| **Pricing** | 🆓 Free | 💰 $21+/user | 🆓 Free | 💰 $29+/user |

## License

MIT License - see [LICENSE](./LICENSE)

## Support

- **Documentation**: [docs.fangornsentinel.dev](https://docs.fangornsentinel.dev)
- **Issues**: [GitHub Issues](https://github.com/notifd/fangorn_sentinel/issues)
- **Discussions**: [GitHub Discussions](https://github.com/notifd/fangorn_sentinel/discussions)
- **Slack**: [Join Community](https://fangornsentinel.slack.com)

## Acknowledgments

Inspired by the excellent work of:
- Grafana OnCall team
- PagerDuty
- The Elixir and Phoenix communities

Built with ❤️ by the open-source community.

---

**Status**: Early Development
**Last Updated**: 2025-11-21
**Maintainer**: Chaos

*"Always watching, never sleeping"* 🌲👁️
