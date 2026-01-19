# TDD Workflow Guide

This guide explains the complete TDD sprint workflow with command sequences and best practices.

## Quick Reference

### Commands by Category

**Setup (One-Time):**
- `/init-planning-templates` - Download planning templates from repository
- `/init-specs [--language <lang>] [--framework <fw>]` - Generate project specifications

**Documentation:**
- `/init-documentation [--update] [--include-transitive ] [--packages <packages>]` - Generate base documentation

**Planning:**
- `/init-plan [description or @file]` - Create TDD implementation plan
- `/find-documentation @plan/folder/` - Identify relevant specifications
- `/create-documentation @plan/folder/ @docs...` - Extract and organize documentation
- `/create-user-stories @plan/folder/` - Generate user stories (feature plans)
- `/create-tasks @plan/folder/` - Generate tasks (non-feature plans)
- `/create-acceptance-criteria @plan/folder/` - Generate acceptance criteria
- `/design-sprint @plan/folder/` - Analyze and design sprint
- `/create-sprint @plan/folder/` - Generate executable sprint plan

**Execution:**
- `/execute-sprint @sprint/folder/` - Run sprint implementation
- `/validate-sprint @sprint/folder/` - Validate sprint before execution

**Quality & Validation:**
- `/code-review @sprint/folder/ [--user-stories] [--run-tests]` - Automated code review
- `/sprint-complete @sprint/folder/` - TDD compliance and alignment check

**Finalization:**
- `/finalize-sprint` - Commit artifacts, merge PR, return to main

**Frontend Testing:**
- `/create-frontend-tests @sprint/folder/` - Generate frontend test plan
- `/execute-frontend-tests @test-plan.md` - Run frontend tests via browser

**Utility:**
- `/help-workflow [--refresh]` - Display this guide

---

## Main Workflow: Full TDD Planning

### Feature Plans (User Stories)

```
Step 1: Initialize Plan
├─> /init-plan "detailed requirement description"
│   Output: .planning/plans/X.X_name/ with plan.md, original-requirements.md
│
Step 2: Create Documentation Index (Optional)
├─> /find-documentation @.planning/plans/X.X_name/
├─> /create-documentation @.planning/plans/X.X_name/ @specs...
│   Output: documentation/ folder with ranked resources
│
Step 3: Generate User Stories
├─> /create-user-stories @.planning/plans/X.X_name/
│   Output: user-stories/ folder with individual story files
│
Step 4: Add Acceptance Criteria
├─> /create-acceptance-criteria @.planning/plans/X.X_name/
│   Output: acceptance-criteria/ folder with criteria files
│
Step 5: Design Sprint
├─> /design-sprint @.planning/plans/X.X_name/
│   Output: sprint-design.md with complexity analysis
│
Step 6: Create Sprint Plan
├─> /create-sprint @.planning/plans/X.X_name/
│   Output: .planning/sprints/active/X.X_name/ with sprint-plan.md
│
Step 7: Execute Sprint
├─> /execute-sprint @.planning/sprints/active/X.X_name/
│   Output: Code changes, test updates, checkmarks in sprint-plan.md
│
Step 8: Code Review
├─> /code-review @.planning/sprints/active/X.X_name/ --user-stories --run-tests
│   Output: code-review.md with evidence
│
Step 9: Sprint Complete
├─> /sprint-complete @.planning/sprints/active/X.X_name/
│   Output: sprint-complete.md with TDD compliance, alignment check
│
Step 10: Finalize Sprint
└─> /finalize-sprint
    Output: Merged PR, clean main branch
```

### Non-Feature Plans (Tasks)

For bugfix, tech-debt, test-remediation, infrastructure plans:

```
Step 1: Initialize Plan
├─> /init-plan "bugfix: description" (or tech-debt:, test-remediation:, infrastructure:)
│
Step 2: Generate Tasks (Skip user stories)
├─> /create-tasks @.planning/plans/X.X_name/
│   Output: tasks/ folder with task files
│
Step 3: Design Sprint
├─> /design-sprint @.planning/plans/X.X_name/
│
Step 4: Create Sprint Plan
├─> /create-sprint @.planning/plans/X.X_name/
│
Step 5-8: Execute → Code Review → Sprint Complete → Finalize
    (Same as feature workflow)
```

---

