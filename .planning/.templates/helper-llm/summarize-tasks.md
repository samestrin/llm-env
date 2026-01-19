# Tasks Summary Task

Analyze task files and create a concise summary.

## Task

Read all task files and generate a brief overview of what tasks were created.

## Required Output Format

```markdown
## Tasks Summary

**Total Tasks**: [number]

**Tasks Created**:
- **[Task Title]** (P[1-3], [S/M/L]): [One sentence describing the task's scope/goal]
- **[Task Title]** (P[1-3], [S/M/L]): [One sentence describing the task's scope/goal]
- **[Task Title]** (P[1-3], [S/M/L]): [One sentence describing the task's scope/goal]
[... for all tasks]

**Priority Distribution**: [P1: N, P2: N, P3: N]

**Effort Distribution**: [S: N, M: N, L: N]

**Coverage**: [1-2 sentences describing overall scope and focus areas covered]
```

**OUTPUT ONLY THE MARKDOWN ABOVE - NO OTHER TEXT**

---

## Input Data

**Task Files Directory**: [[PLAN_PATH]]tasks/

Please read all .md files in that directory and summarize them.
