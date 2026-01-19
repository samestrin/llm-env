# Extract Technologies Task

Extract technology names from a plan that need external documentation.

## Input

**Plan Goal:** [[PLAN_GOAL]]

**Key Features:** [[KEY_FEATURES]]

**Technologies Mentioned:** [[TECHNOLOGIES]]

**Missing Packages:** [[MISSING_PACKAGES]]

## Task

Identify technologies, libraries, frameworks, and tools from the input that would benefit from external documentation.

Focus on:
1. Any items in MISSING_PACKAGES (highest priority)
2. Technologies mentioned that aren't standard language features
3. Frameworks and libraries with complex APIs
4. Tools or services that require configuration

Exclude:
- Standard language features (e.g., "JavaScript arrays", "Python dicts")
- Basic programming concepts
- Internal/custom modules (no public docs available)

## Required Output Format

Output ONLY technology names, one per line:

```
zod
drizzle-orm
tanstack-query
openai-sdk
```

**IMPORTANT:**
- Output ONLY the technology names
- One name per line, lowercase
- NO explanations, NO numbers, NO bullets
- Maximum 10 technologies
- Use the canonical package/library name
