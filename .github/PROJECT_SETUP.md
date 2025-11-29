# Fangorn Sentinel - GitHub Project Setup

**Created**: 2025-11-22
**Repository**: https://github.com/notifd/fangorn_sentinel
**Project Board**: https://github.com/notifd/fangorn_sentinel/issues

---

## Overview

This document describes the GitHub project structure for Fangorn Sentinel, an open-source on-call notification system.

## Project Structure

### Milestones (6 Phases)

| Phase | Title | Issues | Due Date |
|-------|-------|--------|----------|
| 1 | Phase 1: Core Backend | 13 | 2025-12-20 |
| 2 | Phase 2: Scheduling & Escalation | 8 | 2026-01-03 |
| 3 | Phase 3: Web Dashboard | 11 | 2026-01-17 |
| 4 | Phase 4: Mobile Apps | 14 | 2026-02-14 |
| 5 | Phase 5: Grafana Plugin | 6 | 2026-02-28 |
| 6 | Phase 6: Advanced Features | 18 | 2026-04-30 |

**Total Issues**: 70

### Labels (24 total)

#### Priority Labels
- `priority: P0` - Critical path, blocks other work
- `priority: P1` - High priority, important but not blocking
- `priority: P2` - Medium priority, nice to have

#### Type Labels
- `type: backend` - Backend/API work (Elixir/Phoenix)
- `type: frontend` - Frontend work (LiveView/React)
- `type: mobile` - Mobile app work (iOS/Android)
- `type: infrastructure` - DevOps, deployment, tooling
- `type: documentation` - Documentation updates
- `type: testing` - Test coverage and quality

#### Component Labels
- `component: alerts` - Alert system components
- `component: scheduling` - On-call scheduling components
- `component: escalation` - Escalation policy components
- `component: notifications` - Notification system components

#### Status Labels
- `status: blocked` - Blocked by other work
- `status: in-review` - In code review

## Quick Links

- **All Issues**: https://github.com/notifd/fangorn_sentinel/issues
- **All Milestones**: https://github.com/notifd/fangorn_sentinel/milestones
- **Project Board**: Create at https://github.com/notifd/fangorn_sentinel/projects

## Phase Breakdown

### Phase 1: Core Backend (13 issues)
**Timeline**: Weeks 1-4 | **Due**: 2025-12-20

Foundation for alert reception, routing, and storage.

**Key Deliverables**:
- Phoenix application setup
- Database schema implementation
- Alert reception system (Grafana/Prometheus webhooks)
- REST and GraphQL APIs
- Alert routing with Oban workers
- Notification system foundation
- Comprehensive test suite

**Issues**: #1-#13

---

### Phase 2: Scheduling & Escalation (8 issues)
**Timeline**: Weeks 4-6 | **Due**: 2026-01-03

On-call schedules, rotations, and escalation policies.

**Key Deliverables**:
- Schedule management system
- Rotation calculation engine
- Schedule API (REST + GraphQL)
- Escalation policy system
- Escalator worker
- Alert routing with escalation

**Issues**: #14-#21

---

### Phase 3: Web Dashboard (11 issues)
**Timeline**: Weeks 6-8 | **Due**: 2026-01-17

Phoenix LiveView real-time interface.

**Key Deliverables**:
- Authentication system
- Dashboard layout
- Alert management interface
- Schedule management UI
- Team management UI
- Escalation policy UI
- Real-time features with Phoenix Channels
- Dashboard widgets

**Issues**: #22-#32

---

### Phase 4: Mobile Apps (14 issues)
**Timeline**: Weeks 8-12 | **Due**: 2026-02-14

Native iOS and Android apps with push notifications.

**Key Deliverables**:
- iOS app (SwiftUI + Apollo)
- Android app (Jetpack Compose + Apollo)
- APNs integration (iOS)
- FCM integration (Android)
- Backend push infrastructure
- GraphQL subscriptions
- Offline support
- App store preparation

**Issues**: #33-#46

---

### Phase 5: Grafana Plugin (6 issues)
**Timeline**: Weeks 12-14 | **Due**: 2026-02-28

Data source plugin for Grafana integration.

**Key Deliverables**:
- Plugin project setup (TypeScript + React)
- Plugin configuration UI
- Data source implementation
- Alert contact point
- Dashboard queries
- Plugin testing and distribution

**Issues**: #47-#52

---

### Phase 6: Advanced Features (18 issues)
**Timeline**: Weeks 14+ | **Due**: 2026-04-30

Enterprise features and ML capabilities.

**Key Deliverables**:
- Incident management
- Post-mortem templates
- Runbook integration
- Alert analytics dashboard
- MTTA/MTTR metrics
- SLA tracking
- ML-based alert deduplication
- Alert clustering
- Noise reduction
- Multi-tenancy support
- SSO (SAML, OAuth2)
- Audit logging
- RBAC
- High availability setup
- SOC2 compliance preparation

**Issues**: #53-#70

---

## Workflow

### Issue Lifecycle

1. **New Issue** → Created with milestone, labels, and acceptance criteria
2. **Ready** → All dependencies met, ready to start
3. **In Progress** → Developer assigned and working
4. **In Review** → Pull request created, `status: in-review` label
5. **Done** → Merged and issue closed

### Branch Naming

- `feature/issue-{number}-{short-description}` - New features
- `fix/issue-{number}-{short-description}` - Bug fixes
- `docs/issue-{number}-{short-description}` - Documentation

### Pull Request Requirements

- Linked to issue (e.g., "Closes #42")
- All tests passing
- Code coverage maintained (80%+)
- At least one approval
- Follows TDD methodology

---

## Current Progress

**Phase 1 Status**: ~90% complete (as of 2025-11-22)

Completed work:
- ✅ Phoenix application setup
- ✅ Database schema implementation
- ✅ Development environment (Docker)
- ✅ Alerts context and schemas
- ✅ Webhook endpoints (Grafana)
- ✅ REST API v1 (partial)
- ✅ GraphQL API foundation (partial)
- ✅ Oban workers setup
- ✅ AlertRouter worker
- ✅ Push notification system (bonus - ahead of schedule!)

Remaining work:
- ⏳ REST API completion
- ⏳ GraphQL API completion
- ⏳ Comprehensive test suite (tests written, coverage needs validation)
- ⏳ API documentation
- ⏳ Developer documentation

**Next Up**: Phase 2 - Schedule Management

---

## Resources

- **Project Plan**: See `PROJECT_PLAN.md`
- **Development Journal**: See `docs/JOURNAL.md`
- **Architecture**: See `CLAUDE.md`
- **Contributing**: See `CONTRIBUTING.md` (TBD)

---

## Maintainers

- **Lead**: @cole-christensen

## License

MIT License (Open Source)

---

**Last Updated**: 2025-11-22
