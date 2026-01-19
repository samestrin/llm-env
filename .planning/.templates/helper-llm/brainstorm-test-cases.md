# Pattern: Test Case Brainstorming

## Input
- FUNCTION_SIGNATURE: The function/method signature
- CONTEXT_NAME: Class, module, or file name containing the function
- IMPORTS: Key imports or dependencies (optional)
- PURPOSE: Brief description of what the function does

## Output Format
One test case per line:
```
CATEGORY|DESCRIPTION
```

Categories: boundary, error, empty, null, concurrent, security, performance

## Prompt

Brainstorm 5-7 edge case test scenarios for this function.

Function: [[FUNCTION_SIGNATURE]]
Context: [[CONTEXT_NAME]]
Imports: [[IMPORTS]]
Purpose: [[PURPOSE]]

Focus on cases developers commonly miss:
- Boundary conditions (min/max, off-by-one)
- Error states (network failures, timeouts, invalid input)
- Empty/null/undefined inputs
- Concurrent access issues
- Security edge cases (if applicable)

Output format: CATEGORY|DESCRIPTION (one per line)

Categories: boundary, error, empty, null, concurrent, security, performance

Be specific to THIS function's domain. Avoid generic test cases.

## Example

Input:
```
Function: async validateToken(token: string): Promise<User | null>
Context: AuthService
Imports: jwt, database
Purpose: Validates JWT token and returns user if valid
```

Output:
```
boundary|Token that expires exactly at current timestamp (edge of validity window)
error|Database connection fails mid-validation after JWT is decoded
null|Token string is empty string (not null, but zero-length)
security|Token signed with different secret key (key rotation scenario)
error|JWT decode succeeds but user ID doesn't exist in database
boundary|Token with claims that exceed maximum allowed size
concurrent|Same token validated simultaneously from multiple requests
```
