# Task: Generate Category Documentation File

Generate a COMPLETE, THOROUGH documentation file for the category below.

## Category Details

**Category:** [[CATEGORY_TITLE]]
**Description:** [[CATEGORY_DESCRIPTION]]
**Priority:** [[CATEGORY_PRIORITY]] [[CATEGORY_PRIORITY_BADGE]]
**Plan Path:** [[PLAN_PATH]]
**Date:** [[TODAYS_DATE]]

## Extracted Content for This Category

[[CATEGORY_EXTRACTS]]

## CRITICAL INSTRUCTIONS

You MUST generate a comprehensive documentation file. A typical output should be 150-400 lines.

### Relative Path Calculation

Calculate relative paths FROM `[[PLAN_PATH]]documentation/` TO source files:

**Examples:**
- Source: `src/utils/auth.ts` → Relative: `../../src/utils/auth.ts`
- Source: `[[PLAN_PATH]]plan.md` → Relative: `../plan.md`
- Source: `https://docs.example.com/api` → Keep as URL: `https://docs.example.com/api`
- Source: `lib/database/schema.sql` → Relative: `../../lib/database/schema.sql`

**Pattern:** Count directories from `[[PLAN_PATH]]documentation/` back to repo root, then add source path.
- `[[PLAN_PATH]]documentation/` is typically 3-4 levels deep (e.g., `.planning/plans/1.0_feature/documentation/`)
- To reach repo root: `../../../..` (4 levels up from documentation/)
- Then append source path: `../../../../src/utils/auth.ts`

### Required Output Format

```markdown
# [[CATEGORY_TITLE]]

[[CATEGORY_DESCRIPTION]]

**Created:** [[TODAYS_DATE]]
**Plan:** [../plan.md](../plan.md)
**Priority:** [[CATEGORY_PRIORITY]] [[CATEGORY_PRIORITY_BADGE]]

---

## References

### [[CATEGORY_PRIORITY_BADGE]] 1. [First Reference Title from Extract]

**📄 Source:** [`[calculated-relative-path]`]([calculated-relative-path])
**Priority:** [[CATEGORY_PRIORITY]] - [reason why this priority]
**When to use:** [Setup|Development|Testing|All Phases]

**Summary:**
[2-3 sentences from extract's Summary section]

**Why it's useful:**
[From extract's "Why This Matters" section - explain specific relevance]

**Key sections to focus on:**
- [Section name from source] - [why important]
- [Another section] - [why important]

**Key Concepts:**
- **[Concept from extract]**: [explanation]
- **[Another concept]**: [explanation]
- **[Third concept]**: [explanation]

**Examples:**

[Copy the code examples from the extract - include ALL of them]

**Code snippets:**
```[language]
[ACTUAL CODE from the extract - not placeholder text]
```

**Usage patterns:**
- **[Pattern name]**: [detailed explanation from extract]
- **[Another pattern]**: [explanation]

[IF extract has Database Schemas section:]
**Database schema example:**
```sql
[ACTUAL SQL from extract]
```

[IF extract has API Endpoints section:]
**API endpoint example:**
```
[METHOD] [PATH]
[Request/response from extract]
```

**Source Location:**
- **File:** `[relative-path-to-source]`
- **Section:** [section name from extract]
- **Lines:** [line numbers if available, otherwise "Full document"]

---

### [[CATEGORY_PRIORITY_BADGE]] 2. [Second Reference Title]

[Repeat the same detailed structure for each reference in this category]

---

## Quick Reference

| Concept | Description | Example |
|---------|-------------|---------|
| [key concept 1] | [brief description] | `[code example]` |
| [key concept 2] | [brief description] | `[code example]` |
| [key concept 3] | [brief description] | `[code example]` |

**Common Commands/Patterns:**
```[language]
// [Pattern 1 name]
[actual code]

// [Pattern 2 name]
[actual code]
```

---

**Navigation:**
- [← Back to Documentation Index](README.md)
- [Plan Document](../plan.md)
```

### Quality Checklist

Before outputting, verify:
- [ ] Every [[PLACEHOLDER]] has been replaced with actual content
- [ ] All code examples are REAL code from extracts (not `[placeholder]` text)
- [ ] Relative paths are correctly calculated
- [ ] Each reference has Summary, Key Concepts, Code Examples, Usage Patterns
- [ ] Quick Reference table has actual content
- [ ] Output is 150+ lines (thin output = failure)

**OUTPUT THE COMPLETE DOCUMENTATION FILE - NO OTHER TEXT**
