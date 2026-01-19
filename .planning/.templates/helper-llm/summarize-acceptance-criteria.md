# Acceptance Criteria Summary Task

Analyze acceptance criteria files and create a concise summary organized by user story.

## Task

Read all acceptance criteria files and generate a brief overview of what acceptance criteria were created.

## Required Output Format

```markdown
## Acceptance Criteria Summary

**Total Acceptance Criteria**: [number]

**Acceptance Criteria by User Story**:

### [Story Title]
- [AC 1]: [Brief description]
- [AC 2]: [Brief description]
[... for all AC in this story]

### [Story Title]
- [AC 1]: [Brief description]
- [AC 2]: [Brief description]
[... for all AC in this story]

[... for all stories]

**Coverage**: [1-2 sentences describing overall test coverage and focus areas]
```

**OUTPUT ONLY THE MARKDOWN ABOVE - NO OTHER TEXT**

---

## Input Data

**Acceptance Criteria Files Directory**: [[PLAN_PATH]]acceptance-criteria/

Please read all .md files in that directory and summarize them by user story.
