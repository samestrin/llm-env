# Task: Extract Documentation for Implementation Plan

You are extracting relevant content from a documentation resource for use in an implementation plan.

## Source Information

**Source Path:** [[SOURCE_PATH]]
**Source Type:** [[SOURCE_TYPE]]
**Resource Name:** [[RESOURCE_NAME]]

## Plan Context

**Goal:** [[PLAN_GOAL]]
**Scope:** [[PLAN_SCOPE]]
**Technical Approach:** [[TECHNICAL_APPROACH]]

## Instructions

Extract information useful for implementing the plan above. Be THOROUGH - include:
- Public API signatures, function names, and exports
- Configuration options and environment variables
- Code examples and usage patterns (include COMPLETE examples, not snippets)
- Architecture and design patterns relevant to the scope
- Database schemas or data models (full table definitions)
- API endpoint definitions (full request/response examples)
- Type definitions and interfaces
- Important constants and configuration values
- Error handling patterns
- Integration patterns with other components

**KEEP content even if you're unsure of relevance - better to include than omit.**

**OMIT only:**
- Purely marketing content
- License text
- Changelog entries older than 1 year
- Content in languages other than English (unless code)

## Required Output Format

```markdown
# [[RESOURCE_NAME]] - Extracted Content

**Source:** [[SOURCE_PATH]]
**Source Type:** [[SOURCE_TYPE]]
**Priority:** [Critical|Important|Reference] - explain WHY this priority
**When to Use:** [Setup|Development|Testing|All Phases]

## Summary
[2-3 sentences describing what this resource covers and why it matters for this plan]

## Why This Matters for the Plan
[1-2 sentences explaining specific relevance to [[PLAN_GOAL]]]

## Key Concepts
List 5-10 key concepts with brief explanations:
- **[concept name]**: [explanation of what it is and when to use it]
- **[concept name]**: [explanation]
...

## Code Examples

### Example 1: [descriptive title]
**Location in source:** [section name or "lines X-Y" if known]
```[language]
[COMPLETE working code example - not a snippet]
```
**When to use:** [explain the use case]

### Example 2: [descriptive title]
**Location in source:** [section name or line reference]
```[language]
[another complete example]
```
**When to use:** [explain]

[Include 3-5 code examples minimum]

## Usage Patterns
- **[Pattern Name]**: [detailed explanation of when and how to use]
- **[Pattern Name]**: [detailed explanation]
...

## Type Definitions (if applicable)
```[language]
[Include relevant interfaces, types, schemas]
```

## Database Schemas (if applicable)
**Location in source:** [where this schema is defined]
```sql
[Complete CREATE TABLE statements or schema definitions]
```

## API Endpoints (if applicable)
### [Endpoint Name]
- **Method:** [GET/POST/etc]
- **Path:** [/api/path]
- **Location in source:** [where defined]
- **Request:**
```json
[request body example]
```
- **Response:**
```json
[response body example]
```

## Configuration Options
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| [name] | [type] | [default] | [what it does] |

## Common Pitfalls
- [pitfall 1]: [how to avoid]
- [pitfall 2]: [how to avoid]

## Related Resources
- [other relevant docs/files mentioned in this resource]
```

**OUTPUT ONLY THE MARKDOWN FORMAT ABOVE - NO OTHER TEXT**
**Be THOROUGH - a 50-line extract from a 500-line doc is too thin. Aim for 30-50% of original relevant content.**

---

**Resource to Extract:**
[[RESOURCE_CONTENT]]
