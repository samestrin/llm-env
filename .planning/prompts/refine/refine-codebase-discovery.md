# Refine Codebase Discovery Prompt

Use this prompt to update and improve an existing `codebase-discovery.json` file. This is useful when the plan evolves, new codebase patterns are discovered, or to correct initial assumptions.

## Context
You are an expert Senior Software Architect. Your goal is to review an existing architectural map (`codebase-discovery.json`) and refine it to ensure it is 100% accurate, comprehensive, and actionable for the development team.

## Inputs
- Target plan directory (e.g., `.planning/plans/50.0_feature_name`)

## Instructions
Your task is to refine the `codebase-discovery.json` file for the given plan directory. This file will serve as the architectural map for the implementation. This file should be comprehensive and it should cover all the files, directories, functions, patterns, line numbers, etc. that are relevant to the plan. This is a planning task and you are only allowed to touch this single file. Follow the steps below to refine/improve the file. 

### 1. Analyze Current State
*   Read `plan.md` and `original-requirements.md` to re-ground yourself in the requirements.
*   Read the existing `codebase-discovery.json`.
*   Read `documentation/*` (if available) for any new standards.
*   Search `.planning/specifications/` for any new or updated specifications.

### 2. Verify and Expand
*   **Path Verification**: Check if files listed in `files_to_modify` or `existing_patterns` still exist and are correct.
*   **Gap Analysis**: Are there missing "integration_gaps"? Does the plan require changes to files not yet listed?
*   **Pattern Check**: Are the "existing_patterns" still the best references? Is there a better example in the codebase?
*   **Architecture Review**: Are the "architecture_recommendations" specific enough? (e.g., mentioning strict typing, specific library versions, or specific directory structures).

### 3. Update `codebase-discovery.json`
*   **Preserve Structure**: Keep the valid parts of the existing JSON.
*   **Enrich**: Add missing details, correct wrong paths, and elaborate on "suggested_approach" or "reason".
*   **Prune**: Remove files or patterns that are no longer relevant to the refined plan.

## Output
Provide a summary of the changes made to `codebase-discovery.json`.

```markdown
# Codebase Discovery Refinement Summary

## Changes Applied
- **Additions**: [List added files/patterns] (e.g., "Added missing API endpoint file")
- **Corrections**: [List corrections] (e.g., "Corrected reference pattern for auth")
- **Pruning**: [List removed items] (e.g., "Removed deprecated file references")

## Remaining Work (if any)
- [List any ambiguities that require human input]
```
