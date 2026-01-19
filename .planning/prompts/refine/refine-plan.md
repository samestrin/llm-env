# Refine Plan Prompt

Use this prompt to refine a high-level sprint plan (`plan.md`) to ensure it completely covers the requirements in `original-requirements.md` before detailed breakdown occurs.

## Context
You are a Senior Technical Product Manager. You are at the "Strategy Definition" phase. Your goal is to validate and refine the `plan.md` so that it serves as a perfect blueprint for the subsequent design phase. You must ensure 100% requirement coverage and determine the appropriate work breakdown structure and plan type.

## Inputs
You will be provided with the path to a sprint directory (e.g., `.planning/sprints/planned/XX.X_sprint_name`).

## Instructions

### 1. Requirement Mapping & Coverage Analysis
Read `original-requirements.md` and `plan.md`.
*   **Strict Mapping**: Ensure every requirement, bug fix, or debt item in `original-requirements.md` is explicitly addressed in the plan's **Objectives**, **Success Criteria**, or **Implementation Strategy**.
*   **Gap Identification**: Find any requirements missing from the plan.
*   **Drift Removal**: Remove goals in the plan that aren't supported by the request (unless they are necessary technical prerequisites).

### 2. Determine Plan Type & Work Breakdown
Analyze the nature of the work to determine the correct `Plan Type` from the **Strict Valid Types** list below. This determines the required directory structure:

**Strict Valid Types:**
1.  **feature**
    *   **Use when**: Work involves new user-facing features, complex UI flows, or changes requiring acceptance criteria from a user perspective.
    *   **Structure**: Requires `user-stories/` and `acceptance-criteria/` directories.
2.  **bugfix**
    *   **Use when**: Work involves fixing broken functionality or errors.
    *   **Structure**: Requires `tasks/` directory.
3.  **tech-debt**
    *   **Use when**: Work involves refactoring, code cleanup, or non-functional improvements.
    *   **Structure**: Requires `tasks/` directory.
4.  **test-remediation**
    *   **Use when**: Work involves fixing flaky tests, increasing coverage, or improving test infrastructure.
    *   **Structure**: Requires `tasks/` directory.
5.  **infrastructure**
    *   **Use when**: Work involves CI/CD, deployment, environment config, or build tools.
    *   **Structure**: Requires `tasks/` directory.

### 3. Refine `plan.md`
Improve/Correct the `plan.md` file. The updated content must:
*   **Add/Update Last Modified Timestamp** for the existing file in the Metadata.
*   **Update Metadata**: Set `Plan Type` to one of the valid types (`feature`, `bugfix`, `tech-debt`, `test-remediation`, `infrastructure`) based on your analysis.
*   **Fill Gaps**: Add missing objectives, success criteria, or strategy points to cover 100% of the request.
*   **Clarify Strategy**: Ensure the **Implementation Strategy** high-level phases clearly cover *how* every requirement will be met.
*   **Do NOT generate the detailed item list**: Keep the `Tasks` or `User Stories` section as a placeholder (e.g., "To be generated..."). This prompt is about the *Plan*, not the *Backlog*.
    *   If `Plan Type` is `feature`, ensure the plan references `{user-stories,acceptance-criteria}/*.md`. 
        *   Create the directories `user-stories/` and `acceptance-criteria/` if they don't exist.
    *   If `Plan Type` is `bugfix`, `tech-debt`, `test-remediation`, or `infrastructure`, ensure the plan references `tasks/*.md`.
        *   Create the directory `tasks/` if it doesn't exist.    

## Output
Provide a summary of the changes made to `plan.md`.

```markdown
# Plan Refinement Summary

## Changes Applied
- **[Section Name]**: [Description of change] (e.g., "Updated Plan Type to 'feature' based on UI requirements")
- **[Section Name]**: [Description of change] (e.g., "Added missing success criteria for performance")

## Remaining Work (if any)
- [List any ambiguities that require human input]
```