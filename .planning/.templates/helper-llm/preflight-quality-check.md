# Pattern: Pre-flight Quality Gate

## Input
- ARTIFACT_CONTENT: The full sprint plan, implementation plan, or other artifact to validate
- ARTIFACT_TYPE: Type of artifact (sprint-plan, implementation-plan, user-story, etc.)

## Output Format
```
SCORE|PASS_OR_BLOCK|BLOCKERS_OR_NONE
```

Where:
- SCORE: 1-10 quality score
- PASS_OR_BLOCK: "PASS" if score >= 6, "BLOCK" if score < 6
- BLOCKERS_OR_NONE: Comma-separated list of issues, or "NONE"

## Prompt

Quick sanity check: Does this [[ARTIFACT_TYPE]] look implementable?

Score 1-10 based on:
- Clarity: Are requirements unambiguous?
- Completeness: Are all necessary details present?
- Feasibility: Can this realistically be built?
- Testability: Can success be verified?

Output format: SCORE|PASS_OR_BLOCK|BLOCKERS_OR_NONE

Rules:
- PASS if score >= 6
- BLOCK if score < 6
- List up to 3 most critical blockers (or NONE)

Artifact:
[[ARTIFACT_CONTENT]]

## Example

Input:
```
ARTIFACT_TYPE: sprint-plan

# Sprint: Add User Authentication

## Scope
- Login form
- Password reset
- Session management

## User Stories
1. As a user, I can log in with email/password
2. As a user, I can reset my forgotten password

## Tasks
- Create login component
- Implement JWT token handling
- Add password reset flow
```

Output:
```
7|PASS|NONE
```

Input (problematic):
```
ARTIFACT_TYPE: sprint-plan

# Sprint: Refactor Everything

## Scope
- Make code better
- Improve performance

## Tasks
- Refactor stuff
```

Output:
```
2|BLOCK|No specific requirements defined,Tasks too vague to estimate,No success criteria or tests mentioned
```
