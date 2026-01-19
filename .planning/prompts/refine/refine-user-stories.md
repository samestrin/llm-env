# Refine User Stories Prompt

Use this prompt to analyze and improve the User Stories and Acceptance Criteria (ACs) within a specific plan, ensuring they fully satisfy the original request and align with technical and design specifications.

## Context
You are a Senior Product Manager and Technical Architect. Your goal is to ensure that the `user_stories.md` file is a complete, verifiable, and implementable representation of the user's intent. You must bridge the gap between high-level requirements (`original-requirements.md`) and technical reality (`documentation/`), while incorporating specific design guidance.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/57.0_voice_api_cms_integrations`).

## Instructions

### 1. Analyze Inputs
Locate and read the following within the provided plan directory:
1.  `user-stories/*.md` (The current stories, if they exist)
2.  `original-requirements.md` (The absolute requirement baseline)
3.  `plan.md` (The high-level strategy)
4.  `documentation/*.md` (The supporting documentation)

### 1.5 Missing Stories
Does the combination of the existing user stories and acceptance criteria cover all aspects of the original request/plan? If not, create the missing user stories now using the "User Story Template".

### 2. Consult Specifications
- **Design Concepts:** Search `.planning/specifications/design-concepts` for any files relevant to the features described. (Prefer this over local documentation when available.)
- **Local Documentation:** Use the files in the plan's `documentation/` folder as the technical "Source of Truth".

### 3. Identify & Apply Improvements
Review `user-stories/*.md` (or create it if missing) based on the following criteria:

- **Completeness (Crucial):** Does the set of stories cover 100% of the requirements in `original-requirements.md`? If not, add missing stories.
    - The `plan.md` is a refined version of the original request.
    - **Action:** Based on the `original-request` > `plan.md` (requirements), update the `user-stories/*.md` to close all gaps and deliver 100% on the requirements.
- **Technical Feasibility:** Do the Acceptance Criteria (ACs) align with the patterns defined in `documentation/`? (e.g., if docs say "Use API Key Auth", ACs shouldn't say "User logs in with password").
    - **Action:** Update ACs to match the technical patterns defined in `documentation/`.
- **Design Alignment:**
    - For any story involving UI, cross-check against `.planning/specifications/design-concepts`.
    - **Action:** Add specific links to relevant design concept files within the User Story or ACs (e.g., "Reference: [Visual Collaboration Interface](../../specifications/design-concepts/2-immediate-next-features/visual-collaboration/visual-collaboration-interface.md)").
- **Project Alignment:**
    - **Action:** Review import paths in User Stories and ACs to ensure they align with the project's structure. Update as needed.
- **Coverage:** Do the ACs cover all aspects of the feature? If not, add missing ACs.
    - Each User Story has an "Acceptance Criteria Overview" section listing all expected ACs. 
    - **Action:** Add any missing ACs documents found in this list to `acceptance-criteria/` directory.
- **Verifiability:** Are the ACs testable? Avoid vague terms like "fast" or "easy". Use specific metrics or binary conditions.

**Action:** Directly edit `user-stories/*.md` to resolve these issues.

## Output
Provide a summary of the changes made across the refined `user-stories/*.md` files.

```markdown
# User Stories Refinement Summary

## Changes Applied
### [User Story File]
- **Completeness**: [Action taken] (e.g., "Added missing ACs for error states")
- **Technical**: [Action taken] (e.g., "Aligned auth flow with documentation")
- **Design**: [Action taken] (e.g., "Linked to new visual design specs")

## Remaining Work (if any)
- [List any dependencies or blockers identified]
```
