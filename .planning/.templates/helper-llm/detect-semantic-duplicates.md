# Pattern: Semantic Duplication Detection

Find semantically similar items in a numbered list for grouping or deduplication.

## Input

- NUMBERED_LIST: Items numbered 1, 2, 3, etc. (one per line)

## Output Format

```
GROUP1: <comma-separated item numbers> | GROUP2: <numbers> | ... | UNIQUE: <numbers>
```

Rules:
- Group items that are semantically similar (same underlying issue/concept)
- Items in a group should be related enough to be addressed together
- UNIQUE contains items that don't match any other item
- Minimum 2 items needed to form a group
- Order groups by size (largest first)

## Prompt

Find semantically similar items in this numbered list. Group items that describe the same underlying issue or concept.

Output format: GROUP1: 1,3,5 | GROUP2: 2,4 | UNIQUE: 6,7,8

Rules:
- Only group items that are genuinely related (same root cause, same area)
- Items in UNIQUE don't match any other item semantically
- Minimum 2 items to form a group
- Order groups largest first
- Output ONLY the grouping line, no explanations

Numbered List:
[[NUMBERED_LIST]]

## Example

**Input:**
```
1. TODO: Add input validation to user registration
2. FIXME: Memory leak in WebSocket handler
3. TODO: Validate email format before submission
4. TODO: Add null check to payment processing
5. FIXME: Connection pool exhaustion under load
6. TODO: Sanitize user input in search field
7. HACK: Temporary workaround for timezone bug
8. TODO: Add CSRF token validation
9. FIXME: Resource leak in file upload handler
10. TODO: Validate phone number format
```

**Output:**
```
GROUP1: 1,3,6,10 | GROUP2: 2,5,9 | UNIQUE: 4,7,8
```

**Explanation (not in output):**
- GROUP1: All input validation related (registration, email, search, phone)
- GROUP2: All resource/memory leak related (WebSocket, connection pool, file upload)
- UNIQUE: Null check, timezone hack, and CSRF are distinct issues
