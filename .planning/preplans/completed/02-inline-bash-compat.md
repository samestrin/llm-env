# Tech Debt: Inline bash_compat.sh into llm-env

## Current State

The `llm-env` script currently relies on an external file, `lib/bash_compat.sh`, to provide associative array compatibility for older versions of Bash (specifically macOS default Bash 3.2). This file is sourced at runtime.
- **Dependency:** `lib/bash_compat.sh` (~90 lines)
- **Distribution:** Requires `install.sh` to download and place this file in a `lib/` subdirectory.
- **Claim:** The project claims "Zero Dependencies" and "Single File" usage, which is technically inaccurate due to this required library file.

## Pain Points

### Distribution Complexity
- Users cannot simply `curl -o llm-env` and run it; they must use the full installer or manually replicate the folder structure.
- The installer (`install.sh`) contains extra logic to handle downloading, verifying, and placing this secondary file.
- Moving the script requires moving the `lib/` folder with it.

### "Fake" Zero Dependency
- The "Zero Dependencies" claim is weakened by the existence of a required support library, even if it is internal to the project.
- It creates a disconnect between marketing ("Just works") and reality ("Just works... if you have the lib folder").

### Maintenance Overhead
- Logic for sourcing the file exists in multiple places (`llm-env`, `test-install.sh`).
- Versioning issues could arise if `llm-env` and `bash_compat.sh` get out of sync during manual updates.

## Evidence

### Code references:
- `llm-env` (lines 161-166): Checks for and sources `lib/bash_compat.sh`.
- `install.sh`: extensive logic to download `bash_compat.sh` to `lib/`.
- `test-install.sh`: Duplicate logic for testing installations.

## Proposed Solution

Inline the contents of `lib/bash_compat.sh` directly into the main `llm-env` script.

### Strategy
1.  **Copy** the compatibility functions (`compat_assoc_set`, `compat_assoc_get`, etc.) from `lib/bash_compat.sh`.
2.  **Paste** them into `llm-env` near the top, replacing the file existence check and `source` commands.
3.  **Remove** `lib/bash_compat.sh` from the repository.
4.  **Update** `install.sh` and `test-install.sh` to remove the download/install steps for the library file.

## Scope

### In Scope
- Modify `llm-env` to include compatibility logic.
- Delete `lib/bash_compat.sh`.
- Modify `install.sh` to remove `download_dependencies` logic.
- Modify `test-install.sh` to remove `download_dependencies` logic.
- Verify `llm-env` works on modern Bash (associative arrays native) and older Bash (using the inlined compat layer).

### Out of Scope
- Changing the actual logic of the compatibility layer (just moving it).
- Removing `curl` dependency (that is separate tech debt).

## Files Affected

| File | Change | Complexity |
|------|--------|------------|
| `llm-env` | Inline functions, remove source logic | Low |
| `lib/bash_compat.sh` | Delete | Low |
| `install.sh` | Remove download logic | Low |
| `test-install.sh` | Remove download logic | Low |

## Success Criteria

- [ ] `llm-env` runs successfully as a standalone file without a `lib/` directory.
- [ ] `lib/bash_compat.sh` is removed from the repo.
- [ ] `install.sh` no longer creates a `lib/` directory.
- [ ] All existing tests pass (Unit, Integration, System).

## Risks

| Risk | Mitigation |
|------|------------|
| Script size increase | The increase is negligible (~90 lines) compared to the benefit of portability. |
| namespace pollution | The functions are already prefixed with `compat_`, reducing collision risk. |

## Rollback Plan

Revert the git commit. The changes are purely structural (moving code), so logic errors are unlikely if the copy-paste is exact.
