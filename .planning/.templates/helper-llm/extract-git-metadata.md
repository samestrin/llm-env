# Metadata Extraction Task

Extract structured metadata from sprint execution logs.

## Task
Analyze the git log and test results to extract:
- Total commits in sprint
- Test files added/modified
- Documentation files updated
- Configuration changes
- Key implementation files

## Required Output Format
```markdown
## Commits
- Total: N
- First: [hash] [message]
- Last: [hash] [message]

## Test Coverage
- Test files: N
- Test commands found: [yes/no]

## Documentation
- Files updated: N
- README changes: [yes/no]

## Implementation
- Source files: N
- Config files: N
```

**OUTPUT ONLY THE METADATA STRUCTURE - NO OTHER TEXT**

---

## Input Data

{{GIT_LOG}}

{{TEST_RESULTS}}
