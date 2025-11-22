# Fangorn Sentinel - Project Plan

**Last Updated**: 2025-11-21
**Status**: Early Development
**Methodology**: Test-Driven Development (TDD)
**Target Launch**: Phase 1 MVP in 8-12 weeks

---

## Executive Summary

Fangorn Sentinel is an open-source on-call notification system with native mobile apps, real-time web dashboard, and Grafana integration. Built as a modern replacement for the deprecated Grafana OnCall.

**Core Value Proposition**:
- Drop-in Grafana replacement
- Native mobile apps (iOS/Android)
- Self-hostable and fully open-source
- Real-time web dashboard with Phoenix LiveView
- Extensible plugin system

---

## Project Phases Overview

```
Phase 1: Core Backend (Weeks 1-4) ────────────────────────┐
│ Foundation: Alert reception, routing, storage          │
│ Deliverable: Working API that receives and routes alerts│
└──────────────────────────────────────────────────────────┘
                            ↓
Phase 2: Scheduling & Escalation (Weeks 4-6) ────────────┐
│ On-call schedules, rotations, escalation policies      │
│ Deliverable: Intelligent alert routing based on schedule│
└──────────────────────────────────────────────────────────┘
                            ↓
Phase 3: Web Dashboard (Weeks 6-8) ──────────────────────┐
│ Phoenix LiveView real-time interface                   │
│ Deliverable: Full-featured web management interface    │
└──────────────────────────────────────────────────────────┘
                            ↓
Phase 4: Mobile Apps (Weeks 8-12) ───────────────────────┐
│ Native iOS (Swift) and Android (Kotlin) apps           │
│ Deliverable: Push notifications, alert management      │
└──────────────────────────────────────────────────────────┘
                            ↓
Phase 5: Grafana Plugin (Weeks 12-14) ───────────────────┐
│ Data source plugin for Grafana integration             │
│ Deliverable: Drop-in replacement for Grafana OnCall    │
└──────────────────────────────────────────────────────────┘
                            ↓
Phase 6: Advanced Features (Weeks 14+) ──────────────────┐
│ Incident management, analytics, ML-based deduplication │
│ Deliverable: Production-ready enterprise features      │
└──────────────────────────────────────────────────────────┘
```

---

## Phase 1: Core Backend Platform (Weeks 1-4)

### Goals
- Establish Elixir/Phoenix foundation
- Implement alert reception and storage
- Build alert routing system
- Create REST and GraphQL APIs
- Set up background job processing

### Deliverables

#### 1.1 Project Foundation (Week 1)
**Priority**: P0 (Critical Path)

- [ ] **Initialize Phoenix application**
  - Create new Phoenix 1.8 project
  - Configure PostgreSQL database
  - Set up Ecto schemas and migrations
  - Configure Oban for background jobs
  - Add core dependencies (Absinthe for GraphQL, etc.)
  - **Tests**: Application boots, database connects

- [ ] **Database schema implementation**
  - Users and authentication
  - Teams and team membership
  - Alert schema with indexes
  - Incident schema (grouped alerts)
  - **Tests**: All migrations run successfully, indexes created

- [ ] **Development environment**
  - Docker Compose for local dev (PostgreSQL, Redis)
  - Environment configuration templates
  - Development seeds for testing
  - **Tests**: docker-compose up works, seeds load

#### 1.2 Alert Reception System (Week 2)
**Priority**: P0 (Critical Path)

- [ ] **Alerts context and schemas**
  - `FangornSentinel.Alerts` context module
  - Alert CRUD operations
  - Alert status transitions (firing → acknowledged → resolved)
  - **Tests**: Create, read, update alerts; status transitions

- [ ] **Webhook endpoints**
  - Grafana AlertManager webhook handler
  - Prometheus AlertManager webhook handler
  - Generic webhook endpoint
  - Webhook signature verification
  - **Tests**: Parse Grafana/Prometheus payloads, create alerts

