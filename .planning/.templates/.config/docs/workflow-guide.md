# TDD Workflow Guide

Complete reference for TDD sprint workflow with command sequences, flags, and best practices.

---

## Quick Reference

### Setup Commands (Run Once Per Project)

| Command | Purpose | Flags |
|---------|---------|-------|
| `/init-specs` | Generate development specifications | `--language <lang>` `--framework <fw>` `--update` `--force` |
| `/init-planning-templates` | Download planning templates | (none) |
| `/init-documentation` | Generate package documentation | `--update` `--include-transitive` `--packages pkg1,pkg2` |
| `/migrate-config-to-yaml` | Migrate legacy config files | `--dry-run` `--keep-legacy` |

### Planning Commands

| Command | Purpose | Flags |
|---------|---------|-------|
| `/init-plan` | Create implementation plan | `--type=TYPE` `--comprehensive` `--no-identify-packages` |
| `/find-documentation` | Identify relevant docs for plan | (path only) |
| `/create-documentation` | Create documentation index | `@doc1 @doc2 ...` |
| `/create-user-stories` | Generate user stories | `--resume` `--max-parallel=N` |
| `/create-acceptance-criteria` | Generate acceptance criteria | `--resume` `--max-parallel=N` |
| `/create-tasks` | Generate tasks (non-feature plans) | `--max-parallel=N` |
| `/design-sprint` | Analyze and design sprint | (path only) |
| `/create-sprint` | Generate executable sprint plan | `--tdd-strict` `--tdd-pragmatic` |

### Execution Commands

| Command | Purpose | Flags |
|---------|---------|-------|
| `/execute-sprint` | Implement sprint plan | (path only) |
| `/create-frontend-tests` | Generate frontend test plan | (path only) |
| `/execute-frontend-tests` | Run frontend tests | `--mode=X` `--capture=X` `--detail=X` `--coverage=X` `TC-XX through TC-YY` |
| `/execute-frontend-tests-audit` | Full visual audit | `--detail=X` `--coverage=X` `TC-XX through TC-YY` |

### Validation & Completion Commands

| Command | Purpose | Flags |
|---------|---------|-------|
| `/code-review` | Automated code review with DoD | `--deep` `--run-tests` `--run-regression` `--dry-run` |
| `/validate-sprint` | Validate sprint completeness | (path only) |
| `/sprint-complete` | TDD compliance check, alignment | `--quick` `--comprehensive` `--dry-run` `--keep-sprint-active` |
| `/finalize-sprint` | Merge PR, cleanup | `--dry-run` `--no-merge` |

### Recovery Commands

| Command | Purpose | Flags |
|---------|---------|-------|
| `/fix-ci` | Diagnose and repair CI failures | `--run-id=<id>` `--dry-run` |

### Utility Commands

| Command | Purpose | Flags |
|---------|---------|-------|
| `/help-workflow` | Display this guide | `--refresh` |

---

## Main Workflow: Feature Sprint

Standard workflow for implementing new features with TDD.

```
SETUP (once per project)
│
├── /init-specs --language typescript --framework react
│   Creates: .planning/specifications/
│
├── /init-planning-templates
│   Creates: .planning/.templates/
│
└── /init-documentation
    Creates: .planning/documentation/
    
─────────────────────────────────────────────────────

PLANNING PHASE
│
├── Step 1: /init-plan "description" --type=feature
│   Creates: .planning/plans/X.X_name/
│   - plan.md
│   - original-requirements.md
│   - metadata.md
│
├── Step 2: /find-documentation @.planning/plans/X.X_name/
│   (Optional) Identifies relevant docs for the plan
│
├── Step 3: /create-documentation @.planning/plans/X.X_name/ @doc1 @doc2
│   (Optional) Creates documentation/ index
│
├── Step 4: /create-user-stories @.planning/plans/X.X_name/
│   Creates: user-stories/*.md
│   (Use --resume if interrupted)
│
├── Step 5: /create-acceptance-criteria @.planning/plans/X.X_name/
│   Creates: acceptance-criteria/*.md
│   (Use --resume if interrupted)
│
├── Step 6: /design-sprint @.planning/plans/X.X_name/
│   Creates: sprint-design.md
│
└── Step 7: /create-sprint @.planning/plans/X.X_name/
    Creates: .planning/sprints/active/X.X_name/
    - sprint-plan.md
    - metadata.md
    - README.md
    - plan/ (copy of plan folder)

─────────────────────────────────────────────────────

EXECUTION PHASE
│
└── Step 8: /execute-sprint @.planning/sprints/active/X.X_name/
    Implements sprint tasks with TDD

─────────────────────────────────────────────────────

QUALITY PHASE
│
├── Step 9: /code-review @.planning/sprints/active/X.X_name/ --run-tests
│   Creates: code-review-report.md
│   Flags:
│   - --deep: Include user story DoD verification
│   - --run-tests: Execute sprint-specific tests
│   - --run-regression: Execute full test suite
│   - --dry-run: Preview without modifying files
│
├── Step 10: /validate-sprint @.planning/sprints/active/X.X_name/
│   (Optional) Additional validation checks
│
├── Step 11: /sprint-complete @.planning/sprints/active/X.X_name/
│   TDD compliance, alignment verification
│   Flags:
│   - --quick: Fast validation
│   - --comprehensive: Deep analysis
│   - --dry-run: Preview only
│   - --keep-sprint-active: Don't mark complete
│
└── Step 12: /finalize-sprint
    Merges PR, moves to completed/
    Flags:
    - --dry-run: Preview merge without executing
    - --no-merge: Skip PR merge
    
    Shows CI status after merge:
    - If CI fails → Run /fix-ci
```

