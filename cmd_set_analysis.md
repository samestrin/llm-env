## cmd_set Variable Assignment Analysis

### Issue Summary
Test `cmd_set: sets provider environment variables` fails with error message:
```
⚠️  No API key found for test_provider. Set  in your shell profile.
```

Notice the empty variable name after "Set " - this indicates `key_var` is empty.

### Root Cause Investigation

**Test Configuration:**
```ini
[test_provider]
base_url=https://api.example.com/v1
api_key_var=LLM_TEST_API_KEY
default_model=test-model-v1
description=Test provider for integration tests
enabled=true
```

**Code Flow in cmd_set (line 438):**
```bash
key_var="$(get_provider_value "PROVIDER_API_KEY_VARS" "$provider")"
```

**Problem:** The config uses field name `api_key_var` but the code looks for `PROVIDER_API_KEY_VARS` array.

### Array Name Mapping Issue
The configuration loading needs to map:
- `api_key_var` field → `PROVIDER_API_KEY_VARS` array
- `base_url` field → `PROVIDER_BASE_URLS` array  
- `default_model` field → `PROVIDER_DEFAULT_MODELS` array

### Analysis Required
1. **Configuration Loading**: Check where config fields are parsed and loaded into arrays
2. **Array Names**: Verify the correct array name mapping  
3. **get_provider_value**: Test if it returns values correctly for existing providers
4. **compat_assoc_get**: Check compatibility layer behavior

### Expected Fix
Either:
1. Fix the array name mapping during config loading
2. Fix the array name used in get_provider_value calls
3. Ensure proper error handling when key_var is empty

### Test Environment
- BATS helper now loads correctly (symlink created)
- Test creates config file in isolated temp directory
- Script sources after config creation - timing may be factor