- [ ] **REST API v1**
  - `POST /api/v1/alerts` - Create alert
  - `GET /api/v1/alerts` - List alerts with filters
  - `GET /api/v1/alerts/:id` - Get alert details
  - `POST /api/v1/alerts/:id/acknowledge` - Acknowledge
  - `POST /api/v1/alerts/:id/resolve` - Resolve
  - Authentication middleware (API keys)
  - **Tests**: All endpoints, authentication, validation

- [ ] **GraphQL API (foundation)**
  - Absinthe schema setup
  - Alert queries (list, get)
  - Alert mutations (acknowledge, resolve)
  - Authentication context
  - **Tests**: All queries and mutations work

#### 1.3 Alert Routing & Background Jobs (Week 3)
**Priority**: P0 (Critical Path)

- [ ] **Oban workers setup**
  - Configure queues (alerts, escalations, notifications)
  - Error handling and retry strategies
  - **Tests**: Jobs enqueue and process

- [ ] **AlertRouter worker**
  - Determine who is on-call (basic version)
  - Assign alert to on-call user
  - Trigger notification jobs
  - **Tests**: Alerts routed to correct user

- [ ] **Notification system foundation**
  - Notification schema and context
  - Multi-channel notification framework
  - Email notifications (SMTP via Swoosh)
  - Slack notifications (webhook-based)
  - **Tests**: Send email/Slack notifications

#### 1.4 Testing & Documentation (Week 4)
**Priority**: P1 (High)

- [ ] **Comprehensive test suite**
  - Unit tests for all contexts
  - Integration tests for API endpoints
  - Worker tests with Oban.Testing
  - Test coverage > 80%
  - **Tests**: All tests pass, coverage measured

- [ ] **API documentation**
  - OpenAPI/Swagger spec for REST API
  - GraphQL schema documentation
  - Webhook payload examples
  - Postman/Insomnia collections

- [ ] **Developer documentation**
  - Setup guide (local development)
  - Architecture documentation
  - Database schema diagrams
  - Contributing guide

---

## Phase 2: Scheduling & Escalation (Weeks 4-6)

### Goals
- Implement on-call schedule management
- Build rotation calculation engine
- Create escalation policy system
- Enable intelligent alert routing

### Deliverables

#### 2.1 Schedule Management (Week 4-5)
**Priority**: P0 (Critical Path)

- [ ] **Schedule schemas**
  - Schedule model (name, timezone, team)
  - Rotation model (daily, weekly, custom)
  - Override model (vacation, swap shifts)
  - **Tests**: Create schedules with rotations

