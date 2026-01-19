# Pattern: AC → Test Scenarios

Convert acceptance criteria into GIVEN/WHEN/THEN test scenarios for better test structure.

## Input

- AC_CONTENT: The acceptance criteria text (markdown format with checkboxes or bullet points)

## Output Format

One scenario per line in pipe-delimited format:

```
GIVEN <precondition>|WHEN <action>|THEN <expected outcome>
```

## Prompt

Convert these acceptance criteria into GIVEN/WHEN/THEN test scenarios.

Rules:
- One scenario per line
- Format: GIVEN <precondition>|WHEN <action>|THEN <expected outcome>
- Be specific about inputs and expected outputs
- Include edge cases where implied by the criteria
- Do NOT add commentary or explanations

Acceptance Criteria:
[[AC_CONTENT]]

## Example

**Input:**
```markdown
- [ ] User can enter email address
- [ ] System validates email format
- [ ] Error shown for invalid email
- [ ] Submit button disabled until valid
```

**Output:**
```
GIVEN user is on the registration form|WHEN user enters a valid email address|THEN the email field accepts the input
GIVEN user has entered text in email field|WHEN the text is not a valid email format|THEN system displays email format error message
GIVEN user has entered invalid email|WHEN viewing the form|THEN submit button is disabled
GIVEN user corrects email to valid format|WHEN validation runs|THEN submit button becomes enabled
```
