# Ralph Agent Instructions

## Overview

Ralph is an autonomous GPT Codex loop for ChatGPT Pro accounts, tuned for budget-friendly iterations. Each iteration is a fresh instance with clean context.

## Commands

```bash
# Run the flowchart dev server
cd flowchart && npm run dev

# Build the flowchart
cd flowchart && npm run build

# Run Ralph (codex only, infinite by default)
./ralph.sh [max_iterations]

# Run Ralph with GPT Codex (explicit)
./ralph.sh --tool codex [max_iterations]
```

## Key Files

- `ralph.sh` - The bash loop that spawns GPT Codex instances (codex only)
- `CODEX.md` - Instructions given to each GPT Codex instance
- `prd.json.example` - Example PRD format
- `flowchart/` - Interactive React Flow diagram explaining how Ralph works

## Flowchart

The `flowchart/` directory contains an interactive visualization built with React Flow. It's designed for presentations - click through to reveal each step with animations.

To run locally:
```bash
cd flowchart
npm install
npm run dev
```

## Patterns

- Each iteration spawns a fresh GPT Codex instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update AGENTS.md with discovered patterns for future iterations