- [ ] **Schedule calculation engine**
  - `Schedule.who_is_on_call?/2` - Calculate current on-call
  - Rotation logic (daily, weekly, custom patterns)
  - Override handling (priority over rotations)
  - Timezone support (calculate in user's timezone)
  - **Tests**: Verify on-call calculation across timezones

- [ ] **Schedule API**
  - REST endpoints for schedule CRUD
  - GraphQL queries for current on-call
  - Bulk schedule import/export
  - **Tests**: All schedule operations

- [ ] **Schedule UI components (basic)**
  - LiveView schedule list
  - Calendar view of rotations
  - Override creation form
  - **Tests**: LiveView integration tests

#### 2.2 Escalation Policies (Week 5-6)
**Priority**: P0 (Critical Path)

- [ ] **Escalation schemas**
  - EscalationPolicy model
  - EscalationStep model (multi-step policies)
  - Policy-to-team associations
  - **Tests**: Create multi-step policies

- [ ] **Escalator worker**
  - Process escalation steps
  - Wait between steps (schedule next job)
  - Notify users/schedules in each step
  - Stop escalation on acknowledgement
  - **Tests**: Multi-step escalation flow

- [ ] **Alert routing with escalation**
  - Link alerts to escalation policies
  - Trigger escalation on alert creation
  - Re-escalate on timeout
  - **Tests**: End-to-end alert → escalation → notification

- [ ] **Escalation API**
  - REST endpoints for policy management
  - GraphQL mutations for policy changes
  - Test escalation endpoint
  - **Tests**: All policy operations

---

## Phase 3: Web Dashboard (Weeks 6-8)

### Goals
- Build real-time web interface with Phoenix LiveView
- Create alert management UI
- Build schedule and escalation UIs
- Implement user/team management

### Deliverables

#### 3.1 Core Dashboard (Week 6-7)
**Priority**: P0 (Critical Path)

- [ ] **Authentication system**
  - User registration and login
  - Password hashing (Bcrypt)
  - Session management
  - **Tests**: Register, login, logout flows

- [ ] **Dashboard layout**
  - Navigation components
  - Responsive design (TailwindCSS + DaisyUI)
  - Real-time updates via LiveView
  - **Tests**: LiveView rendering

- [ ] **Alert management interface**
  - Alert list with real-time updates
  - Alert detail view
  - Acknowledge/resolve actions
  - Filtering and search
  - **Tests**: User interactions, real-time updates

- [ ] **Alert timeline**
  - Chronological alert feed
  - Status indicators (firing, acknowledged, resolved)
  - Assignment display
  - **Tests**: Timeline renders correctly

#### 3.2 Schedule & Team Management (Week 7-8)
**Priority**: P1 (High)

- [ ] **Schedule management UI**
  - Schedule list and creation
  - Rotation configuration forms
  - Visual calendar view
  - Override management
  - **Tests**: Create/edit schedules via UI

- [ ] **Team management UI**
  - Team creation and configuration
  - Member management (add/remove)
  - Role assignment
  - **Tests**: Team CRUD operations

- [ ] **Escalation policy UI**
  - Policy builder (drag-and-drop steps)
  - Step configuration (users, schedules, channels)
  - Wait time configuration
  - **Tests**: Build complex policies via UI

- [ ] **User settings**
  - Profile management
  - Notification preferences
  - Timezone configuration
  - **Tests**: User updates preferences

#### 3.3 Real-time Features (Week 8)
**Priority**: P1 (High)

- [ ] **Phoenix Channels setup**
  - AlertChannel for real-time alerts
  - Presence tracking (who's online)
  - **Tests**: WebSocket connections, broadcasts

- [ ] **Real-time alert updates**
  - Broadcast new alerts to dashboard
  - Update alert status in real-time
  - Toast notifications for critical alerts
  - **Tests**: Updates appear without refresh

- [ ] **Dashboard widgets**
  - Active alerts count
  - On-call summary (who's on call now)
  - Recent activity feed
  - **Tests**: Widgets update in real-time

---

## Phase 4: Mobile Apps (Weeks 8-12)

### Goals
- Build native iOS app (Swift/SwiftUI)
- Build native Android app (Kotlin/Compose)
- Implement push notifications
- Enable offline alert management

### Deliverables

#### 4.1 iOS App Foundation (Week 8-9)
**Priority**: P0 (Critical Path)

- [ ] **iOS project setup**
  - Xcode project structure
  - SwiftUI app architecture (MVVM)
  - GraphQL client (Apollo iOS)
  - Secure credential storage (Keychain)
  - **Tests**: XCTest unit tests

- [ ] **Authentication flow**
  - Login screen
  - Token storage
  - Auto-login on app launch
  - **Tests**: UI tests for login flow

- [ ] **Alert list view**
  - Alert feed (SwiftUI List)
  - Pull-to-refresh
  - Alert severity indicators
  - Tap to view details
  - **Tests**: UI tests for alert list

- [ ] **Alert detail view**
  - Full alert metadata display
  - Acknowledge/resolve buttons
  - Add notes functionality
  - **Tests**: UI tests for interactions

#### 4.2 Android App Foundation (Week 9-10)
**Priority**: P0 (Critical Path)

- [ ] **Android project setup**
  - Android Studio project
  - Jetpack Compose UI
  - GraphQL client (Apollo Android)
  - Encrypted SharedPreferences
  - **Tests**: JUnit + Espresso tests

- [ ] **Authentication flow**
  - Login screen (Compose)
  - Token storage
  - Auto-login
  - **Tests**: UI tests for login

- [ ] **Alert screens**
  - Alert list (LazyColumn)
  - Alert detail screen
  - Swipe actions (acknowledge, resolve)
  - **Tests**: UI tests for alert management

#### 4.3 Push Notifications (Week 10-11)
**Priority**: P0 (Critical Path)

- [ ] **APNs integration (iOS)**
  - Push certificate setup
  - Critical alert permissions
  - Background notification handling
  - Notification actions (acknowledge, view)
  - **Tests**: Push notification delivery

- [ ] **FCM integration (Android)**
  - Firebase setup
  - FCM token registration
  - Foreground/background notifications
  - Notification channels (critical, normal)
  - **Tests**: Push notification delivery

- [ ] **Backend push infrastructure**
  - Push device registration endpoint
  - APNs client (Pigeon library)
  - FCM client (Pigeon library)
  - PushSender Oban worker
  - **Tests**: Send push to iOS/Android devices

- [ ] **GraphQL subscriptions**
  - Real-time alert subscriptions
  - Alert status updates
  - **Tests**: Subscription updates

#### 4.4 Mobile App Polish (Week 11-12)
**Priority**: P1 (High)

- [ ] **Offline support**
  - Local caching (CoreData for iOS, Room for Android)
  - Sync on reconnection
  - Offline indicators
  - **Tests**: Offline mode functionality

- [ ] **App polish**
  - App icons and launch screens
  - Dark mode support
  - Accessibility (VoiceOver, TalkBack)
  - Haptic feedback
  - **Tests**: Accessibility audits

- [ ] **App store preparation**
  - Screenshots and metadata
  - Privacy policy
  - TestFlight beta (iOS)
  - Google Play internal testing
  - **Tests**: Beta testing with real users

---

## Phase 5: Grafana Plugin (Weeks 12-14)

### Goals
- Build Grafana data source plugin
- Enable alert sending from Grafana
- Query alert status in dashboards
- Drop-in Grafana OnCall replacement

### Deliverables

#### 5.1 Plugin Foundation (Week 12-13)
**Priority**: P1 (High)

- [ ] **Plugin project setup**
  - Grafana plugin scaffolding
  - TypeScript + React setup
  - Build configuration (webpack)
  - **Tests**: Jest unit tests

- [ ] **Plugin configuration**
  - ConfigEditor component
  - API URL configuration
  - API key authentication
  - Connection testing
  - **Tests**: Config validation

- [ ] **Data source implementation**
  - DataSource class
  - Query editor component
  - Alert query support
  - Time series formatting
  - **Tests**: Query execution

#### 5.2 Alert Integration (Week 13-14)
**Priority**: P1 (High)

- [ ] **Alert contact point**
  - Send alerts to Fangorn Sentinel
  - Alert templating
  - Severity mapping
  - **Tests**: Alerts received from Grafana

- [ ] **Dashboard queries**
  - Query active alerts
  - Alert annotations on graphs
  - Alert count metrics
  - **Tests**: Query results in Grafana

- [ ] **Plugin testing & distribution**
  - E2E tests with Grafana
  - Plugin signing
  - Grafana.com submission
  - Documentation
  - **Tests**: Full integration test

---

## Phase 6: Advanced Features (Weeks 14+)

### Goals
- Incident management
- Analytics and reporting
- ML-based alert deduplication
- Multi-tenancy for SaaS

### Deliverables (Post-MVP)

#### 6.1 Incident Management
- [ ] Incident schema (group related alerts)
- [ ] Incident timeline and collaboration
- [ ] Post-mortem templates
- [ ] Runbook integration

#### 6.2 Analytics & Reporting
- [ ] Alert analytics dashboard
- [ ] MTTA (Mean Time To Acknowledge) metrics
- [ ] MTTR (Mean Time To Resolve) metrics
- [ ] Team performance reports
- [ ] SLA tracking

#### 6.3 ML & Automation
- [ ] Alert deduplication (ML-based)
- [ ] Alert clustering (similar alerts)
- [ ] Noise reduction
- [ ] Auto-resolution suggestions

#### 6.4 Enterprise Features
- [ ] Multi-tenancy support
- [ ] SSO (SAML, OAuth2)
- [ ] Audit logging
- [ ] RBAC (role-based access control)
- [ ] High availability setup
- [ ] Compliance (SOC2 ready)

---

## Technical Infrastructure

### Required Services

#### Development
- **Database**: PostgreSQL 14+ (local via Docker)
- **Queue**: Redis 7+ (for Oban)
- **Email**: Mailhog (local SMTP testing)
- **Push Testing**: iOS Simulator, Android Emulator

#### Production
- **Database**: PostgreSQL 14+ (RDS, Cloud SQL, or self-hosted)
- **Queue**: Redis 7+ (ElastiCache, Memorystore)
- **Email**: SendGrid, Mailgun, or AWS SES
- **SMS/Voice**: Twilio
- **Push**: APNs (Apple), FCM (Google)
- **Hosting**: Fly.io, Heroku, AWS ECS, or self-hosted

### Third-Party Dependencies

#### Backend (Elixir)
- `phoenix` - Web framework
- `ecto` - Database ORM
- `oban` - Background jobs
- `absinthe` - GraphQL
- `swoosh` - Email
- `pigeon` - Push notifications (APNs/FCM)
- `ex_twilio` - SMS/voice calls

#### Mobile (iOS)
- Apollo iOS - GraphQL client
- KeychainAccess - Secure storage

#### Mobile (Android)
- Apollo Android - GraphQL client
- Room - Local database

#### Grafana Plugin
- @grafana/data - Grafana SDK
- @grafana/ui - UI components
- React - UI framework

---

## Success Metrics

### Phase 1 (Core Backend)
- ✅ Can receive alerts from Grafana webhook
- ✅ Alerts stored in database
- ✅ Alerts routed to on-call users
- ✅ Email/Slack notifications sent
- ✅ 80%+ test coverage

### Phase 2 (Scheduling)
- ✅ On-call schedules created and managed
- ✅ Correct on-call calculation (multiple timezones)
- ✅ Multi-step escalation policies work
- ✅ Alerts escalate after timeout

### Phase 3 (Web Dashboard)
- ✅ Users can log in and manage alerts
- ✅ Real-time alert updates (no refresh needed)
- ✅ Schedule calendar view functional
- ✅ Responsive design (mobile-friendly)

### Phase 4 (Mobile Apps)
- ✅ iOS and Android apps in app stores
- ✅ Push notifications delivered reliably
- ✅ Acknowledge/resolve from mobile
- ✅ Offline mode works

### Phase 5 (Grafana Plugin)
- ✅ Plugin installable in Grafana
- ✅ Alerts sent from Grafana to Fangorn
- ✅ Alert queries work in dashboards
- ✅ Documentation complete

---

## Risk Management

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Push notification reliability | High | Medium | Use Pigeon library (battle-tested), implement retry logic, monitor delivery rates |
| Timezone calculation bugs | High | Medium | Extensive tests across timezones, use standard libraries (Timex) |
| Real-time performance at scale | High | Low | Phoenix Channels proven at scale, implement rate limiting, load testing |
| Mobile app review delays | Medium | High | Submit early, follow guidelines strictly, have web fallback |
| Database performance | Medium | Medium | Proper indexing, connection pooling, read replicas if needed |

### Operational Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Third-party costs (Twilio) | Medium | Medium | Make phone/SMS optional, document pricing clearly |
| APNs/FCM configuration complexity | Medium | High | Detailed setup guides, setup wizard in UI |
| Multi-timezone support complexity | High | Medium | Use well-tested libraries, extensive timezone tests |
| Community adoption | High | Medium | Great docs, active support, showcase features |

---

## Development Principles

### Test-Driven Development (TDD)
**MANDATORY for all code**:
1. Write test first (red phase)
2. Implement minimal code (green phase)
3. Refactor while keeping tests passing
4. No code committed without tests

### Code Quality
- **Backend**: 80%+ test coverage, Credo for linting
- **iOS**: XCTest for unit tests, XCUITest for UI
- **Android**: JUnit + Espresso, 80%+ coverage
- **Plugin**: Jest tests, ESLint for linting

### Documentation
- Maintain `docs/JOURNAL.md` after each significant task
- Update API docs when endpoints change
- Keep README current with features
- Write inline documentation for complex logic

### Git Workflow
- Feature branches off `main`
- Pull requests for all changes
- CI must pass (tests, linting)
- Squash and merge

---

## Team & Roles

### Current Team
- **Lead Developer**: Chaos (full-stack, Elixir, mobile)

### Future Contributors Needed
- iOS developer (Swift/SwiftUI expert)
- Android developer (Kotlin/Compose expert)
- Frontend developer (Phoenix LiveView)
- DevOps engineer (deployment, infrastructure)
- Technical writer (documentation)

---

## Timeline Summary

```
Week 1-2:   Backend foundation + Alert reception
Week 3-4:   Alert routing + Testing
Week 4-6:   Scheduling + Escalation
Week 6-8:   Web dashboard (LiveView)
Week 8-10:  iOS + Android foundation
Week 10-12: Push notifications + Mobile polish
Week 12-14: Grafana plugin
Week 14+:   Advanced features

MVP Target: Week 12 (Core platform + Mobile apps)
Public Launch: Week 14 (With Grafana plugin)
```

---

## Next Steps (Immediate)

### Week 1 - Kick Off
1. **Initialize Phoenix project** (Day 1)
   ```bash
   mix phx.new fangorn_sentinel --database postgres
   cd backend
   mix ecto.create
   ```

2. **Set up Docker Compose** (Day 1)
   - PostgreSQL container
   - Redis container
   - Development environment variables

3. **Create database migrations** (Day 2)
   - Users table
   - Teams table
   - Alerts table
   - Initial indexes

4. **Implement Alerts context** (Day 3-4)
   - Alert schema with Ecto
   - CRUD operations
   - TDD: Write tests first

5. **Create webhook endpoint** (Day 5)
   - Grafana webhook handler
   - TDD: Test Grafana payload parsing

### Decision Needed
- **Twilio vs alternative** for phone/SMS (or make pluggable)?
- **Deployment target** for Phase 1 (Fly.io recommended)?
- **App store accounts** ready for mobile apps?

---

## Resources & Links

### Documentation
- Phoenix: https://hexdocs.pm/phoenix
- Ecto: https://hexdocs.pm/ecto
- Oban: https://hexdocs.pm/oban
- Absinthe (GraphQL): https://hexdocs.pm/absinthe
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view

### Mobile
- SwiftUI: https://developer.apple.com/xcode/swiftui/
- Jetpack Compose: https://developer.android.com/jetpack/compose
- Apollo iOS: https://www.apollographql.com/docs/ios/
- Apollo Android: https://www.apollographql.com/docs/kotlin/

### Grafana
- Plugin Development: https://grafana.com/docs/grafana/latest/developers/plugins/

### Community
- Elixir Forum: https://elixirforum.com
- Phoenix Discord: https://discord.gg/elixir
- Grafana Community: https://community.grafana.com

---

**Document Status**: Draft v1.0
**Ready for Review**: Yes
**Next Review**: After Phase 1 completion

*"The journey of a thousand pages begins with a single commit."* 🚀
