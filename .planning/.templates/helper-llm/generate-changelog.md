# Pattern: Changelog Generation

Generate grouped changelog from git commits.

## Input

- COMMITS: Git commit log output (from `git log --oneline` or similar)
- VERSION: Optional version number for the header

## Output Format

Markdown changelog grouped by category:

```markdown
## [VERSION] - YYYY-MM-DD

### Added
- New feature descriptions

### Changed
- Modified behavior descriptions

### Fixed
- Bug fix descriptions

### Removed
- Removed feature descriptions
```

## Prompt

Generate a changelog from these git commits. Group by: Added, Changed, Fixed, Removed.

Rules:
- Use past tense
- One bullet point per significant change
- Omit merge commits and version bumps
- Combine related commits into single entries
- Focus on user-facing changes, not internal refactors
- Keep descriptions concise (one line each)
- If a category has no entries, omit it entirely

Commits:
[[COMMITS]]

## Example

**Input:**
```
abc1234 Add user authentication flow
def5678 Fix memory leak in image loader
ghi9012 Update dashboard styling
jkl3456 Remove deprecated API v1 endpoints
mno7890 Add rate limiting to API
pqr1234 Fix typo in error message
```

**Output:**
```markdown
### Added
- User authentication flow
- Rate limiting to API endpoints

### Changed
- Dashboard styling updates

### Fixed
- Memory leak in image loader
- Typo in error message

### Removed
- Deprecated API v1 endpoints
```