## Visual Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        PLANNING PHASE                        │
└─────────────────────────────────────────────────────────────┘
                               │
                               v
                       ┌─────────────┐
                       │  init-plan  │
                       └──────┬──────┘
                              │
                              v
                       ┌─────────────┐
                       │    find-    │
                       │documentation│ (optional)
                       └──────┬──────┘
                              │
                              v
                       ┌─────────────┐
                       │   create-   │
                       │documentation│ (optional)
                       └──────┬──────┘
                              │
          ┌───────────────────┴───────────────────┐
          │                                       │
          v (feature)                             v (non-feature)
   ┌─────────────┐                         ┌─────────────┐
   │create-user- │                         │create-tasks │
   │  stories    │                         └──────┬──────┘
   └──────┬──────┘                                │
          │                                       │
          v                                       │
   ┌─────────────┐                                │
   │create-      │                                │
   │acceptance-  │                                │
   │criteria     │                                │
   └──────┬──────┘                                │
          │                                       │
          └───────────────────┬───────────────────┘
                              │
                              v
                       ┌─────────────┐
                       │design-sprint│
                       └──────┬──────┘
                              │
                              v
                       ┌─────────────┐
                       │create-sprint│
                       └──────┬──────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                      EXECUTION PHASE                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              v
                       ┌─────────────┐
                       │execute-     │
                       │  sprint     │
                       └──────┬──────┘
                              │
┌─────────────────────────────┴───────────────────────────────┐
│                    VALIDATION PHASE                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              v
                       ┌─────────────┐
                       │ code-review │
                       │--user-stories│
                       │--run-tests  │
                       └──────┬──────┘
                              │
                              v
                       ┌─────────────┐
                       │  sprint-    │
                       │  complete   │
                       └──────┬──────┘
                              │
                              v
                       ┌─────────────┐
                       │ finalize-   │
                       │   sprint    │
                       └─────────────┘
                              │
                              v
                        ✅ Done!
```

---

## Best Practices

### 1. Use the Full Validation Flow
```bash
/execute-sprint @sprint/
/code-review @sprint/ --user-stories --run-tests
/sprint-complete @sprint/
/finalize-sprint
```

### 2. Plan Before You Code
Complete all planning steps (init-plan through create-sprint) before executing.

### 3. Use Correct Plan Type
- Feature work → user stories + acceptance criteria
- Bugfix/tech-debt → tasks only (skip user stories/AC)

### 4. Validate Before Finalize
Always run `/code-review` and `/sprint-complete` before `/finalize-sprint`.

### 5. Keep original-requirements.md as Source of Truth
All planning artifacts should align with original-requirements.md.

---

## Command Argument Reference

| Command | Required | Optional |
|---------|----------|----------|
| `/init-plan` | description or @file | - |
| `/find-documentation` | @plan/folder/ | - |
| `/create-documentation` | @plan/folder/, @docs... | - |
| `/create-user-stories` | @plan/folder/ | --max-parallel=N |
| `/create-tasks` | @plan/folder/ | --max-parallel=N |
| `/create-acceptance-criteria` | @plan/folder/ | --max-parallel=N |
| `/design-sprint` | @plan/folder/ | - |
| `/create-sprint` | @plan/folder/ | --tdd-strict, --tdd-pragmatic |
| `/validate-sprint` | @sprint/folder/ | - |
| `/execute-sprint` | @sprint/folder/ | - |
| `/code-review` | @sprint/folder/ | --user-stories, --run-tests, --run-regression, --dry-run |
| `/sprint-complete` | @sprint/folder/ | --comprehensive, --dry-run |
| `/finalize-sprint` | - | --dry-run, --no-merge |
| `/create-frontend-tests` | @sprint/folder/ | - |
| `/execute-frontend-tests` | @test-plan.md | TC-XX through TC-YY, --capture, --detail |

---

## Directory Structure

```
.planning/
├── .config/                              # Configuration
│   ├── helper_script                     # Path to llm-support tool
│   ├── helper_llm                        # LLM for helper tasks (gemini)
│   └── max_lines                         # Compression threshold
├── .templates/                           # Downloaded templates
├── specifications/                       # Project specs
├── plans/
│   └── X.X_name/
│       ├── plan.md                       # From /init-plan
│       ├── original-requirements.md           # Source of truth
│       ├── metadata.md                   # Plan metadata
│       ├── sprint-design.md              # From /design-sprint
│       ├── documentation/                # From /create-documentation
│       ├── user-stories/                 # From /create-user-stories
│       ├── tasks/                        # From /create-tasks
│       └── acceptance-criteria/          # From /create-acceptance-criteria
│
└── sprints/
    ├── active/
    │   └── X.X_name/
    │       ├── sprint-plan.md            # From /create-sprint
    │       ├── YYYY-MM-DD_code-review.md # From /code-review
    │       ├── YYYY-MM-DD_sprint-complete.md # From /sprint-complete
    │       └── plan/ -> ../../plans/X.X_name/
    └── completed/                        # Moved after /finalize-sprint
```

---

**Next Steps:**
1. Run `/init-planning-templates` to download templates
2. Run `/init-specs` to configure your project
3. Run `/init-plan` to start your first TDD sprint!
