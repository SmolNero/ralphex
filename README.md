# Ralph

![Ralph](ralph.webp)

Ralph is an autonomous AI agent loop that runs AI coding tools ([Amp](https://ampcode.com), [Claude Code](https://docs.anthropic.com/en/docs/claude-code), or GPT Codex) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.
Demo heartbeat: see `docs/ralph-demo.txt`.

## Prerequisites

- One of the following AI coding tools installed and authenticated:
  - [Amp CLI](https://ampcode.com) (default)
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`npm install -g @anthropic-ai/claude-code`)
  - GPT Codex CLI or wrapper (configure via `CODEX_CMD`)
    - Install: `npm install -g @openai/codex`
    - Authenticate (Codex Pro): `codex login`
    - Authenticate (API key): `printenv OPENAI_API_KEY | codex login --with-api-key`
    - Auto-login support: if `OPENAI_API_KEY` is set, `ralph.sh` will attempt a login automatically
    - External auth (e.g., OpenCode): set `CODEX_SKIP_LOGIN_CHECK=1`
    - OpenCode fallback: set `CODEX_DRIVER=opencode` to use OpenCode OAuth
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

### Option 1: Copy to your project

Copy the ralph files into your project:

```bash
# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/

# Copy the prompt template for your AI tool of choice:
cp /path/to/ralph/prompt.md scripts/ralph/prompt.md    # For Amp
# OR
cp /path/to/ralph/CLAUDE.md scripts/ralph/CLAUDE.md    # For Claude Code
# OR
cp /path/to/ralph/CODEX.md scripts/ralph/CODEX.md      # For GPT Codex

chmod +x scripts/ralph/ralph.sh
```

### Option 2: Install skills globally (Amp)

Copy the skills to your Amp or Claude config for use across all projects:

For AMP
```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

For Claude Code (manual)
```bash
cp -r skills/prd ~/.claude/skills/
cp -r skills/ralph ~/.claude/skills/
```

### Option 3: Use as Claude Code Marketplace

Add the Ralph marketplace to Claude Code:

```bash
/plugin marketplace add snarktank/ralph
```

Then install the skills:

```bash
/plugin install ralph-skills@ralph-marketplace
```

Available skills after installation:
- `/prd` - Generate Product Requirements Documents
- `/ralph` - Convert PRDs to prd.json format

Skills are automatically invoked when you ask Claude to:
- "create a prd", "write prd for", "plan this feature"
- "convert this prd", "turn into ralph format", "create prd.json"

### Configure Amp auto-handoff (recommended)

Add to `~/.config/amp/settings.json`:

```json
{
  "amp.experimental.autoHandoff": { "context": 90 }
}
```

This enables automatic handoff when context fills up, allowing Ralph to handle large stories that exceed a single context window.

## Quick Start: GPT Codex + OpenCode (Smol Budget Edition)

If you are building on a tight budget, this is the fastest path with minimal setup. OpenCode handles OAuth so you do not need API keys.

1. Copy these files into your project root:
   - `ralph.sh`
   - `ralphcodex`
   - `CODEX.md`
2. Make the wrapper executable:
   - `chmod +x ralphcodex`
3. Log in once with OpenCode:
   - `opencode auth login`
4. Add a `prd.json` to your project root.
5. Run:
   - `./ralphcodex`

Ralph will print the ASCII banner, then run until all stories pass.

## What We Built (Walkthrough)

- **Codex loop with OpenCode fallback**: `ralph.sh` uses the Codex CLI when logged in, and falls back to OpenCode OAuth when not.
- **One-command runner**: `./ralphcodex` defaults to `CODEX_DRIVER=opencode` and `CODEX_MODEL=openai/gpt-5.2-codex`.
- **Active/Deactivated banner**: Ralph prints a big ASCII banner with `ACTIVE 🟢` or `DEACTIVATED 🔴`.
- **Deactivation switch**: `./ralphcodex off` creates `.ralph-disabled`; `./ralphcodex on` removes it; `./ralphcodex status` reports state.
- **Clean exit when done**: if no stories remain, Codex emits `<promise>COMPLETE</promise>` and the loop stops.

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Load the prd skill and create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
# One-command Codex loop (OpenCode OAuth by default)
./ralphcodex [max_iterations]

# Toggle Ralph on/off
./ralphcodex off
./ralphcodex on
./ralphcodex status

# Using Amp (default)
./scripts/ralph/ralph.sh [max_iterations]

# Using Claude Code
./scripts/ralph/ralph.sh --tool claude [max_iterations]

# Using GPT Codex (set CODEX_CMD if needed)
CODEX_CMD="codex" ./scripts/ralph/ralph.sh --tool codex [max_iterations]

# Bootstrap from example PRD (for demos only):
PRD_BOOTSTRAP=1 ./scripts/ralph/ralph.sh [max_iterations]
```

Default is 10 iterations. Use `--tool amp`, `--tool claude`, or `--tool codex` to select your AI coding tool.

For Codex, set `CODEX_CMD` to the command that accepts prompt text on stdin, for example:

```bash
CODEX_CMD="codex exec --dangerously-bypass-approvals-and-sandbox" ./scripts/ralph/ralph.sh --tool codex

# If your environment already manages auth (e.g., OpenCode), bypass the login check:
CODEX_SKIP_LOGIN_CHECK=1 ./scripts/ralph/ralph.sh --tool codex

# Use OpenCode as the Codex driver (uses OpenAI OAuth):
CODEX_DRIVER=opencode CODEX_MODEL="openai/gpt-5.2-codex" ./scripts/ralph/ralph.sh --tool codex
```

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

If `prd.json` is missing, `ralph.sh` will exit with instructions. To auto-copy the example, set `PRD_BOOTSTRAP=1`.

## Deactivate Ralph

To pause the loop (useful if you want GPT Codex to stop running Ralph):

```bash
# Create a flag file to deactivate
touch .ralph-disabled

# Or set an env var for a single run
RALPH_DISABLED=1 ./ralph.sh
```

When deactivated, Ralph prints a banner and exits. To override:

```bash
RALPH_FORCE=1 ./ralph.sh
```

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop that spawns fresh AI instances (supports `--tool amp`, `--tool claude`, or `--tool codex`) |
| `prompt.md` | Prompt template for Amp |
| `CLAUDE.md` | Prompt template for Claude Code |
| `CODEX.md` | Prompt template for GPT Codex |
| `prd.json` | User stories with `passes` status (the task list) |
| `prd.json.example` | Example PRD format for reference |
| `progress.txt` | Append-only learnings for future iterations |
| `skills/prd/` | Skill for generating PRDs (works with Amp and Claude Code) |
| `skills/ralph/` | Skill for converting PRDs to JSON (works with Amp and Claude Code) |
| `.claude-plugin/` | Plugin manifest for Claude Code marketplace discovery |
| `flowchart/` | Interactive visualization of how Ralph works |

## Flowchart

[![Ralph Flowchart](ralph-flowchart.png)](https://snarktank.github.io/ralph/)

**[View Interactive Flowchart](https://snarktank.github.io/ralph/)** - Click through to see each step with animations.

The `flowchart/` directory contains the source code. To run locally:

```bash
cd flowchart
npm install
npm run dev
```

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new AI instance** (Amp or Claude Code) with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### AGENTS.md Updates Are Critical

After each iteration, Ralph updates the relevant `AGENTS.md` files with learnings. This is key because AI coding tools automatically read these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to AGENTS.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser using dev-browser skill" in acceptance criteria. Ralph will use the dev-browser skill to navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```bash
# See which stories are done
cat prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat progress.txt

# Check git history
git log --oneline -10
```

## Customizing the Prompt

After copying `prompt.md` (for Amp) or `CLAUDE.md` (for Claude Code) to your project, customize it for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## References

- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
- [Amp documentation](https://ampcode.com/manual)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
