# Sprint Design Prompt

Use this prompt to generate a `sprint-design.md` file for a given plan directory. This document bridges the gap between the high-level plan and the actual execution, organizing tasks into phases and defining the testing/architecture strategy.

## Context
You are an expert Technical Project Manager and Software Architect. Your goal is to analyze the refined plan and detailed tasks/stories to create a cohesive Sprint Design that guides the development team.

## Inputs
- Target plan directory (e.g., `.planning/plans/48.0_code_quality`)

## Instructions

1. **Analyze Inputs:**
   - Read `original-requirements.md` to understand the core user intent.
   - Read `plan.md` to understand the high-level approach and metadata (Plan Type, Complexity).
   - Read all files in `tasks/` OR `user-stories/` (whichever exists). These are the "Work Items".

2. **Synthesize Phases:**
   - Group the Work Items into logical "Phases" (e.g., Setup, Core Logic, UI, Polish) or strict sequential steps if dependencies exist.
   - Estimate the timeline based on the number and complexity of tasks.

3. **Determine Complexity:**
   - Assess Architecture, Integration, Story/Test, and Risk/Unknowns on a scale (e.g., 1/3).

4. **Define Strategy:**
   - **Test Strategy:** Identify where tests live, what patterns to use (Unit/Integration/E2E), and specific tools.
   - **Architecture:** Define primitives, module boundaries, and external dependencies.
   - **Risks:** Identify technical and process risks and their mitigations.

5. **Generate Output:**
   - Create/Overwrite `sprint-design.md` in the target directory.
   - Use the template below.

## Sprint Design Template

```markdown
# Sprint Design: <Plan Title>

**Created:** <YYYY-MM-DD HH:MM:SS>
**Plan:** [<Plan Title>](./)
**Plan Type:** <From plan.md>
**Status:** Design Complete

---

## Original User Request

**What the user actually asked for:**
> <Quote from original-requirements.md>

**Referenced Resources:**
<List from original-requirements.md or "None">

**CRITICAL:** All sprint implementation must ultimately deliver on this original request. If tasks seem unrelated to the above, validate before proceeding.

---

## Configuration

**Sprint Name:** <Plan Title>
**Plan Type:** <From plan.md>
**Framework:** wasp
**Complexity:** <Calculated Score>/12 (<LOW/MODERATE/HIGH>)
**Timeline:** <N> days
**Phases:** <N>
**Pattern:** <e.g., Moderate TDD, Heavy Refactoring, Feature Build>

---

## Complexity Breakdown

- **Architecture:** <N>/3 - (<Reason>)
- **Integration:** <N>/3 - (<Reason>)
- **Story/Test:** <N>/3 - (<Reason>)
- **Risk/Unknowns:** <N>/3 - (<Reason>)

**Time Formula:** (<N> Tasks × <0.5/1.0> days) + buffer = <Total> days
**Calculation:** <Explanation>

---

## Phase Structure

1. **Phase 1**: <Phase Name> (<Duration>)
   - Stories/Tasks: <List Task/Story Names>
   - Focus: <Goal of this phase>

2. **Phase 2**: ...

---

## Work Decomposition

### Task Decomposition

### <Task/Story Title>
**Source:** <Task Filename or ID>
**Priority:** <High/Medium/Low> | **Effort:** <Small/Medium/Large>

**Testable Elements:**
- Element 1: <Component> (<unit/integration>) - <Verification Step>
- ...

**Success Criteria:**
- <Criteria 1>
- <Criteria 2>

**Dependencies:** <List dependencies>

<Repeat for all Work Items>

---

## Test Strategy

**PRIMARY_TEST_LOCATION:** <app/tests/ or src/tests/>
- Pattern: <SEPARATED/CO-LOCATED>
- Detected: <Observation>

**Test File Placement Examples:**
- Unit test for `<src_file>` → `<test_file>`
- ...

**Unit Tests:**
- Naming: *.test.ts
- Tools: vitest

**Integration Tests:**
- Focus: <Focus Area>

**E2E Tests:**
- Focus: <Focus Area>

---

## Architecture

**Primitives:**
- <Core Data Structures/Models>

**Module Boundaries:**
- <Directory paths>

**External Dependencies:**
- <New NPM packages or Services>

---

## Risks

**Technical:**
- **<Risk Name>:** <Description>
  - *Mitigation:* <Strategy>

**Process/TDD:**
- **<Risk Name>:** <Description>
  - *Mitigation:* <Strategy>

---

**Next:** `/create-sprint @<path-to-plan>`
```
