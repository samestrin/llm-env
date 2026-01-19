# Extract Sprint Learnings

Analyze the implementation from this sprint to identify implicit decisions, patterns, and conventions worth capturing as project memories.

## Sprint Context

**Sprint Name:** [[SPRINT_NAME]]
**Sprint Plan Summary:** [[SPRINT_CONTEXT]]

## Implementation Changes

**Git Diff Summary:**
```
[[IMPLEMENTATION_DIFF]]
```

## Extraction Rules

Identify learnings that are:
1. **Architectural decisions** - Why code is structured a certain way
2. **Pattern choices** - Consistent patterns used across files
3. **Integration approaches** - How components connect
4. **Debugging insights** - Solutions to non-obvious problems
5. **Convention discoveries** - Project-specific naming or organization

**Quality Criteria:**
- Must be SPECIFIC to this codebase (not generic programming advice)
- Must have CONCRETE examples from the diff
- Must answer "why" not just "what"
- Must be useful for future work on this project

**DO NOT include:**
- Generic programming best practices everyone knows
- Formatting or style changes
- Obvious implementation details
- Anything you're uncertain about (confidence < 0.7)

## Output Format

Output ONLY valid pipe-delimited rows, one per line.
Maximum 10 learnings.
Minimum confidence threshold: 0.7

**Format (one entry per line):**
```
QUESTION|ANSWER|FILES|TAGS|CONFIDENCE
```

**Field rules:**
- QUESTION: What decision was made? (phrased as question, max 150 chars)
- ANSWER: The pattern/decision and WHY it was chosen (max 400 chars)
- FILES: Comma-separated file paths where pattern appears
- TAGS: Comma-separated relevant domain tags
- CONFIDENCE: 0.0-1.0 score (only output if >= 0.7)

**Example output:**
```
How should error handling work in API routes?|All API route errors are caught by middleware and wrapped with traceIds for debugging. This pattern centralizes error formatting and ensures consistent client responses.|src/api/middleware/error.ts,src/api/routes/users.ts|error-handling,api,middleware|0.85
Why use a factory pattern for database connections?|Database connections use a factory to support both Postgres (production) and SQLite (tests) without code changes. The factory reads from env config.|src/db/factory.ts,src/db/postgres.ts|database,testing,factory-pattern|0.9
```

## Constraints

- Only extract HIGH CONFIDENCE patterns (confidence >= 0.7)
- Skip cosmetic changes (formatting, whitespace, comments)
- Skip patterns that only appear once (not established)
- Skip generic advice that isn't specific to this codebase
- If no high-confidence patterns found, output: `NO_HIGH_CONFIDENCE_PATTERNS|analysis complete`

## Extract Now

Analyze the implementation changes above and output ONLY the pipe-delimited learning entries (or NO_HIGH_CONFIDENCE_PATTERNS).
