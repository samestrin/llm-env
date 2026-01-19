# Extract Search Keywords for Codebase Discovery

You are analyzing a feature request to extract keywords for searching an existing codebase.

## Request

[[REQUEST_CONTENT]]

## Task

Extract keywords and patterns to search for existing relevant code.

**OUTPUT FORMAT (one item per line, no bullets or formatting):**

```
FUNCTIONS: functionName1 functionName2 functionName3
CLASSES: ClassName1 ClassName2
MODULES: moduleName directory/path
PATTERNS: regex1 regex2
CONCEPTS: concept1 concept2 concept3
```

**Guidelines:**
- FUNCTIONS: Likely function names (camelCase, snake_case variations)
- CLASSES: Likely class/type names (PascalCase)
- MODULES: Directory or file names to look for
- PATTERNS: Regex patterns for grep (e.g., "log.*Performance", "handle.*Error")
- CONCEPTS: General terms to search (e.g., "logging", "cache", "auth")

**Example for "optimize logging performance":**
```
FUNCTIONS: logPerformance log performance logMetrics trackPerformance
CLASSES: Logger PerformanceLogger LogManager
MODULES: logging logger performance metrics utils/log
PATTERNS: log.*[Pp]erformance performance.*[Ll]og
CONCEPTS: logging performance metrics telemetry
```

**OUTPUT ONLY THE KEYWORD LINES - NO OTHER TEXT**