---

## Alternative Workflow: Non-Feature Plans

For bugfix, tech-debt, infrastructure, and test-remediation plans.

```
├── /init-plan "description" --type=bugfix
│   (or --type=tech-debt, --type=infrastructure, --type=test-remediation)
│
├── /create-tasks @.planning/plans/X.X_name/
│   Creates: tasks/*.md (instead of user-stories)
│
├── /design-sprint @.planning/plans/X.X_name/
│
├── /create-sprint @.planning/plans/X.X_name/
│
└── Continue with execution and quality phases...
```

**Plan Types:**

| Type | Use Case | Work Source |
|------|----------|-------------|
| `feature` | New functionality | user-stories/ |
| `bugfix` | Bug fixes | tasks/ |
| `tech-debt` | Technical debt cleanup | tasks/ |
| `infrastructure` | DevOps, CI/CD, tooling | tasks/ |
| `test-remediation` | Test improvements | tasks/ |

---

## Frontend Testing Workflow

For UI/visual testing with browser automation.

```
After sprint execution:
│
├── /create-frontend-tests @.planning/sprints/active/X.X_name/
│   Creates: frontend-tests/test-plan.md
│
├── /execute-frontend-tests @frontend-tests/test-plan.md
│   Runs tests via Chrome DevTools MCP
│   Flags:
│   - --mode=targeted|exploratory|regression
│   - --capture=screenshot|video|none
│   - --detail=minimal|standard|verbose
│   - --coverage=changed|module|full
│   - TC-XX through TC-YY: Run specific test cases
│
└── /execute-frontend-tests-audit @frontend-tests/test-plan.md
    Full visual audit with exploratory analysis
    Flags:
    - --detail=minimal|standard|verbose
    - --coverage=changed|module|full
    - TC-XX through TC-YY: Run specific test cases
```

---

## Documentation Workflow

Managing project documentation.

```
SETUP
│
└── /init-documentation
    Scans package.json/requirements.txt
    Generates documentation for dependencies
    Flags:
    - --update: Refresh existing docs
    - --include-transitive: Include transitive deps
    - --packages pkg1,pkg2: Specific packages only

─────────────────────────────────────────────────────

PER-PLAN (Optional)
│
├── /find-documentation @.planning/plans/X.X_name/
│   Identifies relevant docs based on plan content
│
└── /create-documentation @.planning/plans/X.X_name/ @doc1 @doc2
    Creates plan-specific documentation index
```

---

## Recovery Workflow: CI Failures

When CI fails after finalizing a sprint.

```
/finalize-sprint
│
└── CI Status: ❌ failing
    │
    └── /fix-ci
        Diagnoses and repairs CI failures
        Flags:
        - --run-id=<id>: Fix specific run
        - --dry-run: Diagnose only
        
        Error categories:
        - lint: Auto-fixes with npm run lint:fix
        - type: Fixes TypeScript errors
        - test: Fixes failing tests
        - build: Fixes import/module errors
        - dependency: Reinstalls node_modules
```

---

## Flag Reference

### /init-plan

| Flag | Description |
|------|-------------|
| `--type=TYPE` | Plan type: feature, bugfix, tech-debt, infrastructure, test-remediation |
| `--comprehensive` | Enable comprehensive analysis mode |
| `--no-identify-packages` | Disable package identification |

### /init-specs

| Flag | Description |
|------|-------------|
| `--language <lang>` | Primary language (typescript, python, go, etc.) |
| `--framework <fw>` | Framework (react, nextjs, fastapi, etc.) |
| `--update` | Update existing specs |
| `--force` | Overwrite without prompting |

### /init-documentation

| Flag | Description |
|------|-------------|
| `--update` | Refresh existing documentation |
| `--include-transitive` | Include transitive dependencies |
| `--packages pkg1,pkg2` | Document specific packages only |

### /create-user-stories, /create-acceptance-criteria, /create-tasks

| Flag | Description |
|------|-------------|
| `--resume` | Continue generation after crash/interruption (skips existing files) |
| `--max-parallel=N` | Number of parallel generations (default: 3) |

### /create-sprint

| Flag | Description |
|------|-------------|
| `--tdd-strict` | Force strict RED-GREEN-REFACTOR for all stories |
| `--tdd-pragmatic` | Force pragmatic TDD for all stories |

### /execute-frontend-tests

