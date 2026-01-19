# User Stories Generation Prompt

Use this prompt to generate user stories for a plan directory and then derive acceptance criteria for each story, so the plan delivers 100% of the original request.

## Context
You are an expert Product Manager and Technical Project Manager. Your goal is to create clear, actionable user stories that fully align with the original request, plan details, and codebase discovery.

## Inputs
- Target plan directory (e.g., `.planning/plans/XX.X_feature_or_tech_debt`)

## Instructions

1. Locate and read the following files inside the target plan directory:
   - `plan.md` – The detailed plan to implement
   - `original-requirements.md` – Source of truth for the request and requirements
   - `codebase-discovery.json` – Primary/related files, patterns, recommendations
   - `documentation/*.md` – Backend, NPM tools, and Testing patterns

2. Identify all work items in `plan.md` (Technical Debt Inventory or feature items). Create one user story per item.

3. Create `user-stories/` under the target plan directory. Name each file:
   - `NN-<slug>.md` (two-digit order matching `plan.md`; concise hyphenated slug)

4. Populate each user story using the template below. Ensure links to `documentation/*.md` and file paths listed in `codebase-discovery.json` are included.

5. Generate acceptance criteria for each user story:
   - Create `acceptance-criteria/` under the target plan directory
   - For each file in `user-stories/*.md`, produce one or more acceptance criteria files named `NN-MM-<slug>.md` where `NN` is the user story number and `MM` is a two-digit sequential counter (starting at `01`)
   - Link each acceptance criteria file back to its related user story and to relevant documentation and related files listed in `codebase-discovery.json`

6. Validate coverage:
   - Each item in `plan.md` has a corresponding user story
   - All requirements from `original-requirements.md` appear in relevant stories
   - Stories include documentation links and related file references
   - Each user story has at least one acceptance criteria file capturing its key outcomes

## User Story Template

```markdown
### User Story NN: <Title>

**As a** <role>
**I want** <goal>
**So that** <business value>.

## Story Context
- **Background:** <context from plan.md/original-requirements.md>
- **Assumptions:** <key assumptions>
- **Constraints:** <architectural or tooling constraints>

## Story Details
- **Priority:** <P1/P2/P3>
- **Effort Estimate:** <S/M/L>
- **Dependencies:** <TD-1 or other>

## Success Criteria (SMART)
- **Specific:** <what exactly must be done>
- **Measurable:** <how to measure success>
- **Achievable:** <why feasible>
- **Relevant:** <why this matters>
- **Time-bound:** <target timeframe>

## Acceptance Criteria Overview
- <AC 1>
- <AC 2>
- <AC 3>

## Technical Considerations
- **Implementation Notes:** <files, modules, patterns>
- **Integration Points:** <ops, services, jobs>
- **Data Requirements:** <models/config>

## Documentation Links
- [Backend Development Patterns](../../documentation/backend-development-patterns.md)
- [Testing Patterns](../../documentation/testing-patterns.md)
- [NPM Tool Patterns](../../documentation/npm-tool-patterns.md)

## Related Files (from codebase-discovery.json)
- <list key file paths used by this story>

## Potential Risks
- **Risk:** <description> – **Mitigation:** <strategy>

---

**Created:** <YYYY-MM-DD>
**Story Status:** Draft - Awaiting Acceptance Criteria
```

## Output
- Generate `user-stories/NN-<slug>.md` for every item in the plan, each fully populated and linked to documentation and discovered files.
- For each user story, generate acceptance criteria files under `acceptance-criteria/` using the template below.

## Acceptance Criteria Template

```markdown
## Acceptance Criteria: <Short Title>

**Related User Story:** [NN: <User Story Title>](../user-stories/NN-<slug>.md)

### Overview
<Summarize what this acceptance criteria validates and why it matters>

### Implementation Technology
| Aspect | Technology/Approach | Notes |
|--------|---------------------|-------|
| **Component Type** | <component or file> | <path(s)> |
| **Test Framework** | Vitest | Unit/Integration testing |
| **Key Dependencies** | <libraries/tools> | <constraints> |

### Happy Path Scenarios
**Scenario 1: <title>**
- **Given** <precondition>
- **When** <action>
- **Then** <expected outcome>

**Scenario 2: <title>**
- **Given** <precondition>
- **When** <action>
- **Then** <expected outcome>

### Edge Cases
- **Edge Case 1:** <description> → Expected: <behavior>

### Performance / Build Requirements
- <requirements>

### Test Implementation Guidance
**Test Type:** UNIT / INTEGRATION

**Test Data Requirements:**
- <data or fixtures>

**Mock/Stub Requirements:**
- <mocks or stubs>

**Test Coverage Expectations:**
- <coverage goals>

### Documentation Links
- [Backend Development Patterns](../../documentation/backend-development-patterns.md)
- [Testing Patterns](../../documentation/testing-patterns.md)
- [NPM Tool Patterns](../../documentation/npm-tool-patterns.md)

### Related Files (from codebase-discovery.json)
- `../../codebase-discovery.json`
- <list key file paths>

### Definition of Done
**Auto-Verified**:
- [ ] All tests passing
- [ ] Coverage ≥ 80%
- [ ] No linting errors
- [ ] Build succeeds
- [ ] Documentation updated

**Manual Review**:
- [ ] Code reviewed and approved

**Story-Specific**:
- [ ] <primary criteria satisfied>
```
