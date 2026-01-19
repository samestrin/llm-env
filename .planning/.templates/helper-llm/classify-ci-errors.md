# Pattern: CI Error Classification (Multi-Error)

Analyze CI failure logs and extract ALL distinct errors with classifications.

## Input

- CI_LOG: The full CI failure log output

## Output Format

First line: Summary counts by category
Subsequent lines: One error per line

```
SUMMARY: type=N,lint=N,test=N,build=N,dependency=N
ERROR|CATEGORY|CODE|FILE:LINE|PROBLEM|FIX
ERROR|CATEGORY|CODE|FILE:LINE|PROBLEM|FIX
...
```

Where:
- CATEGORY: lint, type, test, build, dependency, unknown
- CODE: Specific error code (TS2339, ESLint/no-unused-vars, etc.) or NONE
- FILE:LINE: Location if available, or NONE
- PROBLEM: Brief description (max 50 chars)
- FIX: Actionable fix suggestion (max 80 chars)

## Prompt

Analyze this CI log and extract ALL distinct errors.

Output format:
- Line 1: SUMMARY: type=N,lint=N,test=N,build=N,dependency=N
- Lines 2+: ERROR|CATEGORY|CODE|FILE:LINE|PROBLEM|FIX

Rules:
- One ERROR line per distinct error (max 15)
- Categories: lint, type, test, build, dependency, unknown
- Include error code if present (TS2339, E0502, etc.)
- Keep PROBLEM under 50 chars, FIX under 80 chars
- If same error repeats in multiple files, list each file separately

CI Log:
[[CI_LOG]]

## Example

**Input:**
```
src/UserProfile.tsx:45 - error TS2339: Property 'email' does not exist
src/api.ts:112 - error TS2322: Type 'string' is not assignable to number
src/utils.ts:8:1 - error: 'unused' is defined but never used (no-unused-vars)
```

**Output:**
```
SUMMARY: type=2,lint=1,test=0,build=0,dependency=0
ERROR|type|TS2339|src/UserProfile.tsx:45|Property 'email' missing on type|Add email field to interface or use optional chaining
ERROR|type|TS2322|src/api.ts:112|String assigned to number type|Use parseInt() or fix return type
ERROR|lint|no-unused-vars|src/utils.ts:8|Unused variable 'unused'|Remove variable or add underscore prefix
```