| Flag | Description |
|------|-------------|
| `--mode=X` | targeted, exploratory, regression |
| `--capture=X` | screenshot, video, none |
| `--detail=X` | minimal, standard, verbose |
| `--coverage=X` | changed, module, full |
| `TC-XX through TC-YY` | Run specific test case range |

### /code-review

| Flag | Description |
|------|-------------|
| `--deep` | Include user story DoD verification |
| `--run-tests` | Execute sprint-specific tests |
| `--run-regression` | Execute full test suite |
| `--dry-run` | Preview without modifying files |

### /sprint-complete

| Flag | Description |
|------|-------------|
| `--quick` | Fast validation (skip comprehensive checks) |
| `--comprehensive` | Deep analysis (takes longer) |
| `--dry-run` | Preview only, no file modifications |
| `--keep-sprint-active` | Don't mark sprint as complete |

### /finalize-sprint

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview merge without executing |
| `--no-merge` | Skip PR merge (validation only) |

### /fix-ci

| Flag | Description |
|------|-------------|
| `--run-id=<id>` | Fix specific CI run (default: latest failed) |
| `--dry-run` | Diagnose only, don't apply fixes |

### /migrate-config-to-yaml

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview migration without writing |
| `--keep-legacy` | Keep original files after migration |

---

## Directory Structure

```
.planning/
├── .config/                      # Configuration
│   ├── config.yaml               # Main config
│   └── docs/                     # Cached docs
│       └── workflow-guide.md
│
├── .templates/                   # Downloaded templates
│   ├── helper-llm/               # Helper LLM prompts
│   └── output/                   # Output templates
│
├── .temp/                        # Temporary files
│
├── specifications/               # From /init-specs
│   ├── implementation-standards.md
│   ├── coding-standards.md
│   └── git-strategy.md
│
├── documentation/                # From /init-documentation
│   └── <package-name>.md
│
├── plans/                        # From /init-plan
│   └── X.X_name/
│       ├── plan.md
│       ├── original-requirements.md
│       ├── metadata.md
│       ├── sprint-design.md      # From /design-sprint
│       ├── documentation/        # From /create-documentation
│       ├── user-stories/         # From /create-user-stories
│       ├── acceptance-criteria/  # From /create-acceptance-criteria
│       └── tasks/                # From /create-tasks
│
└── sprints/
    ├── active/                   # Active sprints
    │   └── X.X_name/
    │       ├── sprint-plan.md    # From /create-sprint
    │       ├── metadata.md
    │       ├── README.md
    │       ├── plan/             # Copy of plan folder
    │       ├── code-review-report.md  # From /code-review
    │       └── clarifications/
    │
    └── completed/                # Finalized sprints
```

---

## Best Practices

### 1. Always Run Setup First
```bash
/init-specs --language typescript --framework react
/init-planning-templates
/init-documentation
```

### 2. Use Appropriate Plan Types
- New features → `--type=feature` → creates user-stories
- Bug fixes → `--type=bugfix` → creates tasks
- Tech debt → `--type=tech-debt` → creates tasks

### 3. Code Review Strategy
```bash
# During development (preview)
/code-review @sprint/ --dry-run

# Before completion (verify)
/code-review @sprint/ --deep --run-tests

# Before release (comprehensive)
/code-review @sprint/ --deep --run-regression
```

### 4. Handle CI Failures
After `/finalize-sprint` shows CI failing:
```bash
/fix-ci                # Auto-diagnose and repair
/fix-ci --dry-run      # Diagnose only
```

### 5. Frontend Testing Flow
```bash
/create-frontend-tests @sprint/
/execute-frontend-tests @test-plan.md --mode=targeted
/execute-frontend-tests @test-plan.md TC-01 through TC-05  # Specific tests
/execute-frontend-tests-audit @test-plan.md  # Full audit
```

---

## Troubleshooting

**Q: Which command creates user stories vs tasks?**
A: Use `/create-user-stories` for feature plans, `/create-tasks` for bugfix/tech-debt/infrastructure plans.

**Q: What's the difference between /validate-sprint and /sprint-complete?**
A: `/validate-sprint` is a quick validation check. `/sprint-complete` is the full TDD compliance check with alignment verification and cleanup.

**Q: When should I use --comprehensive vs --quick on /sprint-complete?**
A: Use `--quick` during development for fast feedback. Use `--comprehensive` (or no flag) for final validation before `/finalize-sprint`.

**Q: How do I fix CI failures after merge?**
A: Run `/fix-ci` which will diagnose the failure, attempt automatic fixes, and push a fix commit.

**Q: A generation command crashed/timed out. How do I continue?**
A: Use `--resume` flag: `/create-user-stories @plan/ --resume` or `/create-acceptance-criteria @plan/ --resume`. This skips files that were already generated.

**Q: What's the difference between /init-documentation and /create-documentation?**
A: `/init-documentation` scans package.json and generates docs for all dependencies (project-level). `/create-documentation` creates a documentation index for a specific plan.

---

**Next Steps:**
1. Run setup commands if not done: `/init-specs`, `/init-planning-templates`
2. Start with `/init-plan` to create your first plan
3. Follow the workflow through to `/finalize-sprint`
