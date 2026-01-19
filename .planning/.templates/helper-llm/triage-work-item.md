# Triage Work Item

Quick assessment of a work item (user story or task) to determine if it needs detailed Claude review or can be processed with high confidence.

## Input

Work item content (user story or task markdown).

## Output Format

```
COMPLEXITY|CONFIDENCE|FLAGS
```

Where:
- COMPLEXITY: `simple` | `moderate` | `complex`
- CONFIDENCE: 0.0-1.0 (how confident in this assessment)
- FLAGS: comma-separated list or `none`

## Flag Types

- `unclear_requirements` - Ambiguous acceptance criteria
- `multi_file` - Likely touches 3+ files
- `architectural` - May require design decisions
- `external_deps` - Involves external services/APIs
- `security` - Security-sensitive changes
- `performance` - Performance-critical code
- `none` - No special flags

## Classification Rules

**simple** (confidence >= 0.8):
- Single file change
- Clear, specific requirements
- No flags or only `multi_file`

**moderate** (confidence 0.5-0.8):
- 2-3 files
- Some interpretation needed
- 1-2 non-critical flags

**complex** (confidence < 0.5):
- Multiple files with dependencies
- Architectural decisions needed
- Security or performance concerns
- Unclear requirements

## Examples

Input: "Add a 'createdAt' timestamp field to the User model"
Output: `simple|0.9|none`

Input: "Implement OAuth2 login with Google and GitHub providers"
Output: `complex|0.4|multi_file,external_deps,security`

Input: "Fix typo in error message for login failure"
Output: `simple|0.95|none`

Input: "Refactor the database connection pool for better performance"
Output: `complex|0.3|architectural,performance`

## Prompt

Assess this work item for complexity and review needs:

```
[[WORK_ITEM]]
```

**Output ONLY the single line in format:** `COMPLEXITY|CONFIDENCE|FLAGS`
