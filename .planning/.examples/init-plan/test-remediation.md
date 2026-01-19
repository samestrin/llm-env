# Test Remediation: Improve API Endpoint Coverage

## Current State

API endpoint test coverage is at 34%, well below our 80% target. This has led to:
- 3 production incidents in the past quarter from untested edge cases
- Low confidence during refactoring
- Manual QA bottleneck before releases

## Coverage Analysis

### By Module

| Module | Current | Target | Gap |
|--------|---------|--------|-----|
| /api/auth/* | 65% | 90% | 25% |
| /api/users/* | 45% | 80% | 35% |
| /api/orders/* | 28% | 80% | 52% |
| /api/products/* | 35% | 80% | 45% |
| /api/payments/* | 22% | 90% | 68% |
| /api/admin/* | 15% | 80% | 65% |

### Critical Gaps

1. **Payment endpoints (22%)** - Highest risk, handles money
2. **Admin endpoints (15%)** - Security-sensitive operations
3. **Order endpoints (28%)** - Core business flow

## Root Cause Analysis

### Why coverage is low:
- Rapid feature development prioritized over tests
- No test requirements in PR review checklist
- Complex test setup for database-dependent endpoints
- Missing test utilities and fixtures

### Barriers to writing tests:
- Database setup takes 30+ seconds per test file
- No standardized request/response mocking
- Authentication helpers are cumbersome
- Lack of example tests to follow

## Remediation Goals

### Phase 1: Foundation (This Plan)
- [ ] Create test utilities and fixtures
- [ ] Standardize test patterns with examples
- [ ] Add tests for highest-risk endpoints (payments, admin)
- [ ] Target: 60% overall coverage

### Phase 2: Comprehensive (Future)
- [ ] Reach 80% coverage target
- [ ] Add integration tests
- [ ] Implement coverage gates in CI

## Test Infrastructure Improvements

### 1. Database Test Utilities
```typescript
// Goal: Reduce setup from 30s to <1s
beforeAll(() => testDb.setup())
afterAll(() => testDb.teardown())
beforeEach(() => testDb.seed('standard'))
```

### 2. Authentication Helpers
```typescript
// Goal: One-liner auth for any role
const response = await request(app)
  .get('/api/admin/users')
  .withAuth('admin')  // or 'user', 'guest'
```

### 3. Fixture Library
```typescript
// Goal: Consistent, realistic test data
const user = fixtures.user({ role: 'admin' })
const order = fixtures.order({ user, items: 5 })
```

## Priority Endpoints

### Critical (Must Test)

| Endpoint | Current Tests | Risk | Notes |
|----------|---------------|------|-------|
| POST /api/payments/charge | 0 | Critical | Handles money |
| POST /api/payments/refund | 0 | Critical | Handles money |
| DELETE /api/admin/users/:id | 0 | High | Data deletion |
| PUT /api/admin/permissions | 0 | High | Security-sensitive |
| POST /api/orders | 2 | High | Core business flow |

### High (Should Test)

| Endpoint | Current Tests | Gap |
|----------|---------------|-----|
| GET /api/users/me | 1 | Missing error cases |
| PUT /api/users/me | 0 | No tests |
| GET /api/orders/:id | 1 | Missing auth checks |
| POST /api/products | 1 | Missing validation |

## Test Types Needed

### Unit Tests (API Handlers)
- Input validation
- Business logic branching
- Error response formatting

### Integration Tests
- Database operations
- Authentication/authorization
- Cross-endpoint workflows

### Contract Tests
- Request/response schema validation
- Backward compatibility checks

## Success Criteria

- [ ] Test utilities created and documented
- [ ] All critical endpoints have tests (5 endpoints)
- [ ] All high-priority endpoints have tests (4 endpoints)
- [ ] Coverage reaches 60%
- [ ] Test execution time < 2 minutes
- [ ] Example tests added to CONTRIBUTING.md

## Files to Create/Modify

### New Files
- `tests/utils/testDb.ts` - Database utilities
- `tests/utils/auth.ts` - Authentication helpers
- `tests/fixtures/index.ts` - Fixture library
- `tests/api/payments/*.test.ts` - Payment tests
- `tests/api/admin/*.test.ts` - Admin tests

### Modify
- `jest.config.js` - Add coverage thresholds
- `CONTRIBUTING.md` - Add testing guidelines
- `.github/workflows/test.yml` - Add coverage reporting

## Constraints

- Tests must run in CI (no external dependencies)
- Cannot modify production code for testability (minimal changes only)
- Must work with existing Jest + Supertest setup

## Out of Scope

- Frontend/E2E tests
- Performance/load testing
- Security penetration testing
- Legacy endpoint deprecation
