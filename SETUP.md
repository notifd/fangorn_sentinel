# Fangorn Sentinel - Quick Setup Guide

## 🚀 Quick Start

Fangorn Sentinel is an open-source on-call notification system - PagerDuty/Grafana OnCall replacement.

### Components

1. **Backend** (Elixir/Phoenix) - API, webhooks, push notifications
2. **iOS App** (Swift/SwiftUI) - Mobile alerts for iOS
3. **Android App** (Kotlin/Jetpack Compose) - Mobile alerts for Android
4. **Grafana Plugin** (TypeScript/React) - Integration with Grafana

---

## Backend Setup

### Prerequisites
- Elixir 1.15+
- PostgreSQL 14+
- Redis 7+ (optional, for Oban)

### Install & Run

```bash
cd backend

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

Server runs at: `http://localhost:4000`

### API Endpoints

- `POST /api/v1/webhooks/grafana` - Receive Grafana alerts
- `POST /api/v1/devices/register` - Register mobile device for push
- `DELETE /api/v1/devices/unregister` - Unregister device

### Configure Push Notifications

#### APNs (iOS)

1. Get `.p8` auth key from Apple Developer Portal
2. Set environment variables:
```bash
export APNS_KEY_ID=ABC123DEFG
export APNS_TEAM_ID=DEF123
export APNS_KEY_PATH=/path/to/AuthKey.p8
```

#### FCM (Android)

1. Create Firebase project: https://console.firebase.google.com
2. Download service account JSON
3. Set environment variables:
```bash
export FCM_PROJECT_ID=your-project-id
export FCM_SERVICE_ACCOUNT_JSON_PATH=/path/to/service-account.json
```

---

## iOS App Setup

### Prerequisites
- Xcode 15+
- iOS 15+ device
- Apple Developer account (for push notifications)

### Build & Run

```bash
cd mobile/ios
open FangornSentinel.xcodeproj
```

1. Update Bundle ID in Xcode
2. Add Push Notifications capability
3. Add Critical Alerts entitlement (requires Apple approval)
4. Update backend URL in `FangornSentinelApp.swift`
5. Build and run on device (push won't work in simulator)

### Testing Push Notifications

1. Launch app on physical device
2. App will register device token
3. Send test alert from Grafana
4. Phone should beep! 📱🚨

---

## Android App Setup

### Prerequisites
- Android Studio Hedgehog+
- Android 8.0+ device
- Firebase project

### Build & Run

```bash
cd mobile/android
# Open in Android Studio
```

1. Connect Firebase project (download `google-services.json`)
2. Place `google-services.json` in `app/`
3. Update backend URL in `FangornSentinelApp.kt`
4. Build and run

---

## Grafana Plugin Setup

### Install Plugin

```bash
cd grafana-plugin

# Install dependencies
npm install

# Build plugin
npm run build

# Copy to Grafana plugins directory
cp -r dist /var/lib/grafana/plugins/fangorn-sentinel
```

### Configure in Grafana

1. Restart Grafana
2. Go to **Configuration → Plugins**
3. Find "Fangorn Sentinel"
4. Enable plugin
5. Configure:
   - API URL: `https://your-backend.com`
   - API Key: (generate in Fangorn backend)

### Setup Webhook

1. **Alerting → Contact points**
2. Click **Add contact point**
3. Name: `Fangorn Sentinel`
4. Type: **Webhook**
5. URL: `https://your-backend.com/api/v1/webhooks/grafana`
6. HTTP Method: **POST**
7. Save

### Test Alert

1. Create test alert rule in Grafana
2. Set contact point to "Fangorn Sentinel"
3. Trigger alert
4. Check mobile app - you should get push notification! 🎉

---

## Complete Flow Test

1. **Start backend**: `cd backend && mix phx.server`
2. **Launch iOS/Android app** on physical device
3. **Register device**: App automatically registers on launch
4. **Configure Grafana**: Add webhook contact point
5. **Create alert**: In Grafana, create alert rule
6. **Trigger alert**: Wait for alert to fire
7. **Receive notification**: Phone should make noise! 📱🔊

---

## Production Deployment

### Docker

```bash
# Build
docker build -t fangorn-sentinel ./backend

# Run
docker run -p 4000:4000 \
  -e DATABASE_URL=postgresql://... \
  -e SECRET_KEY_BASE=... \
  -e APNS_KEY_ID=... \
  -e FCM_PROJECT_ID=... \
  fangorn-sentinel
```

### Environment Variables

See `.env.production.example` for all required environment variables.

### Mobile App Distribution

- **iOS**: Publish to App Store or TestFlight
- **Android**: Publish to Google Play or distribute APK

---

## Troubleshooting

### No push notifications?

**iOS**:
- Check device token is registered: `POST /api/v1/devices/register`
- Verify APNs credentials are correct
- Ensure using physical device (not simulator)
- Check critical alert permission granted

**Android**:
- Check FCM token registered
- Verify `google-services.json` is correct
- Check notification channel created
- Ensure app has notification permission

### Grafana webhook not working?

- Check webhook URL is correct
- Verify backend is accessible from Grafana
- Check backend logs: `docker logs fangorn-sentinel`
- Test webhook manually:
```bash
curl -X POST https://your-backend.com/api/v1/webhooks/grafana \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {"alertname": "Test", "severity": "critical"},
      "annotations": {"summary": "Test alert"},
      "startsAt": "2025-11-22T00:00:00Z",
      "fingerprint": "test123"
    }]
  }'
```

---

## Next Steps

- [ ] Configure on-call schedules (Phase 2)
- [ ] Add escalation policies
- [ ] Customize notification preferences
- [ ] Set up alert acknowledgement
- [ ] Add incident management
- [ ] Configure team access

---

## Support

- 📖 Documentation: `docs/`
- 🐛 Issues: https://github.com/notifd/fangorn-sentinel/issues
- 💬 Discord: (coming soon)

---

**Built with ❤️ by the open-source community**
