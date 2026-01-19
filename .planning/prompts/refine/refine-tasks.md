# Refine Tasks Prompt

Use this prompt to refine and improve the individual task files in the plan's `tasks/` directory. Do not create a consolidated `tasks.md` unless explicitly requested. Ensure every User Story is actionable and every technical step is accurate.

## Context
You are a Senior Engineering Lead. Your goal is to translate the User Stories (`user_stories.md`) into a concrete set of engineering tasks by refining the existing `tasks/*.md` files so a developer can execute them. You must ensure the tasks are granular, technically accurate based on the documentation, and cover the full scope of work.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/57.0_voice_api_cms_integrations`).

## Instructions
Your task is to update the task files in task/ and possibly the plan.md, you should not be coding at this time. This is a planning task. Please review, refine, and improve the tasks. Using the plan and tasks, a developer should be able to completely deliver 100% on the original-requirements.md without any gaps. If there are gaps, you must close them. 

### 1. Analyze Inputs
Locate and read the following within the provided plan directory:
1.  `tasks/*.md` (The individual task files to refine)
2.  `original-requirements.md` (The source of requirements, the tasks should resolve or deliver this)
3.  `plan.md` (The requirements converted into a plan, should include tasks)
4.  `documentation/*.md` (The supporting technical specifications and patterns)
5.  `codebase-discovery.json` (The output of the codebase discovery, should include file paths, function names, and class names)

### 2. Consult Specifications
- **Technical Patterns:** Refer to `documentation/` to ensure tasks describe the *correct* technical implementation (e.g., "Create Wasp API using `apiNamespace`" vs "Create Express route").
- **Design Concepts:** If tasks involve frontend work, refer to `.planning/specifications/design-concepts` for implementation details.

### 3. Identify & Apply Improvements
Review and refine each file in `tasks/` based on the following criteria:

- **Coverage:** Do the tasks collectively complete *all* User Stories and Acceptance Criteria?
- **Technical Accuracy:**
    - Do the tasks reference specific files, functions, or patterns defined in `documentation/`?
    - **Action:** Update task descriptions to be specific (e.g., instead of "Build API", say "Implement `voiceProfileCreate` API in `src/server/api/voiceProfiles.ts` using `APIKey` middleware").
- **Granularity:**
    - Are tasks sized appropriately (approx. 1-4 hours)?
    - Break down monolithic tasks (e.g., "Build Integration") into smaller steps (e.g., "Scaffold Plugin", "Implement Auth", "Map Fields").
- **Dependencies:** Are tasks ordered logically?

**Action:** Directly edit existing task files or create new task files under `tasks/` to resolve these issues. Do not create `tasks.md` unless explicitly requested. Ensure each task file follows the project's task file standard.

### 4. Update `plan.md`:
   - Add a link to each individual task file in the task directory in the plan.md file under "## Tasks"

### 5. Output Format
Provide a summary of the changes made across the refined `tasks/*.md` files.

```markdown
# Tasks Refinement Summary

## Changes Applied
### [Feature/Section Name]
- **Breakdown**: Split [Large Task] into [Sub-task 1] and [Sub-task 2].
- **Accuracy**: Updated [Task X] to reference [Specific Pattern/File] from documentation.
- **Coverage**: Added tasks to cover [User Story Y].

## Remaining Work (if any)
- [List any dependencies or blockers identified]
```
