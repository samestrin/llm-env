# Extract Plan Metadata Task

Extract metadata from plan files and output as shell variable assignments.

## Task

Read the following files and extract simple metadata as shell variable assignments:

1. [[PLAN_PATH]]original-requirements.md
2. [[PLAN_PATH]]sprint-design.md

## Required Fields

Extract these fields as KEY="VALUE" pairs (one per line):

**From original-requirements.md:**
- ORIGINAL_USER_INPUT (first paragraph only, escape quotes)
- ORIGINAL_TARGET (referenced files/paths)

**From sprint-design.md:**
- SPRINT_NAME
- COMPLEXITY_SCORE (number only, e.g., 8)
- COMPLEXITY_LEVEL (SIMPLE|MODERATE|COMPLEX|VERY COMPLEX)
- PHASE_COUNT (number only)
- PHASE_PATTERN (pattern name)
- TOTAL_DAYS (number only)

## Required Output Format

Output ONLY shell variable assignments, properly quoted:

```
ORIGINAL_USER_INPUT="value"
ORIGINAL_TARGET="value"
SPRINT_NAME="value"
COMPLEXITY_SCORE="8"
COMPLEXITY_LEVEL="MODERATE"
PHASE_COUNT="4"
PHASE_PATTERN="pattern name"
TOTAL_DAYS="7"
```

**IMPORTANT:**
- Escape any quotes in values with backslash
- Output ONLY the variable assignments above
- NO other text or commentary
