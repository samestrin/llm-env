# Codebase Discovery Prompt

Use this prompt to generate a `codebase-discovery.json` file for a new plan. This file serves as the architectural map for the implementation.

## Context
You are an expert Senior Software Architect. Your goal is to analyze a feature plan and the existing codebase to create a structured discovery map. This map identifies where new code should live, what existing patterns to follow, and where integration points exist to ensure consistency and minimize technical debt.

## Inputs
- Target plan directory (e.g., `.planning/plans/50.0_feature_name`)

## Instructions
Your task is to create the `codebase-discovery.json` file for the given plan directory. This file will serve as the architectural map for the implementation. This is a planning task and you are only allowed to touch this single file. Follow the steps below to create the file. 

1.  **Analyze Plan Artifacts**:
    *   Read `original-requirements.md` (User Intent).
    *   Read `plan.md` (Technical Plan).
    *   Read `documentation/*` (if available, for patterns and standards).

2.  **Explore the Codebase**:
    *   Search for similar features or patterns already implemented.
    *   Identify files that need to be modified.
    *   Identify where new files should be placed based on project structure.
    *   Check for existing "dead code" or "technical debt" related to the plan.
    *   **Verify** file paths exist using `ls` or `search`.

3.  **Generate `codebase-discovery.json`**:
    *   Create the file inside the target plan directory.
    *   Use the JSON structure defined below.

## JSON Output Template

```json
{
  "build_from": {
    "primary_file": "app/src/path/to/best/example.ts",
    "reason": "Why this file is the best reference (e.g., 'Follows the exact Wasp job pattern we need')",
    "suggested_approach": "How to adapt the pattern for this specific plan"
  },
  "existing_patterns": [
    {
      "name": "Pattern Name (e.g., Background Jobs)",
      "description": "How it works currently",
      "files": [
        "app/src/path/to/reference1.ts",
        "app/src/path/to/reference2.ts"
      ]
    }
  ],
  "files_to_modify": [
    "app/src/path/to/file_that_needs_changes.ts"
  ],
  "new_files_to_create": [
    "app/src/path/to/new_file.ts"
  ],
  "integration_gaps": [
    "List of missing connections or logic that needs to be bridged"
  ],
  "architecture_recommendations": [
    "Specific advice on structuring the new code",
    "Guidelines on naming conventions or library usage"
  ]
}
```

## Execution Rules
*   **Be Specific**: Use exact file paths.
*   **Verify Existence**: Do not invent file paths; ensure references exist.
*   **Prioritize Consistency**: Always recommend following existing patterns over inventing new ones unless the plan explicitly calls for refactoring.
