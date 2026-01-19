# Extract Q&A from Documentation

Extract question-answer pairs from the provided documentation content that represent project decisions, clarifications, or important knowledge.

## Input

**Source File:** [[SOURCE_FILE]]
**Content:**

```
[[CONTENT]]
```

## Extraction Rules

Look for these Q&A patterns:

1. **Explicit Q&A markers:** `Q:` / `A:`, `Question:` / `Answer:`
2. **Decision sections:** Headers like "## Decisions", "### Decision", "## Why", "### Rationale"
3. **FAQ sections:** "## FAQ", "### Frequently Asked Questions"
4. **Implicit decisions:** Statements explaining "we chose X because Y" or "this uses X instead of Y because"

## Output Format

Output ONLY valid pipe-delimited rows, one per line.
Maximum 10 entries.

**Format (one entry per line):**
```
QUESTION|ANSWER|TAGS
```

**Field rules:**
- QUESTION: The question or decision point (max 200 chars)
- ANSWER: The answer or decision made (max 500 chars)
- TAGS: Comma-separated relevant tags (e.g., "architecture,api,auth")

**Example output:**
```
Why use TypeScript over JavaScript?|TypeScript provides compile-time type checking which reduces runtime errors and improves developer experience with better IDE support.|typescript,architecture,language-choice
What authentication method should we use?|JWT tokens with refresh rotation for stateless authentication that scales horizontally.|auth,security,api
```

## Constraints

- Only extract ACTUAL decisions or Q&A content, not documentation descriptions
- Skip table of contents, navigation links, or metadata headers
- Skip content that is instructional rather than decisional
- If no Q&A content found, output: `NO_QA_CONTENT_FOUND`

## Extract Now

Analyze the content above and output ONLY the pipe-delimited Q&A entries (or NO_QA_CONTENT_FOUND).
