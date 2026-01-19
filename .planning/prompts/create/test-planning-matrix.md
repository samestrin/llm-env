# Test Planning Matrix Prompt

Use this prompt to generate a comprehensive test planning matrix (`test-planning-matrix.md`) for a given plan directory by reading its `plan.md`, `user-stories/`, and `acceptance-criteria/` files. The matrix maps acceptance criteria to test types, complexity, and estimated effort, ensuring TDD coverage across all stories.

## Context
You are a Senior QA Lead and Technical Program Manager. Your goal is to ensure that every acceptance criterion is represented in the test plan with the correct test type, realistic complexity, and effort estimate, aligned with the project’s target test pyramid. The output must be written to the provided plan directory.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/XX.X_plan_name`).

## Instructions

### 1. Collect Source Files
Read the following within the provided directory:
- `plan.md` — High-level objectives, phases, and success criteria
- `user-stories/*.md` — One file per story (ordered by `NN-` prefix)
- `acceptance-criteria/*.md` — One or more files per story (`NN-MM-...` naming)

### 2. Build Story Index
- If `user-stories.md` exists, use it to confirm ordering and coverage.
- Otherwise, derive ordering by sorting `user-stories/*.md` alphanumerically by their `NN` prefix.

### 3. Map Acceptance Criteria
- For each story `NN`, select all acceptance criteria files matching `NN-*.md`.
- Extract the following fields from each AC file to inform the matrix:
  - `Test Type` (from "Test Implementation Guidance" or explicit "Test Type" section)
  - `Test Framework` (helps infer type if not explicitly set)
  - `Performance / Build Requirements` (indicates complexity/effort)
  - `Key Dependencies` (indicates integration/system scope)
  - `Test Coverage Expectations` (affects complexity)

### 4. Classify Test Type
Use explicit AC metadata when available. If missing, infer using these rules:
- `Playwright` → `E2E`
- React component tests → `Component`
- `Vitest` with DB/services → `Integration`
- Pure logic/provider modules → `Unit`
- CI workflow or scripts → `System`
- Marketplace/Policy checklists → `Manual`
- Policy-only items → `N/A`

### 5. Assign Complexity and Effort
Set complexity using AC signals:
- **S (Small):** Pure unit/component, minimal dependencies, no strict perf/security constraints
- **M (Medium):** Integration/system tests, performance requirements, external APIs, multiple dependencies
- **L (Large):** Security-critical (e.g., OAuth token encryption), data isolation with 100% coverage, complex DB flows

Estimate effort with default mapping (adjust if AC implies higher cost):
- `S` → `1h`
- `M` → `2h`
- `L` → `3h`
- Add `+1h` if AC requires ≥90% coverage, security review, or heavy setup (e.g., mocks for multiple services)

### 6. Compose the Matrix
- Add a header with plan name and created date.
- Include a **Test Pyramid Summary** using target ratio: `70% Unit`, `20% Integration`, `10% E2E`.
- For each story, create a section:
  - Title: `### [Story NN: <Title>]` with a link to the story file
  - Table columns: `Acceptance Criteria`, `Test Type`, `Complexity`, `Estimated Effort`
  - Each row links to the AC file using a relative path

### 7. Validate Coverage
- Every AC file in `acceptance-criteria/` must appear exactly once in the matrix.
- Every story in `user-stories/` must have ≥1 AC row.
- Ensure links resolve correctly from the matrix location.

### 8. Output Path
- Preferred: write to `<provided_directory>/plan/test-planning-matrix.md` (matching existing conventions)
- Fallback: if `plan/` subfolder does not exist, write to `<provided_directory>/test-planning-matrix.md`

## Output
Create or overwrite `test-planning-matrix.md` with the following structure:

```markdown
# Test Planning Matrix

**Created:** <ISO Timestamp>
**Plan:** [<Plan Title>](../plan.md)

## Matrix Overview

This matrix maps acceptance criteria to test types, ensuring comprehensive TDD coverage for all user stories.

## Test Pyramid Summary

**Target Test Pyramid Ratio**: 70% Unit, 20% Integration, 10% E2E

### [Story NN: <User Story Title>](../user-stories/NN-<slug>.md)

| Acceptance Criteria | Test Type | Complexity | Estimated Effort |
|---------------------|-----------|------------|------------------|
| [<AC Title>](../acceptance-criteria/NN-01-<slug>.md) | Unit/Integration/Component/E2E/System/Manual/N/A | S/M/L | 1h/2h/3h |
| ... | ... | ... | ... |

## Test Coverage Targets

- **Unit Test Coverage:** 80%+ line coverage
- **Integration Test Coverage:** All API endpoints and service integrations
- **E2E Test Coverage:** 100% of critical user journeys

---

**Last Updated:** <ISO Timestamp>
```

## Notes
- Always use AC metadata to drive classification; fall back to inference rules only when necessary.
- Keep the matrix concise and scannable; avoid duplicating context already present in AC files.
- Ensure relative links work from the chosen output path.

