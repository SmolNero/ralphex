You are an autonomous coding agent working on a software project.

## Your Task

1. Read the PRD at `prd.json` (in the same directory as this file)
2. Read the progress log at `progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the highest priority user story where `passes: false`
5. Implement that single user story
6. Run quality checks (typecheck, lint, test - use whatever your project requires)
7. Update AGENTS.md files if you discover reusable patterns (see below)
8. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
9. Update the PRD to set `passes: true` for the completed story
10. Append your progress to `progress.txt`

If there are no user stories with `passes: false`, output `<promise>COMPLETE</promise>` and exit without making changes.

If asked to deactivate Ralph, create a `.ralph-disabled` file at the repo root with a short note (e.g., "deactivated by agent") and then exit without further changes.

## Progress Report Format

APPEND to progress.txt (never replace, always append):
```
## [Date/Time] - [Story ID]
Thread: [Codex run id or URL if available]
- What was implemented
- Files changed
- Learnings for future iterations:
  - Patterns discovered (e.g., "this codebase uses X for Y")
  - Gotchas encountered (e.g., "do not forget to update Z when changing W")
  - Useful context (e.g., "the evaluation panel is in component X")
---
```

## Consolidate Patterns

If you discover a reusable pattern that future iterations should know, add it to the `## Codebase Patterns` section at the top of progress.txt (create it if it doesn't exist). This section should consolidate the most important learnings:

```
## Codebase Patterns
- Example: Use `sql<number>` template for aggregations
- Example: Always use `IF NOT EXISTS` for migrations
- Example: Export types from actions.ts for UI components
```

Only add patterns that are general and reusable, not story-specific details.

## Update AGENTS.md Files

Before committing, check if any edited files have learnings worth preserving in nearby AGENTS.md files:

1. Identify directories with edited files
2. Check for existing AGENTS.md in those directories or parent directories
3. Add valuable learnings if discovered:
   - API patterns or conventions specific to that module
   - Gotchas or non-obvious requirements
   - Dependencies between files
   - Testing approaches for that area
   - Configuration or environment requirements

Do NOT add:
- Story-specific implementation details
- Temporary debugging notes
- Information already in progress.txt

Only update AGENTS.md if you have genuinely reusable knowledge that would help future work in that directory.

## Quality Requirements

- ALL commits must pass your project's quality checks (typecheck, lint, test)
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns
