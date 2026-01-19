# Sprint Overview Generation Task

Convert the original user request into a concise, sprint-oriented overview for implementation.

## Task

Create a 2-3 paragraph sprint overview that:
1. Summarizes what we're building (from user perspective)
2. Explains why (user's problem/need)
3. Describes key deliverables
4. States success criteria

## Required Output Format

```markdown
## Sprint Overview

**Metadata:** See [metadata.md](metadata.md) for complete plan and sprint tracking details.

**Original Request:** [Full details in plan/original-requirements.md](plan/original-requirements.md)

### What We're Building

[2-3 sentences: What is being implemented, from the user's perspective]

### Why This Matters

[1-2 sentences: The problem this solves or value it provides]

### Key Deliverables

- [Deliverable 1 from user stories/acceptance criteria]
- [Deliverable 2]
- [Deliverable 3]
- [etc]

### Success Criteria

- [How we know this sprint succeeded - from acceptance criteria]
- [Measurable outcomes]

**CRITICAL REMINDER:** Every task in this sprint must contribute to fulfilling the original request. If a task seems unrelated to what the user actually asked for, STOP and validate before proceeding. Do not add scope beyond the original request.
```

**OUTPUT ONLY THE MARKDOWN ABOVE - NO OTHER TEXT**

---

## Input Data

**Original User Input:**
[[ORIGINAL_USER_INPUT]]

**Referenced Resources:**
[[ORIGINAL_TARGET]]

**User Stories Count:** [[TOTAL_STORIES]]

**Acceptance Criteria Pattern:** See [[PLAN_PATH]]acceptance-criteria/ directory
