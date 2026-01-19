# Task: Categorize Documentation Resources

Analyze the extracted documentation summaries and group them into logical categories.

## Plan Context

**Goal:** [[PLAN_GOAL]]
**Technical Approach:** [[TECHNICAL_APPROACH]]

## Extracted Documentation Summaries

[[EXTRACT_SUMMARIES]]

## Instructions

Group the documentation into 3-6 logical categories based on:
- Framework/Library Patterns
- Design Patterns
- API References
- Database/Data Models
- Testing Guidelines
- Code Conventions
- Deployment/Operations

## Required Output Format

For each category, output EXACTLY this format:

```
CATEGORY: [category-name-kebab-case]
TITLE: [Human Readable Title]
DESCRIPTION: [1 sentence description]
PRIORITY: [Critical|Important|Reference]
RESOURCES: [comma-separated list of resource filenames from extracts]
---
```

**Example:**

```
CATEGORY: wasp-patterns
TITLE: Wasp Framework Patterns
DESCRIPTION: Core patterns and conventions for building Wasp applications
PRIORITY: Critical
RESOURCES: wasp-docs.md, wasp-tutorial.md
---
CATEGORY: api-design
TITLE: API Design Guidelines
DESCRIPTION: REST API conventions and endpoint design patterns
PRIORITY: Important
RESOURCES: api-reference.md, openapi-spec.md
---
```

**OUTPUT ONLY THE CATEGORIES IN THE FORMAT ABOVE - NO OTHER TEXT**
