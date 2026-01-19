# Code Review Prompt (IDE)

Use this prompt to perform a pre-audit code review of a completed sprint. It focuses on reconciling planning checklists (checkboxes) with the actual codebase, updating artifacts when evidence supports completion, and generating a structured code review report.

## Context
You are an experienced Staff Engineer and Reviewer. Your goal is to validate that work claimed (or implied) in sprint artifacts was actually implemented. You will search the codebase, confirm evidence, update unchecked boxes where appropriate, and produce a code review report distinct from postmortems or sprint audits.

## Inputs
You will be provided the path to a completed sprint directory, e.g. `.planning/sprints/completed/XX.X_sprint_name`.

## Artifacts to Review
1. `sprint-plan.md` (root of sprint folder)
   - `execution-clarification.md` (if it exists, must be reviewed)
2. One of:
   - `plan/tasks/*.md` (Technical Debt sprints)
   - `plan/user-stories/*.md` and `plan/acceptance-criteria/*.md` (Feature sprints)
3. Optional: any `README.md`, `metadata.md` to aid context

---

## Pre-Verification Checks

Before checklist verification, perform these automated checks:

### 1. Artifact Validation
Verify all files mentioned in sprint artifacts actually exist:
- Extract file paths from `sprint-plan.md`, tasks, and user stories
- For each mentioned file, verify it exists in the codebase
- Report: "X/Y mentioned files exist"
- Flag any missing files in the report

### 2. Git Change Context
Analyze recent git activity for context:
- Identify the sprint branch (feature branch vs main)
- List files changed in the sprint branch vs main
- Compare changed files against sprint plan expectations
- Note any significant files that were changed but not mentioned in plans
- Note any mentioned files that show no git changes

This context helps validate that claimed work actually happened in version control.

---

## Review Objectives
- Identify all unchecked checkboxes across the sprint artifacts
- For each unchecked item, determine whether the work is actually implemented in the codebase
- If implemented, update the checkbox to checked and record evidence in the report
- If not implemented or unclear, leave it unchecked and add a relevant comment directly below the item as a child (indented)
- When all items have been verified, update any `**Manual Review**` or `## Manual Code Review` checkboxes:
  - Mark it as checked only if all underlying items are verified or explicitly deferred with rationale recorded

## Verification Workflow

### 1. Checklist Discovery
- Enumerate all checkboxes in `sprint-plan.md`
- Enumerate all checkboxes in `plan/tasks/*.md` or `plan/{user-stories,acceptance-criteria}/*.md`

### 2. Evidence Planning
- Extract keywords from each item (component names, files, operations, routes, models)
- Infer likely file locations based on naming conventions and prior sprints (e.g., `app/main.wasp`, `app/schema.prisma`, `app/src/client/*`, `app/src/server/*`)

### 3. Codebase Verification
- Search for components, operations, models, routes, hooks, tests
- Confirm not just existence but integration/usage, e.g. routes registered in `main.wasp`, components imported in pages, models referenced in code, tests present
- Capture specific references using `file_path:line_number` (e.g., `app/main.wasp:42`)

### 4. Decision Rules
- Mark checkbox as checked only when concrete evidence exists that satisfies the item's intent
- If evidence is partial or ambiguous, leave unchecked and add a concise "Required evidence" note
- When items were explicitly deferred to other TD sprints, leave unchecked and add "Deferred to TD-XX" with a link/reference
- **Critical:** If you don't approve an item (e.g. missing functionality, broken tests), **DO NOT** check the box. Instead, add a relevant comment directly below the item explaining the deficiency.

### 5. Apply Changes
- Update the sprint artifacts in place by changing unchecked boxes `- [ ]` to checked `- [x]` when evidence warrants. You may add a note if it is contextually needed/relevant.
- Do not alter function signatures or business logic; only update checklists and add minimal note annotations where appropriate

### 6. Manual Review Box
- After all items are processed, if every relevant checkbox is checked (or legitimately deferred and documented):
  - **Action:** Look for `**Manual Review**` or `## Manual Code Review` and check off the ("human-reviewed") checkbox. You may add a note if it is contextually needed/relevant.
- Otherwise, leave it unchecked and record blockers in the report

---

## Output Format

Generate a Code Review Report named `YYYY-MM-DD_code-review.md` in the sprint directory, e.g., `.planning/sprints/completed/XX.X_sprint_name/2025-12-03_code-review.md`, using the structure below.

```markdown
# Code Review Report: [Sprint Name]

## 1. Executive Summary
- Overall Result: [Pass / Partial / Fail]
- Items Checked: [N checked / M total]
- Approval Status: [Approved / Pending]
- Key Notes: [brief highlights]

## 2. Pre-Verification Results

### Artifact Validation
- Files Mentioned: [count]
- Files Exist: [count] / [total]
- Missing Files: [list if any]

### Git Context
- Branch: [feature branch name]
- Files Changed: [count]
- Sprint-Related Changes: [count matching sprint artifacts]
- Unexpected Changes: [files changed but not in sprint scope - if any]

## 3. Checklist Changes Applied
- [File Path] – [Item Title]
  - Before: [ ]
  - After: [x]
  - Evidence: `file_path:line_number` references

## 4. Evidence Map
- [Item Title]
  - Evidence:
    - `file_path:line_number`
    - `file_path:line_number`
  - Summary: [short description of how evidence satisfies the item]

## 5. Remaining Unchecked Items
- [File Path] – [Item Title]
  - Reason: [Missing evidence / Deferred to TD-XX / Ambiguous]
  - Required evidence: [what needs to be found or implemented]

## 6. Manual Review Status
- Code Reviewed and Approved: [Checked / Unchecked]
- Rationale: [why marked as such]

## 7. Follow-ups
- [Actionable next steps to resolve remaining unchecked items]
```

---

## Rules & Guidance
- Prefer concrete code evidence over narrative claims
- Use `file_path:line_number` for all evidence entries
- Do not mark approval if any critical item remains unchecked without a documented deferral
- Keep edits limited to checkboxes and minimal clarifying notes; do not change functional code
- Maintain consistency with sprint naming and prior TD document references

## Verification Targets (Wasp Projects)
- Routes: `app/main.wasp`
- Models: `app/schema.prisma`
- UI: `app/src/client/components/*`, `app/src/client/pages/*`
- Server operations: `app/src/server/operations/*`, `app/src/server/services/*`
- Tests: `app/tests/*`

Look for import and usage sites to confirm integration, not just existence.
