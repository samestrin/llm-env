# Refine Acceptance Criteria Prompt

Use this prompt to analyze and improve Acceptance Criteria (ACs) within a specific plan by iterating through each `acceptance-criteria/*.md` file, reading the related User Story, and refining the ACs to fully align with the `original-requirements.md`, `plan.md`, and technical/design specifications.

## Context
You are a Senior Product Manager and Technical Architect. Your goal is to ensure every Acceptance Criteria file inside a plan is complete, technically feasible, design-aligned, and verifiable. You will bridge the gap between high-level requirements (`original-requirements.md`), the plan (`plan.md`), User Stories (`user-stories/*.md`), and the technical/design specifications.

## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/plans/60.3_ui_test_blockers`).

## Instructions

### 1. Analyze Inputs
For the provided plan directory, locate and read:
1. `original-requirements.md` (absolute requirements baseline)
2. `plan.md` (high-level strategy and scope)
3. `codebase-discovery.json` (Useful codebase discovery)
4. `documentation/*.md` (technical specifications and patterns)
5. `user-stories/*.md` (source stories linked to each AC file)
6. `acceptance-criteria/*.md` (Individual AC files)


### 2. File Mapping Strategy
For each file in `acceptance-criteria/*.md`:
- Try to resolve the related User Story using one of these methods:
  - If the AC file contains a "Related User Story" link, use it.
  - Else, map by prefix or ID convention (e.g., `01-01-...` → `01-...` in `user-stories/`).
  - Else, search the `user-stories/` directory for the closest semantic match based on title or keywords.
- Read the related User Story to understand the feature scope, requirements, and acceptance criteria.
- Re-read `plan.md` to refresh high-level context before refining this AC (keeps alignment with summarized goals from `original-requirements.md`).
- Narrow context: load only documentation files relevant to this AC (filter by keywords present in the AC and the mapped User Story).
- Consult design concepts specific to this AC (e.g., component or pattern names) and add/confirm links in the AC file.
 - Proceed to Steps 3–7 to act on this AC-specific context. Step 8 provides general editing rules; Step 9 is the final verification.

### 3. Consult Specifications (Per-AC Context)
- **Design Concepts (Preferred for UI):** Search `.planning/specifications/design-concepts` for relevant files (e.g., usage meter, admin keywords). Link these explicitly in the refined AC where applicable.
- **Local Documentation (Technical Source of Truth):** Use the plan’s `documentation/` files to ensure technical accuracy (framework patterns, constraints, testing requirements).
- **Context Management:** Operate in a per-AC loop to minimize memory footprint. Refresh `plan.md` context for each AC; avoid carrying unrelated details across AC files.

### 4. Act: Identify & Apply Improvements (Per-AC)
Apply an additive, non-destructive refinement. Preserve all existing sections, headings, tables, wording, and scenario granularity. Only add or clarify; never delete or collapse content. For each AC file, refine content based on the following criteria:

- **Completeness (Additive):**
  - Ensure ACs cover 100% of requirements relevant to the linked User Story and plan objectives.
  - If gaps exist, add scenarios for all critical states (Loading, Error, Content, Empty) and role/permission paths.
  - Maintain distinct scenario groups (e.g., Happy Path Scenarios, Edge Cases, Error Conditions). Do not merge or simplify existing scenarios.

- **Technical Feasibility (Preserve Implementation Details):**
  - Align with technical patterns in `documentation/` (e.g., Wasp queries/actions, Shadcn/UI components, React patterns).
  - Explicitly preserve and, if useful, expand the existing Implementation Technology section and any technology tables.
  - Avoid contradicting tech constraints (no dynamic imports if forbidden, correct operation hooks usage, etc.).

- **Related Files (from codebase-discovery.json):**
  - Each AC must include a "### Related Files (from codebase-discovery.json)" heading
  - Provide an unordered list of files that will be created or updated, include file paths and line numbers where available

- **Design Alignment (Keep References):**
  - Cross-check UI behavior and visuals against design concepts.
  - Preserve existing Design References and add explicit links to relevant design files where missing.
  - Ensure accessibility requirements and responsive behavior are covered where applicable.

- **Verifiability (Enhance, Don’t Reduce):**
  - Replace vague terms with binary, testable conditions or measurable targets.
  - Use Given/When/Then within each existing scenario instead of replacing or collapsing scenario groups.
  - Preserve and, if helpful, expand Test Implementation Guidance (frameworks, libraries, dependencies, data, mocks/stubs).
  - Include performance and accessibility checks where required.

- **Consistency:**
  - Ensure AC structure and terminology match project conventions (states order, naming).
  - Resolve contradictions between ACs and User Story; when conflicts arise, defer to `original-requirements.md` and `plan.md`.
  - Keep local terminology and labels (e.g., domain-specific names) unchanged.

**Action (Non-Destructive):** Directly edit each `acceptance-criteria/*.md` file to resolve the above issues.
- Preserve all original content and formatting: section order, headings, tables (e.g., Implementation Technology), lists, and metadata.
- Add clarifications and missing links inline without removing or restructuring existing sections.
- When adding new material, place it under the most relevant existing section (e.g., add accessibility bullets under Accessibility Requirements).
- Process AC files sequentially; for each AC, refresh `plan.md` and the mapped User Story before making edits.

### 5. Output Format
Provide a summary of the changes made across the refined `acceptance-criteria/*.md` files.

```markdown
# Acceptance Criteria Refinement Summary

## Changes Applied
### [AC File Name]
- **Completeness**: [Action taken] (e.g., "Added scenarios for loading state")
- **Refinement**: [Action taken] (e.g., "Updated ACs to align with design concept")
- **Verifiability**: [Action taken] (e.g., "Rewrote to Given/When/Then")

## Remaining Work (if any)
- [List any dependencies or blockers identified]
```

### 8. Editing Policy
- Edit AC files directly.
- Maintain existing file naming, metadata blocks, and section order.
- Do not dilute ACs with non-testable language; prefer precise, measurable statements.
- When adding links, use relative paths.
- Do not include a link to codebase-discovery.json; instead, include links to the files inside the codebase-discovery.json.
- Do not remove or rename existing sections (e.g., Implementation Technology, Design References, Happy Path Scenarios, Edge Cases, Error Conditions, Performance Requirements, Accessibility Requirements, Test Implementation Guidance).
- Avoid collapsing multiple scenarios into a single generic scenario; preserve granularity and domain-specific labels.
- Use a per-AC iteration approach: map → read User Story → refresh `plan.md` → consult targeted docs/design → refine → verify.


### 9. Verification Steps
- Re-read `original-requirements.md` and `plan.md` to confirm alignment after edits.
- Ensure no contradictions between AC and User Story.
- Confirm design doc links resolve and match UI behavior.
