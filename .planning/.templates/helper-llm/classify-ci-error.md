# Classify CI Error

Classify this CI failure log into a category and suggest a fix approach.

## Input

CI failure log content.

## Output Format

```
CATEGORY|REASON|SUGGESTED_FIX
```

Where CATEGORY is one of:
- `lint` - ESLint, Prettier, formatting errors
- `type` - TypeScript type errors, tsc failures
- `test` - Test failures, assertion errors
- `build` - Webpack, Vite, esbuild, module resolution
- `dependency` - npm/yarn/pnpm errors, peer deps, lockfile
- `unknown` - Cannot determine category

## Examples

Input: "error TS2322: Type 'string' is not assignable to type 'number'"
Output: `type|TypeScript type mismatch|Fix type annotations or casting`

Input: "FAIL src/auth.test.ts - Expected 200 but received 401"
Output: `test|Authentication test failing|Check auth mock setup or credentials`

Input: "Module not found: Can't resolve './components/Button'"
Output: `build|Missing module import|Check file path and exports`

## Prompt

Analyze this CI failure log and classify it:

```
[[CI_LOG]]
```

**Output ONLY the single line in format:** `CATEGORY|REASON|SUGGESTED_FIX`
