# Ralph Agent Instructions

## Overview

Ralph is an autonomous GPT Codex loop for ChatGPT Pro accounts, tuned for budget-friendly iterations. Each iteration is a fresh instance with clean context.

## Commands

```bash
# Run the flowchart locally
cd flowchart && python3 -m http.server 5173

# Run Ralph (codex only, infinite by default)
./ralph.sh [max_iterations]

# Run Ralph with GPT Codex (explicit)
./ralph.sh --tool codex [max_iterations]
```

## Key Files

- `ralph.sh` - The bash loop that spawns GPT Codex instances (codex only)
- `CODEX.md` - Instructions given to each GPT Codex instance
- `prd.json.example` - Example PRD format
- `flowchart/` - Standalone flowchart explaining how Ralph works

## Flowchart

The `flowchart/` directory contains a standalone HTML flowchart designed for presentations. Click through to reveal each step with animations.

To run locally:
```bash
cd flowchart
python3 -m http.server 5173
```

## Patterns

- Each iteration spawns a fresh GPT Codex instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update AGENTS.md with discovered patterns for future iterations
