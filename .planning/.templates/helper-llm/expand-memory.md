# Memory Expansion Task

Expand a simple Q&A into a rich, searchable memory entry.

## Input

**Question:** [[QUESTION]]
**Answer:** [[ANSWER]]
**Sprint Context:** [[SPRINT_ID]]
**Files Being Worked On:** [[FILES_LIST]]
**Tags (if any):** [[TAGS]]

## Instructions

Transform the Q&A into a structured memory entry. Your output will be embedded for semantic search, so include relevant context that would help find this memory later.

1. **Canonical Question**: Rephrase the question to be general and reusable (not tied to specific sprint)
2. **Brief Title**: 3-5 word title for the decision
3. **Decision**: The actual answer, possibly expanded with specifics
4. **Rationale**: Why this decision was made (infer from context if not explicit)
5. **Applies When**: Bullet list of conditions when this applies
6. **Code Reference**: If the answer mentions code patterns, include a brief example

## Required Output Format

Output ONLY the following YAML+Markdown structure (no explanation):

```
CANONICAL_QUESTION: [rephrased general question]
BRIEF_TITLE: [3-5 word title]
TAGS: [comma-separated relevant tags]
---
## Decision

[expanded answer text]

## Rationale

- [reason 1]
- [reason 2]

## Applies When

- [condition 1]
- [condition 2]

## Code Reference

[code example if relevant, otherwise "N/A"]
```
