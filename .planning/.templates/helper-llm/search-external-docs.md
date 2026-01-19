# Search External Documentation Task

Find official documentation URLs for the given technologies.

## Technologies to Search

[[TECHNOLOGIES]]

## Task

For each technology listed above, find the OFFICIAL documentation URL.

Search priorities:
1. Official documentation site (e.g., docs.example.com)
2. Official GitHub repository README or docs folder
3. Official API reference
4. Well-maintained community documentation (e.g., MDN for web standards)

Avoid:
- Tutorial sites (Medium, Dev.to, etc.)
- Stack Overflow answers
- Outdated documentation
- Marketing pages (use /docs not homepage)

## Required Output Format

Output ONLY in this pipe-delimited format:

```
NAME|DESCRIPTION|URL|SCORE
zod|TypeScript schema validation library|https://zod.dev|95
drizzle-orm|TypeScript ORM for SQL databases|https://orm.drizzle.team/docs/overview|90
tanstack-query|Async state management for React|https://tanstack.com/query/latest/docs/framework/react/overview|85
```

**Format Rules:**
- NAME: Technology name (lowercase, match input)
- DESCRIPTION: One-line description (no pipes)
- URL: Direct link to documentation (not homepage unless docs)
- SCORE: 0-100 relevance score based on:
  - 90-100: Official primary docs
  - 70-89: Official but secondary (GitHub, API ref)
  - 50-69: Community maintained
  - Below 50: Omit entirely

**IMPORTANT:**
- Output ONLY the pipe-delimited lines
- NO header row, NO explanations
- Skip any technology with score < 50
- One line per technology
