# File Compression Task

Analyze the original user request file and create an intelligent compressed version.

## Compression Requirements

### 1. Preserve Exactly (DO NOT compress):
- All file paths and directory references
- All technical constraints and requirements
- All acceptance criteria
- All dependencies and integrations mentioned
- All error messages and edge cases
- All database schema details
- Technology stack and framework versions

### 2. Compress with Cross-References:
- Long code examples → summarize with "See uncompressed lines X-Y for full code"
- Verbose explanations → condense to key points with line references
- Repetitive sections → deduplicate with cross-references
- Long test examples → summarize approach with line references

### 3. Remove Entirely:
- Marketing fluff and unnecessary background
- Redundant explanations of the same concept
- Overly verbose introductions

## Required Output Format

```markdown
# Original Request (Compressed)

**Submitted:** [[DATE]]
**Original Size:** [[FILE_LINES]] lines
**Compression:** Intelligent summary via helper LLM
**Full Version:** [original-requirements-uncompressed.md](original-requirements-uncompressed.md)

## User Input

[EXACT USER REQUEST - NEVER PARAPHRASE]

## Referenced Files/Paths

[LIST ALL FILE PATHS EXACTLY]

## Key Requirements

[BULLET LIST - ALL MUST-HAVES]

## Technical Constraints

[ALL CONSTRAINTS PRESERVED]

## Acceptance Criteria

[ALL CRITERIA PRESERVED]

## Dependencies & Integrations

[ALL DEPENDENCIES PRESERVED]

## Important Sections with Cross-References

[COMPRESSED CONTENT WITH LINE REFERENCES TO UNCOMPRESSED VERSION]

---

**Purpose:** Compressed version to prevent context overflow while preserving all critical information.

**When to use full version:** Reference [original-requirements-uncompressed.md](original-requirements-uncompressed.md) for:
- Complete code examples (see line references above)
- Detailed test cases
- Full error message listings
- Extended explanations

**Usage:** All planning phases use this compressed version to stay grounded in user intent without overwhelming context.
```

**OUTPUT ONLY THE COMPRESSED MARKDOWN - NO OTHER TEXT**

---

## Input Data

**Source File to Compress:**

[[FILE_CONTENT]]
