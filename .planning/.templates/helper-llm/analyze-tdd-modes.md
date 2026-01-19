# TDD Mode Analysis Task

Analyze user stories and calculate TDD mode for each based on criticality scoring.

## Task

For each user story file in [[PLAN_PATH]]user-stories/, analyze content and calculate TDD mode.

## Scoring Rules

1. Base score = (number of acceptance criteria) * 2
2. Add 8 points if story contains: authenticat, authorization, security, permission, access control, encrypt, decrypt, payment, transaction, financial, billing, gdpr, compliance, audit, pii, privacy, sensitive
3. Add 5 points if story contains: api, external, integration, third party, webhook, oauth, saml
4. Add 3 points if story contains: schema, migration, database, table, index, constraint, query
5. Add 3 points if story contains: user data, personal, confidential, protected

## TDD Mode Assignment

- Score >= 10: strict
- Score >= 5: moderate
- Score < 5: pragmatic

## Required Output Format

Output pipe-delimited data with one story per line. Include a header row.

**Format:**
```
FILENAME|SCORE|MODE|TITLE
01-user-authentication|15|strict|User Authentication System
02-user-profile|6|moderate|User Profile Management
03-ui-polish|3|pragmatic|UI Polish and Refinements
```

**Column definitions:**
- FILENAME: Story filename without extension (e.g., `01-user-authentication`)
- SCORE: Calculated criticality score (integer)
- MODE: TDD mode (`strict`, `moderate`, or `pragmatic`)
- TITLE: Story title from the file

**OUTPUT ONLY THE PIPE-DELIMITED DATA WITH HEADER ROW - NO OTHER TEXT, NO BASH COMMANDS**

---

## Input Data

**User Stories Directory**: [[PLAN_PATH]]user-stories/
**Acceptance Criteria Directory**: [[PLAN_PATH]]acceptance-criteria/

Count AC files per story by matching pattern: [[PLAN_PATH]]acceptance-criteria/STORYNUM-*.md
