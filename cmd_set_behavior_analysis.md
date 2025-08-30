# cmd_set Expected Behavior Analysis

## Current cmd_set Function Behavior

### Success Conditions
1. **Provider exists** in configuration (built-in or user-defined)
2. **API key is set** in environment (`LLM_{PROVIDER}_API_KEY`)
3. **Provider validation** passes (valid name format, enabled status)

### Failure Conditions
1. **Invalid provider name** - Returns status 1, shows validation error
2. **Provider not found** - Returns status 1, shows "Unknown provider" error
3. **Missing API key** - Returns status 1, shows warning message

### Current Implementation Analysis

**Lines 463-469 in llm-env:**
```bash
if [[ -z "$key_var" ]]; then
    echo "❌ Invalid provider configuration: missing API key variable for $provider"
    return 1
elif [[ -z "$key" ]]; then
    echo "⚠️  No API key found for $provider. Set $key_var in your shell profile."
    return 1
fi
```

**Issue Identified:** cmd_set returns status 1 when API key is missing, but test expects status 0.

## Built-in Provider Configuration

### OpenAI Provider (Built-in)
- **Provider Name:** `openai`
- **Base URL:** `https://api.openai.com/v1` 
- **API Key Variable:** `LLM_OPENAI_API_KEY`
- **Default Model:** `gpt-5-2025-08-07`
- **Status:** Enabled by default

## Test Design Flaw Analysis

### Current Test Expectations (Lines 116-132)
```bash
@test "provider operations: set provider works in both modes" {
    # Test with native arrays (bash 4.0+)
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='true'
        source $BATS_TEST_DIRNAME/../../llm-env set openai
    "
    [ "$status" -eq 0 ]          # ❌ INCORRECT - Expects success without API key
    [[ "$output" =~ "openai" ]]  # ✅ CORRECT - Output should contain provider name
    
    # Test with compatibility arrays (bash 3.2)
    run bash -c "
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env set openai  
    "
    [ "$status" -eq 0 ]          # ❌ INCORRECT - Expects success without API key
    [[ "$output" =~ "openai" ]]  # ✅ CORRECT - Output should contain provider name
}
```

### Design Problems
1. **Missing API Key Setup:** Test doesn't configure required `LLM_OPENAI_API_KEY`
2. **Wrong Status Expectation:** Expects status 0 when cmd_set should fail without API key
3. **Insufficient Environment:** Subshell execution may not preserve environment variables

## Correct cmd_set Behavior Specification

### With API Key Present
- **Status:** 0 (success)
- **Output:** `✅ Set: provider=openai host=api.openai.com model=gpt-5-2025-08-07 key=••••••••••••••••••••••••••••••••••••••••••••••••••••15xO`
- **Environment Variables Set:** `LLM_PROVIDER`, `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`

### Without API Key Present  
- **Status:** 1 (failure)
- **Output:** `⚠️  No API key found for openai. Set LLM_OPENAI_API_KEY in your shell profile.`
- **Environment Variables:** Not modified

## Required Test Corrections

### Option 1: Fix Test Environment (Recommended)
```bash
@test "provider operations: set provider works in both modes" {
    # Test with native arrays (bash 4.0+)
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        export BASH_ASSOC_ARRAY_SUPPORT='true'
        source $BATS_TEST_DIRNAME/../../llm-env set openai
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
    
    # Test with compatibility arrays (bash 3.2)
    run bash -c "
        export LLM_OPENAI_API_KEY='test-key-12345'
        export BASH_ASSOC_ARRAY_SUPPORT='false'
        source $BATS_TEST_DIRNAME/../../llm-env set openai
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ "openai" ]]
}
```

### Option 2: Update Test Expectations (Alternative)
```bash
# Change expectations to match current failure behavior
[ "$status" -eq 1 ]
[[ "$output" =~ "No API key found for openai" ]]
```

## Recommendation

**Adopt Option 1** - Fix the test environment by providing required API key. This tests the intended successful operation of cmd_set rather than testing failure conditions.

The cmd_set function is designed to succeed when properly configured, so the test should provide proper configuration to validate successful operation across both array modes.