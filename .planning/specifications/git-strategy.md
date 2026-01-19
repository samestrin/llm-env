## Git Strategy

#### Branching Strategy

###### Main Branches

- **`main`**: Production-ready scripts.
  - Always stable.
  - Protected branch.
  - Tagged with semantic versions (e.g., `v1.0.0`).

- **`develop`** (optional): Integration branch.

###### Feature Branches

- **Format**: `feature/<issue-id>-<short-description>`
- **Examples**:
  - `feature/42-backup-script`
  - `feature/101-add-logging`

###### Other Branch Types

- **`bugfix/<issue-id>-<description>`**
- **`hotfix/<issue-id>-<description>`**
- **`refactor/<description>`**
- **`docs/<description>`**

---

#### Commit Message Format

Use Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

###### Types

- **feat**: New script or function
- **fix**: Bug fix in script
- **refactor**: Code restructuring (no behavior change)
- **test**: Adding or updating bats tests
- **docs**: Documentation updates (README, comments)
- **style**: Formatting changes (shfmt)
- **chore**: Maintenance (updating .gitignore, CI config)
- **ci**: CI/CD pipeline changes

###### TDD Commit Pattern

- **RED**: `test: add failing bats test for [behavior]`
- **GREEN**: `feat: implement [behavior]`
- **REFACTOR**: `refactor: improve [function] logic`

---

#### Pull Request Process

###### Creating PRs

1. **Lint First**: Ensure `shellcheck` passes locally.
2. **Format**: Run `shfmt -w .`
3. **Test**: Ensure `bats` tests pass.
4. **Description**: Explain changes and provide usage examples.

###### Review Guidelines

- **Safety**: Check for unquoted variables and lack of error handling (`set -e`).
- **Clarity**: Are variable names descriptive?
- **Idempotency**: Will this break if run twice?

---

#### Workflow Summary

###### Standard Feature Workflow

```bash
## 1. Create feature branch
git checkout main
git pull origin main
git checkout -b feature/1.0-backup-logic

## 2. Make changes with TDD
## RED: Write failing test
git add tests/
git commit -m "test: add failing test for backup rotation"

## GREEN: Make test pass
git add bin/backup.sh
git commit -m "feat(backup): implement rotation logic"

## REFACTOR: Improve code
git add bin/backup.sh
git commit -m "refactor(backup): extract cleanup function"

## 3. Push and create PR
git push -u origin feature/1.0-backup-logic
```

---

#### Best Practices

- **Atomic Commits**: Group related changes.
- **Executable Bits**: Ensure scripts have `chmod +x` before committing (`git update-index --chmod=+x script.sh`).
- **No Hardcoded Secrets**: Use environment variables.
- **Ignore Temporary Files**: Ensure `.gitignore` includes temp files, logs, and OS artifacts.
