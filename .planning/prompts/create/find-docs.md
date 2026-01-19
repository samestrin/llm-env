# Find Documentation Prompt

Use this prompt to identify relevant architectural specifications and documentation for a given sprint plan.

## Context
You are a Technical Lead responsible for ensuring that implementation plans are grounded in established architectural specifications. Your goal is to scan a sprint's requirements and plan, then identify the most relevant documentation in the `.planning/specifications/` directory to guide development.

## Inputs
You will be provided with an "input path" which is a path to a plan or sprint directory (e.g., `.planning/sprints/active/XX.X_sprint_name` or `.planning/plans/XX.X_plan_name`).

## Instructions
Your task is to identify the most relevant architectural specifications and documentation for the given plan or sprint plan. You will be generated a single file `documentation/source.md` which is a reference file that includes details about what files should be aggregated as documentation for this plan. This is a planning task, you are not coding, you may only edit one file. 

### 1. Analyze Sprint Context
Locate and read the following files within the provided sprint directory:
1.  `plan/original-requirements.md` (`original-requirements.md`) - The Requirements
2.  `plan/plan.md` (`plan.md`)  - The Implementation Plan

Extract key features, architectural components, database models, and workflows described in these documents.

### 2. Search Specifications
Scan the `.planning/specifications/` directory and its subdirectories.
- Match the extracted concepts against filenames and file contents in the specification library.
- Identify files that define the patterns, data structures, or behaviors required by the sprint.

### 3. Filter and Group
Apply the following logic to build the result list:
1.  **Relevance**: Rank files based on how critical they are to the specific tasks in the sprint plan.
2.  **Grouping**:
    - If **2 or more** relevant files are found within the same immediate subdirectory (e.g., `.planning/specifications/database/`), collapse them into the folder path (e.g., `.planning/specifications/database/`).
    - Otherwise, list the individual file path.
3.  **Limit**: Select the **top 8** most relevant items (files or folders).
4.  **Ignore**: You should always ignore:
    - Files in the `.planning/specifications/local-services/` directory.
    - `.planning/specifications/coding-standards.md`
    - `.planning/specifications/git-strategy.md`
    - `.planning/specifications/implementation-standards.md`
    - `README.md` (directory indexes, maybe used for discoverry)

### 4. Write `documentation/source.md`
Create an index of the documentation references found in the previous step inside the "input path" folder, use ordered lists, include markdown links and specific line number ranges. If the `source.md` file already exists in the documentation directory, append to it.

### 5. Output Format
Present the findings in the following format:

```markdown
# Related Specifications

## Context
- **Sprint Target**: [Brief summary of what this sprint is building]

## Recommended Documentation
[List the top 8 items here]
- `path/to/spec.md` (or `path/to/folder/`)
    - *Relevance*: [Brief explanation of why this is needed for this sprint]

## Warnings
[Include this section ONLY if more than 8 relevant items were found]
- **High Complexity Warning**: More than 8 relevant specification areas were identified. The list above is truncated to the most critical ones. This suggests the sprint may be touching too many architectural concerns simultaneously.

## Command
/create-documentation @path/to/input/directory @path/to/file1 @path/to/folder2 ..
```
(Note: Replace `@path/to/input/directory` with the provided sprint directory and list all recommended file/folder paths separated by spaces)
