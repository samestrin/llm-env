## Acceptance Criteria: (criterion title)

**Related User Story:** [[[STORY_NUMBER]]: [[STORY_TITLE]]](../user-stories/[[STORY_FILE]])

### Overview
(brief description of what this criterion validates)

### Implementation Technology

| Aspect | Technology/Approach | Notes |
|--------|---------------------|-------|
| **Component Type** | (e.g., API endpoint, React component, Service class) | (implementation notes) |
| **Test Framework** | (e.g., Jest, Pytest, RSpec) | (test framework details) |
| **Key Dependencies** | (e.g., Express, SQLAlchemy, ActiveRecord) | (dependency notes) |

### Design References

**Related Documentation:** (if design docs exist in documentation/ folder)
- [Design Doc Name](../documentation/design-doc.md) - (relevant section or line reference)

**UI/UX References:** (if applicable)
- [Wireframe/Mockup Name](../documentation/wireframes.md) - (specific screens or flows)

**API Specifications:** (if applicable)
- [API Spec Name](../documentation/api-spec.md) - (relevant endpoints)

(Note: Remove sections above if no related documentation exists)

### Related Files

⚠️ **REQUIRED** - Enables parallel sprint execution.

- `(path/to/file.ext)` - modify: (description of changes)
- `(path/to/file.test.ext)` - modify: (test additions)
- `(path/to/new-file.ext)` - create: (what this file will contain)
- `(path/to/types.ext)` - reference: (why relevant)

### Happy Path Scenarios

**Scenario 1: (scenario name)**
- **Given** (initial condition)
- **When** (user action)
- **Then** (expected outcome)

**Scenario 2: (scenario name)** (if applicable)
- **Given** (initial condition)
- **When** (user action)
- **Then** (expected outcome)

### Edge Cases

**Edge Case 1: (edge case description)**
- **Given** (edge condition)
- **When** (edge action)
- **Then** (edge outcome)

**Edge Case 2: (edge case description)** (if applicable)
- **Given** (edge condition)
- **When** (edge action)
- **Then** (edge outcome)

### Error Conditions

**Error Scenario 1: (error description)**
- **Given** (error condition)
- **When** (error trigger)
- **Then** (error handling)
  - Error message: "(specific error message)"
  - HTTP status / error code: (error code)
  - User feedback: (user visible feedback)

### Performance Requirements
- **Response Time:** (performance requirement) (e.g., "< 200ms for API response")
- **Throughput:** (throughput requirement) (e.g., "Handle 100 concurrent requests")
- **Resource Usage:** (resource constraints) (e.g., "< 50MB memory overhead")

### Security Considerations
- **Authentication:** (auth requirements)
- **Authorization:** (authz requirements)
- **Data Protection:** (data security requirements)
- **Input Validation:** (input validation rules)

### Accessibility Requirements
- (accessibility requirement 1) (e.g., "Screen reader compatible")
- (accessibility requirement 2) (e.g., "Keyboard navigation support")

### Test Implementation Guidance

**Test Type:** (UNIT|INTEGRATION|E2E|CONTRACT|PERFORMANCE|SECURITY)

**Test Data Requirements:**
- (specific test data needed)

**Mock/Stub Requirements:**
- (external dependencies to mock)

**Test Environment Setup:**
- (special setup requirements)

**Test Coverage Expectations:**
- **Unit Tests:** (specific functions to test)
- **Integration Tests:** (integration points to test)
- **E2E Tests:** (user flows to test)

**TDD Implementation Notes:**
- **Red Phase:** Write failing test for (specific behavior)
- **Green Phase:** Implement (minimal implementation)
- **Refactor Phase:** Improve (refactoring opportunities)

### Definition of Done

**Auto-Verified** (checked at sprint checkpoint - CI/build validation):
- [ ] All tests passing
- [ ] No linting errors
- [ ] Build succeeds

**Story-Specific** (verified by LLM after implementation):
- [ ] (criterion derived from happy path scenario 1)
- [ ] (criterion derived from happy path scenario 2, if applicable)
- [ ] (criterion derived from edge cases, if applicable)

**Manual Review** (verified by human reviewer post-sprint):
- [ ] Code reviewed and approved
- [ ] (visual/UX verification if applicable)
- [ ] (accessibility verification if applicable)

---

**Created:** [[TODAYS_DATE]]
**Status:** Draft - Awaiting Implementation
