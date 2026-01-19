# Diff to English

Transform a git diff into human-readable change descriptions for PR bodies.

## Input

Git diff output (unified format).

## Output Format

Bullet list of changes, one per significant modification:
```
- Added authentication middleware to protect API routes
- Fixed null check in user service that caused crashes
- Updated error messages to be more descriptive
```

## Guidelines

- Focus on WHAT changed, not HOW (avoid line-by-line descriptions)
- Group related changes into single bullets
- Use past tense ("Added", "Fixed", "Updated", "Removed")
- Keep each bullet to one sentence
- Prioritize user-facing and behavioral changes
- Skip trivial changes (whitespace, formatting only)
- Maximum 7 bullets (summarize if more changes)

## Prompt

Summarize these code changes in plain English for a PR description:

```diff
[[GIT_DIFF]]
```

**Output ONLY the bullet list, no preamble:**
