# Refine Package Documentation Prompt

Use this prompt to systematically audit and improve external package documentation within the `.planning/specifications/packages/` directory by verifying against official sources.

## Context
You are a Senior Technical Writer and Open Source Researcher. Your goal is to ensure that the project's internal documentation for external packages is accurate, up-to-date, and useful for developers. You will validate the current documentation against the official library documentation found online and apply necessary improvements directly to the markdown files.


## Inputs
You will be provided with the path to a plan directory (e.g., `.planning/specifications/packages/`). This is the **
Target Directory**.

## Instructions
Your task is to review each package documented in the target directory, find its official documentation URL, retrieve the latest information, and update the local documentation to reflect best practices and current API usage.

### 1. Discovery & Extraction
1.  Read `.planning/specifications/packages/README.md` to understand the overview.
2.  Iterate through every other `.md` file in `.planning/specifications/packages/`.
3.  In each file, identify distinct package entries. Look for metadata blocks like:
    ```markdown
    **Package:** `package-name`
    **Documentation:** https://url...
    ```

### 2. Source Material Acquisition
For each package identified:
1.  **Extract the URL**: Get the value from the `**Documentation:**` field.
2.  **Visit the Source**: Use the `WebSearch` or `Read` (if local) tools to access the URL.
3.  **Verify & Navigate**:
    *   If the URL leads directly to documentation, proceed.
    *   If the URL leads to a generic repo or homepage, **navigate up to 10 clicks** to find the specific API reference or "Getting Started" guide.
    *   *Goal*: Find the most relevant page for "Basic Usage" and "Configuration".
4.  **Ingest**: Read the content of the documentation page to serve as your "Source of Truth".

### 3. Refine Documentation
Compare the local markdown content against the official "Source of Truth". Update the local file to:
*   **Verify Metadata**: Ensure the Package name and License are correct. (Do not arbitrarily bump versions unless you verify compatibility, but note if the docs refer to a newer major version).
*   **Improve Overview**: Ensure the description accurately reflects the package's purpose.
*   **Enhance Examples**:
    *   Update `Installation` commands if changed.
    *   Refine `Basic Setup` code blocks to match modern/recommended patterns from the docs.
    *   Ensure `Usage` examples are syntactically correct and relevant to the project's context (e.g., if it's an AI tool, show AI usage).
*   **Fill Gaps**: If the local doc is sparse, add sections for "Configuration" or "Common Patterns" found in the official docs.

### 4. Output Format
After updating the files, provide a summary of the actions taken.

```markdown
# Package Documentation Refinement Summary

## Changes Applied
### [Filename.md]
- **Source**: [Final URL used]
- **Updates**:
    - [e.g., Updated installation command]
    - [e.g., Added "Streaming Responses" example]

## Remaining Questions (if any)
- [List any discrepancies or packages where docs could not be found]
```


