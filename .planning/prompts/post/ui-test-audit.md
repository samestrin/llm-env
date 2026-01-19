# UI Test Audit Prompt

Use this prompt to audit frontend UI test plans by comparing the planned test coverage, acceptance criteria, execution notes, and collected evidence. Confirm findings, verify gaps, and update the technical debt backlog accordingly.

## Context
You are an expert QA Lead and Technical Project Manager. Your goal is to perform a rigorous audit of UI test artifacts to ensure that critical user flows are covered, failures are substantiated with evidence, and gaps are tracked in the technical debt backlog.

## Inputs
You will be provided with either a test plan path or a UI test run directory. Typical targets include:
- `.planning/technical-debt/frontend-tests/mvp-smoke-test-plan.md`
- `.planning/sprints/completed/XX.X_*/frontend-tests/test-plan.md`
- `.planning/technical-debt/frontend-tests/runs/YYYY-MM-DD/<scope>/`

## Instructions

### 1. Information Gathering
Locate and read the following artifacts within the provided target. Prefer artifacts in the `runs/` directory when present:
1. **UI Test Plan**: `frontend-tests/test-plan.md` (or any referenced test plan file)
   - Purpose: Defines test phases, test cases (TC-XX), prerequisites, steps, and expected results.
2. **Acceptance Criteria (AC)**: Any files referenced by the test plan (commonly `../plan/acceptance-criteria/*`)
   - Purpose: Ground truth for what must be validated by UI tests.
3. **Execution Notes**: The "Execution Notes" section inside the test plan
   - Purpose: Operational steps to run tests and environmental prerequisites.
4. **Run Artifacts**: Artifacts produced by a specific test execution located under `runs/YYYY-MM-DD/<scope>/`
   - Typical structure:
     - `session-summary.md`
     - `TC-XX-results.md` files (one per test case)
     - `evidence/` directory containing screenshots and captured logs
   - Purpose: Primary source for verified results and evidence
   - Fallback: If no `runs/` directory exists for this scope, look for an adjacent `evidence/` directory next to the test plan.
5. **Sprint Context (optional)**: `sprint-plan.md` in the sprint root (if the test plan lives under a completed sprint)
   - Purpose: Context of features and priorities covered by the test plan.

#### Run Artifact Discovery
- If the input is a test plan path, derive `<scope>` from its parent directory name (e.g., `55.0_limit_enforcement_ui`).
- Search in `.planning/technical-debt/frontend-tests/runs/` for dated directories matching `<scope>`.
- Prefer the latest date by directory name (YYYY-MM-DD). Use this as the canonical run directory for auditing.

#### TC ID Normalization
- Normalize test case identifiers when mapping plan entries to run artifacts:
  - Accept `TC-1`/`TC-01` variants and zero-pad to two digits (`TC-01`).
  - Strip surrounding whitespace and case-normalize.
  - Match `TC-XX-results.md` files by normalized ID.
  - If a result file is missing, record as "Missing Result Artifact" and search evidence for `evidence/TC-XX-*`.

### 2. Analysis Steps
#### A. Alignment Check (Acceptance Criteria vs. Test Plan)
- Does the test plan fully cover the acceptance criteria it references?
- Are AC items missing corresponding test cases or steps?
- Priority: High. Tests must validate planned requirements.

#### B. Coverage Check (Test Plan Structure)
- For each phase and TC, confirm coverage for critical feature areas noted in the plan.
- Identify tests marked as P1/P2/P3 and assess whether P1 paths are adequately covered.
- Flag missing responsive, loading, and RBAC tests if applicable.

#### C. Evidence Verification (Findings vs. Artifacts)
- For each TC, read corresponding `TC-XX-results.md` in the run directory.
- Confirm concrete evidence exists in `runs/.../evidence/` (screenshot, console, network) following naming conventions.
- Assess evidence quality: clarity, relevance, and sufficiency to prove the issue.
- If findings are claimed without artifacts, mark as "Unsubstantiated" and recommend re-run with capture.

#### E. Traceability & Code References
- When failures or gaps are identified, include precise code references using `file_path:line_number`.
- Prefer references to routes, guards, components, and operations relevant to the TC.
- Cross-link AC files referenced by the TC to support traceability.

#### D. Completion Audit (Plan vs. Execution)
- Use `session-summary.md` to obtain overall run status and blockers.
- Cross-check test steps and expected results vs. `TC-XX-results.md` content and captured evidence.
- Identify unexecuted or partially executed tests (unchecked steps, missing captures) and note blockers.
- If tests claim success for complex features without evidence, lower confidence.

