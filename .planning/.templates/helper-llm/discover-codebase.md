# Codebase Discovery for Planning

You are analyzing a codebase to discover existing implementations relevant to a planned feature or change.

## Request Summary

[[REQUEST_SUMMARY]]

## Search Results

The following code was found in the codebase matching relevant keywords:

[[SEARCH_RESULTS]]

## Analysis Task

Based on the search results, provide a structured analysis of what already exists in the codebase.

**OUTPUT FORMAT (JSON):**

```json
{
  "existing_implementations": [
    {
      "name": "functionOrClassName",
      "type": "function|class|module|component",
      "location": "path/to/file.ts:lineNumber",
      "purpose": "Brief description of what it does",
      "relevance": "high|medium|low",
      "reuse_recommendation": "extend|modify|replace|reference"
    }
  ],
  "patterns_detected": [
    {
      "pattern": "Name of pattern (e.g., 'Singleton Logger', 'Event-driven')",
      "locations": ["file1.ts", "file2.ts"],
      "recommendation": "How new code should align with this pattern"
    }
  ],
  "dependencies_found": [
    {
      "name": "package-name",
      "usage": "How it's currently used",
      "relevant_to_plan": true
    }
  ],
  "build_from": {
    "primary_file": "path/to/main/file.ts",
    "reason": "Why this is the starting point",
    "existing_functions": ["func1", "func2"],
    "suggested_approach": "Extend existing implementation | Add to existing module | Create new module that integrates with..."
  },
  "warnings": [
    "Any concerns about the existing code that should inform the plan"
  ]
}
```

**IMPORTANT:**
- Only include items with HIGH or MEDIUM relevance
- Focus on what can be REUSED or EXTENDED, not replaced
- If no relevant code exists, return empty arrays and set build_from to null
- Be specific about file paths and line numbers

**OUTPUT ONLY THE JSON - NO OTHER TEXT**
