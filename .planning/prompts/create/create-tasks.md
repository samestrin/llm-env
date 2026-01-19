# Tasks Generation Prompt

Use this prompt to generate detailed Technical Debt task files for a given plan directory so the plan delivers 100% of the original request.

## Context
You are an expert Technical Project Manager. Your goal is to create one task file per item in the plan, aligned exactly with the original request and enriched with links to relevant documentation and codebase discovery.

## Inputs
- Target plan directory (e.g., `.planning/plans/48.0_code_quality`)

## Instructions

1. Locate and read the following files inside the target directory:
   - `plan.md` – Detailed plan to implement
   - `original-requirements.md` – Source of truth for intent and requirements
   - `codebase-discovery.json` – Primary and related files, patterns, and recommendations
   - `documentation/*` – Backend, NPM tools, and testing patterns

2. Identify all work items in `plan.md` (the Technical Debt Inventory and Detailed Tasks). There should be one task file per item.

3. Create a `tasks/` directory under the target plan directory. For each item, create a file named:
   - `NN-<slug>.md` (two-digit, order as in plan; slug derived from item title)
   - Examples: `01-seo-services-relocation.md`, `02-content-sanitizer-dead-code-removal.md`

4. Use the Task File Template below for each task. Populate every section using information from `plan.md`, `original-requirements.md`, and `codebase-discovery.json`. Link to appropriate docs in `documentation/`.

5. Ensure each task includes:
   - Clear problem statement and solution overview
   - Concrete implementation steps and explicit file paths
   - Links to documentation and related files listed in `codebase-discovery.json`
   - Success criteria, test strategy, risk mitigation, dependencies, and definition of done

6. Verify coverage:
   - Every plan item has a corresponding task file
   - All steps from the original request are represented in tasks
   - Tasks reference `plan.md`, `original-requirements.md`, and `documentation` where relevant

7. Update `plan.md`:
   - Add a link to each individual task file in the task directory in the plan.md file under "## Tasks"

## Task File Template

```markdown
# Task NN: <Title>

**Source:** Plan <plan-number> – Debt Item #<N>
**Priority:** <P1/P2/P3> | **Effort:** <S/M/L> | **Type:** <Refactor/Remove/Upgrade>

## Problem Statement
<Summarize the problem from original-requirements.md>

## Solution Overview
<Summarize the solution approach from plan.md/original-requirements.md>

## Technical Implementation
### Steps
1. <Step 1 with exact file paths>
2. <Step 2>
3. <Step 3>

## Files to Create/Modify
- `path/to/file.ts` – <action>
- `path/to/another-file.ts` – <action>

## Documentation Links
- [Backend Development Patterns](../documentation/backend-development-patterns.md)
- [Testing Patterns](../documentation/testing-patterns.md)
- [NPM Tool Patterns](../documentation/npm-tool-patterns.md)

## Related Files (from codebase-discovery.json)
- `relative/path/from/codebase-discovery.json`
- `...`

## Success Criteria
- [ ] <Criteria 1>
- [ ] <Criteria 2>

## Manual Code Review
- [ ] Codebase has been reviewed - ( After completion, add code review notes here, or remove. )

## Test Strategy
**Unit Tests:**
- <Unit test cases>

**Integration Tests:**
- <Integration test cases>

**Test Files:**
- `app/tests/.../<file>.test.ts`

## Risk Mitigation
- <Risks and mitigations>

## Dependencies
- <Dependencies (e.g., TD-1 Activity Model)>

## Definition of Done
- <DoD checklist>
```

## Output
- Create `tasks/` with one file per plan item, named `NN-<slug>.md`, each fully populated using the template above and linked to valid documentation and linked to valid files from the codebase discovery.

