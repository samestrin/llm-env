# Create Documentation Files Prompt

Use this prompt to generate a comprehensive documentation package for a sprint plan based on the specifications identified in `documentation/source.md`.

## Context
You are a Technical Documentation Specialist. Your goal is to create a focused, sprint-specific documentation library that gives developers exactly what they need to implement the plan. You will convert the list of specifications in `source.md` into individual reference files that extract the *most relevant* parts of the parent specifications, saving developers from reading the entire library.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/XX.X_plan_name`).

## Workflow

### 1. Load Context
Read the following files to understand the sprint requirements:
1.  `{plan_dir}/original-requirements.md`
2.  `{plan_dir}/plan.md`
3.  `{plan_dir}/documentation/source.md` (This optional file may exist. If it does, it contains the list of target specifications)

### 2. Process Specifications
For each specification listed in `documentation/source.md`:
1.  **Read** the source specification file.
2.  **Analyze** the `plan.md` to understand *which parts* of this specification are actually needed for this sprint.
3.  **Extract** the relevant sections (Summary, Key Concepts, Code Examples, specific guidelines - Include line number ranges).
4.  **Create** a new file in `{plan_dir}/documentation/{spec-filename}.md`.
5.  **Format** using the **Documentation File Template** below.

### 3. Analysis and Logical Grouping
Review all the files in `documentation/*.md` (excluding README.md and source.md). Can they be grouped into logical categories based on their content so that we don't have so man small files? Will that provide an improved documentation experience for the developer? If **YES**, combine the documentation into new files and remove any files that are no longer needed.

### 4. Create Index
After processing all specifications, create `{plan_dir}/documentation/README.md` using the **Index Template** below.

---

## Templates

### 1. Documentation File Template
**Filename:** Derived from the spec filename (e.g., `api-rate-limiting.md`)

```markdown
# {Specification Title}

**Source:** [{Original Filename}]({Relative Path to Original Spec})
**Priority:** {Critical/Important/Reference - infer from source.md or plan context}
**Relevance:** {Copy "Relevance" text from source.md}

---

## Context for Sprint
{Brief explanation of how this spec applies to the specific tasks in plan.md. e.g. "This sprint requires implementing the Sentry initialization pattern described in the 'Configuration' section below."}

## Relevant Patterns & Guidelines
{Extract the specific sections from the parent spec that are needed for this sprint. Do not copy the entire file if large sections are irrelevant. Keep code examples.}

### {Section Title from Spec}
{Content...}

---

## Navigation
- [← Back to Documentation Index](README.md)
- [Plan Document](../plan.md)
```

### 2. Index Template (README.md)
**Filename:** `README.md`

```markdown
# Plan Documentation References

This directory contains organized references to external documentation relevant to this implementation plan.

**Created:** {Current Date}
**Plan:** [../plan.md](../plan.md)

---

## Purpose
This documentation index helps developers quickly discover relevant patterns and specifications for this sprint without searching the entire specification library.

---

## Priority Legend

- 🔴 **Critical** - Must read before starting implementation
- 🟡 **Important** - Should review during development
- 🟢 **Reference** - Consult as needed for specific questions

---

## Documentation Files

### [{priority_icon}] {Spec Title} ({Priority})

**File:** [{filename}.md]({filename}.md)
**Priority:** {priority_icon} {Priority}
**Relevance:** {Relevance text from source.md}

**Contains:**
- {Key concept 1}
- {Key concept 2}
- {Code example mentioned}

---
{Repeat for each file, ordered by priority}

## How to Use

1. **Browse by Category**: Open the relevant documentation file for your task
2. **Review Examples**: Each reference includes practical examples and code snippets
3. **Follow Links**: Click through to full documentation for detailed information
4. **Apply Patterns**: Use the examples as templates for implementation

---

**Navigation:**
- [← Back to Plan](../README.md)
- [Plan Document](../plan.md)
```

## Rules
*   **Extraction Focus**: If a specification is 500 lines long but the sprint only needs the "Error Handling" section, only extract that section.
*   **Link Validity**: Ensure the "Source" link in the individual files points correctly to the original specification in `.planning/specifications/...`. You will need to calculate the relative path from `{plan_dir}/documentation/`.
*   **Priority Logic**:
    *   If `source.md` does not specify priority, assume:
    *   **Critical (🔴)**: Security, Core Architecture, Database Schema changes.
    *   **Important (🟡)**: UI Components, API patterns, Workflows.
    *   **Reference (🟢)**: Style guides, General patterns.

## Command
/create-docs @{plan_dir}
