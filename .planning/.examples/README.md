# Input Examples for /init-plan

This directory contains example input files demonstrating best practices for the `/init-plan` command.

## Usage

Reference an example as a template:

```bash
# Copy and customize an example
cp examples/init-plan/feature-request-detailed.md .planning/preplanning/my-feature.md

# Then run init-plan with your customized file
/init-plan @.planning/preplanning/my-feature.md
```

## Examples by Plan Type

| Plan Type | Example File | When to Use |
|-----------|--------------|-------------|
| Feature | [feature-request-simple.md](init-plan/feature-request-simple.md) | Quick feature, clear scope |
| Feature | [feature-request-detailed.md](init-plan/feature-request-detailed.md) | Complex feature, multiple stakeholders |
| Bug Fix | [bug-report.md](init-plan/bug-report.md) | Fixing broken behavior |
| Tech Debt | [tech-debt.md](init-plan/tech-debt.md) | Refactoring, cleanup, modernization |
| Infrastructure | [infrastructure.md](init-plan/infrastructure.md) | CI/CD, deployment, tooling |
| Test Remediation | [test-remediation.md](init-plan/test-remediation.md) | Improving test coverage |

## What Makes Good Input?

### Essential Elements (All Types)

- **Clear problem statement**: What issue are we solving?
- **Success criteria**: How do we know we're done?
- **Scope boundaries**: What's explicitly out of scope?

### Feature-Specific

- User personas and their goals
- User journeys or workflows
- Acceptance criteria themes
- Non-functional requirements (performance, security)

### Bug-Specific

- Reproduction steps
- Expected vs actual behavior
- Impact assessment
- Environment details

### Tech Debt-Specific

- Current pain points with evidence
- Proposed solution approach
- Risk assessment
- Migration strategy (if applicable)

## Input Quality Impact

| Input Quality | Plan Output |
|---------------|-------------|
| Vague, 1-2 sentences | Generic plan, many assumptions, needs iteration |
| Clear problem + success criteria | Focused plan, reasonable scope estimation |
| Detailed with constraints | Accurate complexity, good user story themes |

## Tips

1. **Be specific about constraints**: Budget, timeline, technology restrictions
2. **Include context**: Why now? What triggered this request?
3. **Define non-goals**: Explicitly state what you're NOT doing
4. **Reference existing code**: Mention files/patterns to follow or avoid