### 3. Output Format
Generate a **UI Test Audit Report** file named `####-##-##_ui-test-audit-report.md` (YYYY-MM-DD for today's date). Place it in:
- The target test directory (e.g., `.planning/sprints/completed/XX.X_*/frontend-tests/`), and
- Optionally, the run directory for the audited execution (e.g., `.planning/technical-debt/frontend-tests/runs/YYYY-MM-DD/<scope>/`).
Use Markdown with the following sections:

```markdown
# UI Test Audit Report: [Scope Name]

## 1. Executive Summary
- **Overall Status**: [Pass / Partial / Fail]
- **Coverage Score**: [0-100]% (How well tests cover referenced AC)
- **Evidence Confidence**: [High/Medium/Low] (Based on quality and completeness of artifacts)
- **Blockers**: [List any P1 blockers that prevent valid conclusions]
 - **Run Directory**: [.planning/technical-debt/frontend-tests/runs/YYYY-MM-DD/<scope>/]

## 2. Verified Findings
- [List confirmed failures with links to evidence files]
- Example: "TC-01 RBAC failure confirmed: non-admin accessed /admin" → `runs/YYYY-MM-DD/<scope>/evidence/TC-01-rbac-fail-non-admin-accessed.png`

## 3. Missing or Incomplete Coverage
- [List ACs or features lacking adequate test cases or steps]
- [List tests executed without required evidence]

## 4. Artifact Quality
- **Test Plan Quality**: [Completeness, clarity, prioritization]
- **AC Mapping**: [Coverage, traceability from TC to AC]
- **Evidence Quality**: [Screenshots/logs/network traces quality]
- **Execution Notes**: [Actionability and reproducibility]
 - **Run Artifacts**: [Presence and completeness of `session-summary.md`, `TC-XX-results.md`, `evidence/`]

Include code references for confirmed items using `file_path:line_number` and link to AC documents.

## 5. Recommendations
- [Actionable steps to fix gaps or improve testing]

## 6. Technical Debt Updates
- [Summarize items appended to `.planning/technical-debt/README.md`]
```

### 4. Action Phase: Verification & Backlog Update
After generating the report, perform the following actions:

1. **Verify Failures and Gaps via Codebase Review**
   - For each failure or suspected gap, corroborate with `TC-XX-results.md` and captured evidence.
   - Perform a focused codebase review to confirm whether the issue is real and reproducible.
   - Example queries based on common features:
     - RBAC/Admin: search for routing/guards around `/admin` and role checks
     - Usage Meter: search for `UsageMeter`, usage limits, progress bar rendering
     - Industry Keywords: search for admin list/table, CRUD flows, dialogs

2. **Update Technical Debt Backlog**
   - Append confirmed gaps to the single source of truth at: `.planning/technical-debt/README.md`.
   - Use the format:
     ```markdown
     ### Source: [Test Plan or Sprint Name]
     - **[Issue Title]**: [Brief description referencing AC/TC]
       - **Evidence**: [runs/YYYY-MM-DD/<scope>/evidence/...]
       - **Code Reference**: `file_path:line_number`
       - **Severity**: [feature gap | defect | plan mismatch]
       - **Suggested Fix**: [concise action]
     ```
   - Note: Do not remove existing items; append new findings under the existing backlog section.

3. **Update Frontend Test Run History**
   - Path: `.planning/technical-debt/frontend-tests/run-history.md`.
   - Append or update a row in the table using the latest audited run.
   - Source of metrics: Prefer `session-summary.md` in the run directory; if missing, derive counts from `TC-XX-results.md` files.
   - Row fields:
     - `Date`: YYYY-MM-DD (today)
     - `Plan`: Friendly scope name (derive from test plan title or parent folder, e.g., `55.0 Limit Enforcement UI`).
     - `Executed`: Total tests executed.
     - `Passed`: Total tests passed.
     - `Failed`: Total tests failed.
     - `Blocked`: Total tests blocked.
     - `Pass Rate`: `(Passed / Executed) * 100`, rounded to nearest integer with `%`.
     - `Notes`: Brief blockers or highlights from the run (one line).
   - If a row exists for the same `Date` and `Plan`, update it; otherwise append a new row under the header.

### 5. Rules
- **Source of Truth Hierarchy**: `plan/acceptance-criteria/*` > `sprint-plan.md` (if applicable) > `frontend-tests/test-plan.md` > `runs/YYYY-MM-DD/<scope>/` (`session-summary.md`, `TC-XX-results.md`, `evidence/*`) > Execution Notes.
- If an issue is reported without evidence, flag as "Unsubstantiated" and recommend capture.
- If evidence shows behavior for features not in AC/plan, flag as "Unplanned Work".
- If AC is planned but lacking tests or failing without remediation, flag as "Potential Incomplete Work".

### 6. Scoring Model
- **Coverage Score (0–100%)**:
  - Numerator: Number of AC items with at least one adequately executed TC (has `TC-XX-results.md` and required evidence).
  - Denominator: Total AC items referenced by the test plan.
  - Weight P1 tests higher: P1-covered ACs contribute 1.0, P2 contribute 0.7, P3 contribute 0.5.
- **Evidence Confidence (High/Medium/Low)**:
  - High: All failing TCs include clear screenshots/logs and result files.
  - Medium: Some failing TCs lack one artifact type or have partial captures.
  - Low: Findings mostly without artifacts or ambiguous captures.

### 6. Execution Guidance
- When possible, re-run the tests using the commands documented in the test plan (e.g., `/execute-frontend-tests <path> [options]`) to reproduce and capture missing evidence. Results will be saved under `runs/YYYY-MM-DD/<scope>/`.
- Ensure environment prerequisites are satisfied prior to execution (app server running, seeded users, browser connected, correct base URL).
