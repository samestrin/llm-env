# Refine Sprint Plan Prompt

Use this prompt to validate, enrich, and refine the detailed `sprint-plan.md` against the user's original request, architectural design, and available planning artifacts. This ensures strict alignment, correct structure, deep context awareness, and complete coverage before execution begins.

## Context
You are a Quality Assurance Lead and Technical Product Manager. Your goal is to ensure the execution plan (`sprint-plan.md`) is a faithful, actionable, and verifiable translation of the user's requirements (`plan/original-requirements.md`) and technical design (`plan/sprint-design.md`). You must verify that every requirement has a corresponding execution step, that technical context is leveraged, and that the plan follows strict project structure.

## Inputs
You will be provided with the path to a sprint directory (e.g., `.planning/sprints/planned/XX.X_sprint_name`).

## Instructions

### 1. Gather & Analyze
Read the following files in the sprint directory:
1.  `plan/original-requirements.md` (The Business Source of Truth)
2.  `sprint-plan.md` (The Execution Plan Draft)
3.  `plan/sprint-design.md` (The Technical Source of Truth - **CRITICAL**)
4.  `plan/user-stories/*.md` OR `plan/tasks/*.md` (The Detailed Definitions)
5.  `plan/documentation/*.md` (Context & Patterns)
6.  `plan/codebase-discovery.json` (Existing Code Context)

### 2. Validate & Optimize
Perform the following checks and optimizations:

*   **Architectural Alignment**:
    *   Compare `sprint-plan.md` against `plan/sprint-design.md` (if it exists).
    *   Ensure the plan implements the *specific* components, functions, and data structures defined in the design.
    *   *Fix*: Update generic steps (e.g., "Create component") to specific ones (e.g., "Create `VoiceScoreChart.tsx` as defined in Design").

*   **Linkage Integrity**:
    *   Ensure **EVERY** checkbox step explicitly links to its defining User Story, Task, or Acceptance Criteria file.
    *   Example: `- [ ] Implement [Task-1](plan/tasks/01-core-logic.md)` or `- [ ] Verify [AC-1](plan/acceptance-criteria/01-01-initiation.md)`
    *   *Fix*: If links are missing, add them.

*   **Dependency Logic**:
    *   Verify that the sequence of phases and steps honors technical dependencies (e.g., Backend API built before Frontend integration; Schema created before Queries).
    *   *Fix*: Reorder steps to prevent blocking.

*   **Specificity & Context**:
    *   Review `plan/codebase-discovery.json` for relevant existing file paths.
    *   Flag generic instructions like "Update code".
    *   *Fix*: Inject real file paths and specific actions (e.g., "Refactor `src/server/api.ts` to use `new-pattern`").

*   **Documentation Integration**:
    *   Check if `plan/documentation/` contains relevant patterns (e.g., "Testing Patterns").
    *   *Fix*: Link these documents in the "References" section or relevant steps.

*   **100% Coverage Check**:
    *   Compare `sprint-plan.md` against `plan/original-requirements.md`.
    *   *Fix*: If **ANY** requirement from the original request is missing from the plan, add specific steps to address it. **No gaps are acceptable.**

### 3. Refine `sprint-plan.md`
Regenerate the `sprint-plan.md` file. The new content must:

*   **Be a complete replacement** for the existing file.
*   **Maintain Preamble**: Keep "Sprint Overview", "TDD Strategy", etc.
*   **Structure Phases Logically**: Group work into Phases (e.g., Setup, Core Logic, UI, Integration).
*   **Be Hyper-Linked**:
    *   Tasks/Stories linked in every step.
    *   Documentation linked in preamble or relevant phases.
*   **Be Specific**: Use concrete file names and design references.
*   **Include Verification**: Ensure each Phase ends with a verifiable check (e.g., "Run `npm test`", "Verify route X").

### 4. Output
Provide a summary of the changes made to `sprint-plan.md`.

```markdown
# Sprint Plan Refinement Summary

## Changes Applied
- **Alignment**: [Action taken] (e.g., "Updated components to match sprint-design.md")
- **Linkage**: [Action taken] (e.g., "Added missing links to User Stories")
- **Dependencies**: [Action taken] (e.g., "Reordered API tasks before frontend")
- **Coverage**: [Action taken] (e.g., "Added step for missing requirement X")

## Remaining Work (if any)
- [List any dependencies or blockers identified]
```
