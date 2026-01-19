# Create Frontend Tests Prompt

Use this prompt to generate a comprehensive frontend test plan for a sprint by analyzing its artifacts and creating executable test cases for UI verification via browser automation.

## Context
You are a QA Engineer specializing in frontend testing. Your task is to analyze a sprint's artifacts and generate a structured frontend test plan that can be executed via DevTools MCP / Puppeteer MCP or similar tools. The plan must strictly map acceptance criteria to UI-verifiable test cases with clear steps and expected outcomes.

## Inputs
- Target sprint directory (e.g., `.planning/sprints/active/##.##_sprint_name`)

## Instructions

### 1. Gather Sprint Context
Read the following files from the sprint directory (in order of priority):

**Required:**
1. `sprint-plan.md` — The execution plan with phases and checkboxes
2. `plan/original-requirements.md` — The user's original requirements

**Primary Test Sources (check in order, use first that exists):**
3. `plan/acceptance-criteria/*.md` — Detailed acceptance criteria with Definition of Done
4. `plan/tasks/*.md` — Task definitions (fallback if no acceptance-criteria)

**Additional Context (if exists):**
5. `clarifications/README.md` — Q&A and decisions made during planning
6. `plan/user-stories/*.md` — User story context
7. `plan/documentation/*.md` — Patterns and UI/Testing guidance
8. `plan/codebase-discovery.json` — Existing code paths and components

### 2. Identify UI-Testable Items
Scan acceptance criteria (or tasks) and identify items that have frontend/UI implications:
- Components that render in the browser
- User interactions (forms, buttons, navigation)
- Visual states (loading, error, success, empty states)
- Responsive behavior requirements
- RBAC/permission-based UI differences
- Data display and formatting

Exclude from frontend tests:
- Pure backend logic without UI feedback
- Background jobs with no UI feedback
- Schema migrations unless they affect UI
- Type definitions without UI manifestation

### 3. Extract Manual Review Items
Look for "Manual Review" sections in acceptance criteria and convert them to expected results:
- What was verified
- Verification method
- Specific values or thresholds mentioned

### 4. Create Test Plan Structure
Create the following structure in the sprint folder:

```
[sprint-folder]/
├── frontend-tests/
│   ├── test-plan.md          # Master test plan (you create this)
│   └── evidence/             # Empty folder for screenshots (you create this)
```

### 5. Test Plan Format
Generate `frontend-tests/test-plan.md` with this structure:

```markdown
# Frontend Test Plan: [Sprint Name]

**Generated**: YYYY-MM-DD
**Sprint**: [Sprint Number and Name]
**Source**: [Link to sprint-plan.md]

## Test Configuration

| Setting | Value |
|---------|-------|
| Base URL | http://localhost:3000 |
| Default Viewport | Desktop (1280x800) |
| Evidence Folder | ./evidence/ |

### Test Users
| Role | Email | Purpose |
|------|-------|---------|
| BASIC | testuser-basic@test.local | Standard user flows |
| PRO | testuser-pro@test.local | Pro tier features |
| ADMIN | testadmin@test.local | Admin UI testing |

### Global Checks (Apply to All Tests)
- [ ] No JavaScript console errors
- [ ] No failed network requests (4xx/5xx)
- [ ] Page loads within 3 seconds

---

## Test Cases

### TC-[AC#]-[Seq]: [Title]

**Priority**: P1/P2/P3
**Related**: [Link to acceptance-criteria/XX-XX-name.md or tasks/XX-name.md]

#### Prerequisites
- Logged in as: `[TEST_USER_ROLE]`
- Required state: [Any data or state requirements]

#### Test Configuration
| Setting | Value |
|---------|-------|
| Viewport | Desktop (1280x800) / Mobile (375x667) |
| Start URL | /path/to/page |

#### Steps
1. [Action to perform]
2. [Action to perform]
3. [Action to perform]

#### Expected Results
- [ ] [Specific observable outcome]
- [ ] [Specific observable outcome]
- [ ] [Specific observable outcome]

#### Evidence
- [ ] Screenshot: `evidence/TC-XX-XX-[description].png`

#### Cleanup
[None required / Specific cleanup actions]

---

[Repeat for each test case]

---

## Test Summary

| Priority | Count | Description |
|----------|-------|-------------|
| P1 | X | Critical path - must pass |
| P2 | X | Important features |
| P3 | X | Nice-to-have verification |
| **Total** | **X** | |

## Execution Notes

### Running Tests
1. Ensure server is running: `wasp start`
2. Ensure test users are seeded in database
3. Connect DevTools MCP to Chrome
4. Execute test cases in order (P1 first)
5. Capture evidence for failures
6. Update checkboxes as tests complete

### On Failure
- Capture screenshot immediately
- Check browser console for errors
- Document actual vs expected behavior
- Do not proceed to dependent tests
```

### 6. Test Case Generation Rules

Priority Assignment:
- **P1 (Critical)**: Core user journeys, authentication, primary features of the sprint
- **P2 (Important)**: Secondary features, edge cases that affect UX
- **P3 (Nice-to-have)**: Visual polish, non-blocking issues

Test ID Format:
- `TC-01-01` maps to acceptance criteria `01-01-*.md`
- `TC-T01` maps to task `01-*.md`
- Add sequence suffix if one AC generates multiple tests: `TC-01-01a`, `TC-01-01b`

Intelligent Merging:
- If multiple ACs test the same page/flow, combine into one test case with multiple checkpoints
- Note all related ACs in the "Related" field
- Keep the test focused on one user journey

Step Writing:
- Be specific: "Click the 'Save Profile' button" not "Submit the form"
- Include wait conditions: "Wait for loading spinner to disappear"
- Reference UI elements by visible text or semantic role when possible

Expected Results:
- Each checkbox should be independently verifiable
- Include specific values when known: "Shows '0 of 5' format" not "Shows usage count"
- Reference visual states: "Progress bar is green (usage < 70%)"

### 7. Output

1. Create the directory: `[sprint-folder]/frontend-tests/`
2. Create evidence folder: `[sprint-folder]/frontend-tests/evidence/`
3. Write the test plan: `[sprint-folder]/frontend-tests/test-plan.md`
4. Report summary after creating the files:
   - Number of test cases generated
   - Breakdown by priority
   - Any ACs/tasks that were excluded (and why)
   - Any ambiguities or items needing clarification

## Example Invocation

```
/create-frontend-tests .planning/sprints/active/62.0_sprint_57_deferred_scope/
```

This will analyze the sprint and create:
- `.planning/sprints/active/62.0_sprint_57_deferred_scope/frontend-tests/test-plan.md`
- `.planning/sprints/active/62.0_sprint_57_deferred_scope/frontend-tests/evidence/`

