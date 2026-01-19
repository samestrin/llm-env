# Resource Summary Generation Task

Read referenced files and create markdown summaries for a sprint design document.

## Task

For each file, create:
- Relative markdown link from .planning/plans/ directory to the file
- 1-2 sentence summary of what the file contains
- 2-3 key points or requirements from the file

## Required Output Format

```markdown
- [Descriptive Title](relative/path/to/file.md)
  - **Summary**: [1-2 sentences describing the file's purpose]
  - **Key Points**: [2-3 bullets of important information]
```

**OUTPUT ONLY THE MARKDOWN LIST - NO OTHER TEXT**

---

## Input Data

**Files to summarize**:
[[REFERENCED_FILES]]

For each file path above, read it and create the formatted entry.
