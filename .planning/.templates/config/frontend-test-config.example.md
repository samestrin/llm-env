# Frontend Test Configuration

This file configures project-specific settings for frontend tests. Copy to `.planning/.config/frontend-test-config.md` and customize for your project.

---

## Infrastructure Prerequisites

Define services that must be running before tests execute.

| Service | Port | Health Check | Start Command |
|---------|------|--------------|---------------|
| Frontend | 3000 | `curl -s http://localhost:3000` | `cd app && wasp start` |
| Backend | 3001 | `curl -s http://localhost:3001/api/health` | (started with frontend) |
| Database | 5432 | `pg_isready -h localhost -p 5432` | `docker-compose up -d db` |

**Auto-Recovery**: true
**Startup Wait**: 30s
**Health Check Interval**: 5s
**Max Recovery Attempts**: 3

---

## Test Users

Define test users available for authentication during tests.

| Role | Email | Password | Tier | Admin | Description |
|------|-------|----------|------|-------|-------------|
| BASIC | testuser-basic@test.local | TestPass123! | free | No | Standard user flows |
| PRO | testuser-pro@test.local | TestPass123! | pro | No | Pro tier features |
| ADMIN | testadmin@test.local | TestPass123! | pro | Yes | Admin UI testing |
| AGENCY_OWNER | alex@agency.com | TestPass123! | enterprise | Yes | Agency/enterprise features |

**Seed Command**: `cd app && wasp db seed seedFrontendTestUsers`

---

## Base Configuration

| Setting | Value |
|---------|-------|
| Base URL | http://localhost:3000 |
| Default Viewport | Desktop (1280x800) |
| Mobile Viewport | Mobile (375x667) |
| Tablet Viewport | Tablet (768x1024) |
| Default Timeout | 30000 |
| Screenshot on Failure | true |

---

## Project-Specific Setup

### Before Running Tests

1. Ensure database is migrated: `cd app && wasp db migrate-dev`
2. Seed test data: `cd app && wasp db seed`
3. Clear any stale sessions in browser
4. Verify `.env` has test configuration

### Cleanup Between Tests

- Clear localStorage: `localStorage.clear()`
- Clear sessionStorage: `sessionStorage.clear()`
- Reset any feature flags to defaults

### Selector Strategy

- Prefer `data-testid` attributes for reliable selection
- Fallback to semantic selectors (button text, aria-labels)
- Avoid CSS class selectors (prone to styling changes)

---

## Environment Variables

Required environment variables for test execution:

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | Test database connection | `postgresql://...` |
| `JWT_SECRET` | Auth token secret | `test-secret-key` |
| `SKIP_EMAIL_VERIFICATION` | Bypass email for tests | `true` |

---

## Known Limitations

Document any known issues or workarounds:

- **Flaky test: TC-05** - Occasionally fails due to animation timing, add 500ms wait
- **Mobile viewport** - Some dropdowns require scroll, use explicit scroll steps
- **File upload** - Not supported via DevTools MCP, skip or mock

---

## Notes

Add any project-specific notes for test execution:

- Tests assume a fresh database state
- Some tests modify user data - run in isolation if needed
- CI environment uses different ports (3100/3101)
