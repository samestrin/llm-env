# Refine Documentation Prompt

Use this prompt to analyze and directly improve the documentation within a specific plan directory, ensuring it aligns with the codebase reality and global specifications.

## Context
You are a Senior Technical Writer and Engineer. Your goal is to ensure that the documentation generated for a sprint is accurate, complete, and compliant with the project's architectural standards. You will compare the current documentation against the actual codebase and the global specifications, then **directly apply** the necessary improvements to the documentation files.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/50.0_documentation_process_improvements`).

## Instructions
Your task is to update the documentation files in documentation/ and possibly the plan.md, you should not be coding at this time. This is a planning task. Please review, refine, and improve the documentation. The documentation should be complete and accurate, and should align with the codebase reality and global specifications. The purpose of the local documentation is to provide quick/easy access to revelant documentation excerpts with links back to the original source material. If there are documentation gaps, you must close them. 

### 1. Analyze Inputs
Locate and read the following within the provided plan directory:
1.  `documentation/*.md` (The current documentation set)
2.  `codebase-discovery.json` (Useful codebase discovery)
3.  `plan.md` & `original-requirements.md` (The intent)
4.  `source.md` (Optional, if exists, this provides pointers to specific documentation files)

### 2. Consult Specifications
Search the `.planning/specifications/` directory for standards relevant to the topics covered in the local documentation. Use these as the "Source of Truth" for patterns and best practices.

### 3. Identify & Apply Improvements
Compare the local documentation against the `codebase-discovery.json` and global specifications. Look for:
*   **Drift**: Where the documentation describes something different from the code (e.g., Redis vs In-Memory).
*   **Gaps**: Missing context, setup instructions, or architectural decisions found in the code but not the docs.
*   **Compliance**: Deviations from global patterns defined in `.planning/specifications/`.

**Action:** Directly edit existing or create new documentation files in the `documentation/` directory to resolve these issues.
*   Update existing files to match reality/specs.
*   Create new files if major concepts are missing.
*   Update `documentation/README.md` and `README.md` to reflect any new files or changes - be sure to maintain proper sort order based on importance of the documentation.

### 4. Output Format
Provide a summary of the changes made.

```markdown
# Documentation Refinement Summary

## Changes Applied
### [Filename.md]
- **Issue Resolved**: [Description of drift or gap]
    - **Action Taken**: [Specific change made]

### [NewFile.md] (Created)
- **Reason**: [Why this file was needed]

## Remaining Work (if any)
- [List any ambiguities that require human input]
```

