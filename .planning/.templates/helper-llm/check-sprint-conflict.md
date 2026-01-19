# Sprint Conflict Detection Task

Analyze whether a new plan request conflicts with or depends on an actively running sprint.

## Task Overview

You are checking if a new implementation plan should wait for an active sprint to complete, or if it can proceed independently.

## Input Data

**Active Sprint Path:** [[ACTIVE_SPRINT_PATH]]
**Active Sprint Original Request:** `[[ACTIVE_SPRINT_PATH]]plan/original-requirements.md`

**New Plan Description:**
```
[[NEW_PLAN_DESCRIPTION]]
```

## Analysis Requirements

### 1. Load Active Sprint Request

Read the active sprint's original request file:
```
[[ACTIVE_SPRINT_PATH]]plan/original-requirements.md
```

This file contains what the active sprint is implementing.

### 2. Conflict/Dependency Classification

**CONFLICT: HIGH**
- Both touch same files/directories
- New plan modifies code active sprint is building
- Same feature domain (both working on auth, API, database, etc.)
- Incompatible technical approaches (both changing same architecture)
- Would cause merge conflicts or broken functionality
- **Action:** BLOCK new plan, recommend waiting for sprint completion

**DEPENDENCY: HIGH**
- New plan requires features/APIs being built in active sprint
- New plan assumes active sprint deliverables exist
- New plan builds on top of active sprint work
- Active sprint is prerequisite for new plan
- **Action:** BLOCK new plan, recommend waiting or creating sub-sprint under active sprint

**DEPENDENCY: LOW**
- New plan would benefit from active sprint but can work without it
- Slight overlap in domain but different features
- Shared utilities/libraries but no direct dependency
- **Action:** WARN user, allow proceeding with note

**CONFLICT: NONE**
- Completely different areas of codebase
- Different feature domains
- No shared files or dependencies
- Can work in parallel safely
- **Action:** SILENT, continue without warning

### 3. What to Check

**File/Path Overlap:**
- Do both mention same files, directories, or modules?
- Would both modify same codebase areas?

**Feature Domain:**
- Authentication, API endpoints, database, UI, tests, deployment?
- Same domain = likely conflict
- Different domains = likely safe

**Technical Dependencies:**
- Does new plan require APIs/functions from active sprint?
- Does new plan assume active sprint deliverables exist?
- Would new plan break if active sprint changes architecture?

**Timeline/Blocking:**
- Can new plan proceed without active sprint?
- Must new plan wait for active sprint completion?
- Could both run in parallel?

**Sub-Sprint Potential:**
- Is new plan actually related work that should be a sub-sprint?
- Would combining them make more sense than separate plans?

## Required Output Format

```markdown
# Sprint Conflict Analysis

**Classification:** [HIGH_CONFLICT|HIGH_DEPENDENCY|LOW_DEPENDENCY|NONE]

---

## Active Sprint Summary

**Sprint:** [[ACTIVE_SPRINT_PATH]]

**What Active Sprint is Building:**
(1-2 sentence summary from original-requirements.md)

**Key Files/Paths:**
- File/path 1
- File/path 2

**Feature Domain:**
(Authentication, API, Database, UI, Tests, etc.)

---

## New Plan Summary

**What New Plan Wants to Build:**
(1-2 sentence summary from description)

**Feature Domain:**
(Authentication, API, Database, UI, Tests, etc.)

---

## Conflict/Dependency Analysis

### File/Path Overlap
(Do they touch same files?)

### Feature Domain Overlap
(Same area of application?)

### Technical Dependencies
(Does new plan need active sprint deliverables?)

### Timeline Impact
(Can both run in parallel or must new plan wait?)

---

## Recommendation

**Classification:** [HIGH_CONFLICT|HIGH_DEPENDENCY|LOW_DEPENDENCY|NONE]

### If HIGH_CONFLICT:
❌ **BLOCK:** New plan would conflict with active sprint work.

**Reason:** (specific conflict explanation)

**Suggested Actions:**
1. Wait for active sprint to complete: [[ACTIVE_SPRINT_PATH]]
2. Review sprint status with team
3. Retry planning after sprint merges

**Alternative:** Consider creating a sub-sprint if the work is related and can be coordinated.

---

### If HIGH_DEPENDENCY:
❌ **BLOCK:** New plan depends on active sprint deliverables.

**Reason:** (specific dependency explanation)

**Suggested Actions:**
1. Wait for active sprint to complete: [[ACTIVE_SPRINT_PATH]]
2. **OR** Create sub-sprint under active sprint if work is tightly coupled
3. Retry planning after sprint delivers required features

**Sub-Sprint Recommendation:**
(If new plan is related, suggest creating sub-sprint instead)

---

### If LOW_DEPENDENCY:
⚠️  **WARN:** Potential overlap detected but not blocking.

**Reason:** (minor overlap explanation)

**Suggested Actions:**
1. Proceed with caution
2. Coordinate with active sprint team
3. Monitor for integration issues

**Note:** (what to watch out for)

---

### If NONE:
✅ **PROCEED:** No conflicts or dependencies detected.

**Reason:** Different feature domains, no file overlap, independent work.

**Safe to proceed:** New plan can run in parallel with active sprint without issues.

---
```

**OUTPUT ONLY THE CONFLICT ANALYSIS MARKDOWN - NO OTHER TEXT**

---

## Examples

### Example 1: HIGH_CONFLICT
- Active sprint: Building authentication system in `src/auth/`
- New plan: Refactoring authentication flow in `src/auth/`
- **Result:** HIGH_CONFLICT (same files, same feature)

### Example 2: HIGH_DEPENDENCY
- Active sprint: Building REST API endpoints in `src/api/`
- New plan: Building UI dashboard that calls those API endpoints
- **Result:** HIGH_DEPENDENCY (new plan needs APIs from active sprint)

### Example 3: LOW_DEPENDENCY
- Active sprint: Adding database migrations for user tables
- New plan: Adding new API endpoints (uses user tables but doesn't modify schema)
- **Result:** LOW_DEPENDENCY (shared data model but not blocking)

### Example 4: NONE
- Active sprint: Building payment processing in `src/payments/`
- New plan: Adding email notification system in `src/notifications/`
- **Result:** NONE (completely different domains and files)

---

## Analysis Instructions

1. Read the active sprint's original-requirements.md file
2. Compare with new plan description
3. Identify file/path overlap
4. Identify feature domain overlap
5. Check for technical dependencies
6. Classify severity level
7. Output recommendation with specific reasoning
8. Suggest concrete next steps based on classification
