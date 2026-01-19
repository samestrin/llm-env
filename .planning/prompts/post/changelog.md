# Changelog Generator & Archivist

**Role:** Release Engineer & Documentation Maintainer
**Task:** Generate a strict, evidence-based changelog entry from sprint artifacts and manage file hygiene.

## Inputs
**Sprint Directory:** `{{PATH_TO_SPRINT_DIR}}` (e.g., `.planning/sprints/completed/XX.X_sprint_name`)

## Artifact Hierarchy (Strict Order of Precedence)
1. **Validation:** `*_sprint-audit-report.md` (If this flags an item as incomplete, exclude it even if the postmortem claims it is done).
2. **Execution:** `*_postmortem.md` (Primary source for "what happened").
3. **Intent:** `sprint-plan.md` (Source for Title and Goals).
4. **Origin:** `plan/original-requirements.md` (Fallback for Goals).

## Processing Rules

### 1. Analysis Phase (Internal)
Before generating the output, analyze the inputs:
- **Conflict Check:** Compare the *Postmortem* claims against the *Audit Report*. Identify any discrepancies.
- **Scope Check:** Identify items listed in the *Plan* that are missing from the *Postmortem/Audit* (mark as Deferred).
- **Date Extraction:**
  1. Look for `Date: YYYY-MM-DD` in `*_postmortem.md`.
  2. If missing, look in `*_sprint-audit-report.md`.
  3. Fallback: Use current date.
- **Version Calculation:**
  - Pattern: `Sprint XX.Y` → `0.XX.Y.0`
  - Pattern: `Sprint XX` → `0.XX.0.0`

### 2. Content Generation Rules
- **Title:** Use the H1 from `sprint-plan.md`.
- **Goal:** Summarize the `sprint-plan.md` goal.
- **Categories:**
  - `Added`: User-visible features (validated by Audit).
  - `Changed`: Logic/UX changes.
  - `Fixed`: Bug fixes.
  - `Technical Notes`: Metrics, Test counts (exact numbers preferred), Architecture changes.
  - `Deferred`: Planned items that did not ship.
- **Style:** Concise, past tense, bullet points.

### 3. Archiving Logic (Safety First)
- **Threshold:** `RETAIN_COUNT = 10`.
- **Process:**
  1. Count the existing releases in `CHANGELOG.md` (headers starting with `## [`).
  2. If count > `RETAIN_COUNT`:
     - Identify the oldest entries at the bottom of the list.
     - **STEP A:** Move these entries to `changelogs/CHANGELOG-ARCHIVE-YYYY.md`.
     - **Insertion Point (Archive):** Insert the moved entries **immediately after** the `# Changelog Archive YYYY` header. (This ensures the archive stays in descending order: Newest Archive -> Oldest Archive).
     - **STEP B:** Remove those entries from `CHANGELOG.md`.
     - **STEP C:** Update the `## Archives` list in `CHANGELOG.md` to point to the year file if not already present.

## Output Instructions

**Action 1: The New Entry**
Find the exact line `## Latest Changes` in `CHANGELOG.md`. Insert the new entry **immediately below** that line.

**Format:**
```markdown
## [0.XX.Y.0] - YYYY-MM-DD

### [Title]
**Goal:** [Summary]

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Technical Notes
- **Test Coverage:** [Summary from Audit]
- **Performance:** [Summary from Audit/Postmortem]
- **Architecture:** [Summary from Plan/Postmortem]

### Deferred
- [Optional: List items planned but not shipped]
```

**Action 2: Archive Maintenance**
- If items were moved to the archive, ensure they were inserted at the top of the archive list (under the header `# Changelog Archive YYYY`).
- Ensure `CHANGELOG.md` has the correct link under `## Archives`.

---
**CRITICAL:**
1. Do not invent features. If the Audit says a feature is "Partial" or "Failed," list it in 'Deferred' or 'Technical Notes'.
2. **Anchor Strategy:**
   - Main File: Insert NEWEST items under `## Latest Changes`.
   - Archive File: Insert NEWEST archived items under `# Changelog Archive YYYY`.