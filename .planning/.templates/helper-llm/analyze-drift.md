# Sprint Drift Analysis Task

Analyze whether the sprint implementation has drifted from the original user request.

## Drift Analysis Requirements

### 1. Load Source of Truth (Original Request)

**Original User Request:**
```
[[SPRINT_FOLDER]]plan/original-requirements.md
```

This file contains what the user **actually** asked for. All drift analysis is measured against this source of truth.

### 2. Load Sprint Implementation Plan

**Sprint Plan:**
```
[[SPRINT_FOLDER]]sprint-plan.md
```

This file contains what was planned to be implemented.

### 3. Drift Severity Levels

**SEVERITY: NONE**
- Sprint deliverables directly address the original request
- All user requirements are covered
- No significant scope creep or omissions
- Technical approach aligns with user's stated needs

**SEVERITY: MINOR**
- Sprint covers original request but added extra features not requested
- Minor scope creep (e.g., added nice-to-haves)
- Reorganized structure but core intent preserved
- Technical approach differs slightly but achieves same goals
- User can still recognize their request in the deliverables

**SEVERITY: MAJOR**
- Sprint significantly diverged from original request
- Missing core requirements from original request
- Implemented features user didn't ask for instead of what they wanted
- Changed fundamental approach without user input
- User would not recognize their request in the deliverables
- Requires realignment to match original intent

**SEVERITY: UNKNOWN**
- Cannot determine drift level (missing files, parse errors, etc.)
- Original request is too vague to compare against
- Sprint plan is incomplete or corrupted

### 4. What to Check

**Scope Alignment:**
- Does sprint cover all requirements from original request?
- Are there features in sprint not mentioned in original request?
- Are there requirements from original request missing in sprint?

**Technical Approach:**
- Does technical approach match user's constraints/preferences?
- Are there architectural changes not discussed with user?
- Does implementation strategy align with stated goals?

**File/Path References:**
- Are the referenced files/paths from original request addressed?
- Did sprint work on the right parts of the codebase?

**Acceptance Criteria:**
- Do sprint deliverables satisfy the original acceptance criteria?
- Were new criteria added that weren't requested?

**Dependencies & Integrations:**
- Are original dependencies/integrations preserved?
- Were new dependencies added without user request?

## Required Output Format

```markdown
# Sprint Drift Analysis

**Severity:** [NONE|MINOR|MAJOR|UNKNOWN]

---

## Summary

(1-2 sentence summary of drift status)

---

## Original Request Analysis

### What User Actually Asked For

(Bullet list of core requirements from original-requirements.md)

- Requirement 1
- Requirement 2
- Requirement 3

### Referenced Files/Paths

(List of files/paths user mentioned)

- Path 1
- Path 2

### Key Constraints/Preferences

(Technical constraints, framework preferences, etc.)

- Constraint 1
- Constraint 2

---

## Sprint Implementation Analysis

### What Sprint Planned to Deliver

(Bullet list of sprint deliverables from sprint-plan.md)

- Deliverable 1
- Deliverable 2
- Deliverable 3

### Technical Approach

(Summary of technical approach taken)

---

## Drift Assessment

### ✅ Alignment (What Matched)

(List what the sprint got right)

- ✅ Item 1: (why this aligns)
- ✅ Item 2: (why this aligns)

### ⚠️  Deviations (What Drifted)

(List any deviations from original request)

**Added Features Not Requested:**
- Feature X: (was this justified?)
- Feature Y: (scope creep?)

**Missing Requirements:**
- Requirement A: (why missing?)
- Requirement B: (overlooked?)

**Technical Approach Changes:**
- Change 1: (deviation from user's stated approach)
- Change 2: (architectural difference)

**File/Path Misalignment:**
- (Did sprint work on different files than user specified?)

### 📊 Drift Score Breakdown

- **Scope Coverage:** [X/10] (10 = all requirements covered)
- **Feature Creep:** [X/10] (10 = no extra features, 0 = many extras)
- **Technical Alignment:** [X/10] (10 = matches user's approach)
- **File/Path Accuracy:** [X/10] (10 = correct files targeted)
- **Overall Alignment:** [X/10] (average of above)

---

## Recommendation

**SEVERITY: [NONE|MINOR|MAJOR|UNKNOWN]**

### If NONE:
Sprint accurately implements user's original request. Safe to proceed with merge.

### If MINOR:
Sprint covers original request but includes extra features or minor reorganization. Review additions to ensure they add value. Consider proceeding with merge if extras are beneficial.

### If MAJOR:
Sprint significantly diverged from user's intent. DO NOT merge. Recommend:
1. Review drift analysis with user
2. Create sub-sprint to realign implementation
3. Remove features not requested
4. Add missing requirements

### If UNKNOWN:
Cannot determine drift level. Manual review required before proceeding.

---

## Next Steps

(Specific actions based on severity level)
```

**OUTPUT ONLY THE DRIFT ANALYSIS MARKDOWN - NO OTHER TEXT**

---

## Input Data

**Sprint Folder:** [[SPRINT_FOLDER]]

The helper LLM should read:
1. `[[SPRINT_FOLDER]]plan/original-requirements.md` - Source of truth
2. `[[SPRINT_FOLDER]]sprint-plan.md` - Implementation plan
3. `[[SPRINT_FOLDER]]plan/plan.md` - Overall plan (if needed for context)

Compare deliverables against original user request and output drift analysis with severity classification.
