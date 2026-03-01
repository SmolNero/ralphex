#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool codex] [max_iterations]

set -e

# Parse arguments
TOOL="codex"  # Default to codex
MAX_ITERATIONS=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Enforce codex-only mode
if [[ "$TOOL" != "codex" ]]; then
  echo "Note: tool '$TOOL' is disabled; using 'codex' instead."
  TOOL="codex"
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
CODEX_DRIVER=${CODEX_DRIVER:-codex}
CODEX_MODEL=${CODEX_MODEL:-openai/gpt-5.2-codex}
CODEX_AGENT=${CODEX_AGENT:-build}

if [ ! -f "$PRD_FILE" ]; then
  if [ "${PRD_BOOTSTRAP:-}" == "1" ] && [ -f "$SCRIPT_DIR/prd.json.example" ]; then
    echo "prd.json not found; copying prd.json.example to prd.json"
    cp "$SCRIPT_DIR/prd.json.example" "$PRD_FILE"
  else
    echo "Error: prd.json not found."
    echo "Create one for your project or copy prd.json.example:"
    echo "  cp prd.json.example prd.json"
    echo "Or set PRD_BOOTSTRAP=1 to auto-copy the example."
    exit 1
  fi
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"
    
    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

print_banner() {
  local greeting="$1"
  local status="$2"

  echo ""
  cat <<EOF
⠀⠀⠀⠀⠀⠀⣀⣤⣶⡶⢛⠟⡿⠻⢻⢿⢶⢦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣠⡾⡫⢊⠌⡐⢡⠊⢰⠁⡎⠘⡄⢢⠙⡛⡷⢤⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⢪⢋⡞⢠⠃⡜⠀⠎⠀⠉⠀⠃⠀⠃⠀⠃⠙⠘⠊⢻⠦⠀⠀⠀⠀⠀⠀
⠀⠀⢇⡇⡜⠀⠜⠀⠁⠀⢀⠔⠉⠉⠑⠄⠀⠀⡰⠊⠉⠑⡄⡇⠀⠀⠀⠀⠀⠀
⠀⠀⡸⠧⠄⠀⠀⠀⠀⠀⠘⡀⠾⠀⠀⣸⠀⠀⢧⠀⠛⠀⠌⡇⠀⠀⠀⠀⠀⠀
⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠙⠒⠒⠚⠁⠈⠉⠲⡍⠒⠈⠀⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠈⠲⣆⠀⠀⠀⠀⠀⠀⠀⠀⣠⠖⠉⡹⠤⠶⠁⠀⠀⠀⠈⢦⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⣦⡀⠀⠀⠀⠀⠧⣴⠁⠀⠘⠓⢲⣄⣀⣀⣀⡤⠔⠃⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣜⠀⠈⠓⠦⢄⣀⣀⣸⠀⠀⠀⠀⠁⢈⢇⣼⡁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⠒⠛⠲⣄⠀⠀⠀⣠⠏⠀⠉⠲⣤⠀⢸⠋⢻⣤⡛⣄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢡⠀⠀⠀⠀⠉⢲⠾⠁⠀⠀⠀⠀⠈⢳⡾⣤⠟⠁⠹⣿⢆⠀⠀⠀⠀⠀⠀
⠀⢀⠼⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠈⣧⠀⠀⠀⠀⠀
⠀⡏⠀⠘⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀
⢰⣄⠀⠀⠀⠉⠳⠦⣤⣤⡤⠴⠖⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢯⣆⠀⠀⠀
⢸⣉⠉⠓⠲⢦⣤⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣠⣼⢹⡄⠀⠀
⠘⡍⠙⠒⠶⢤⣄⣈⣉⡉⠉⠙⠛⠛⠛⠛⠛⠛⢻⠉⠉⠉⢙⣏⣁⣸⠇⡇⠀⠀
⠀⢣⠀⠀⠀⠀⠀⠀⠉⠉⠉⠙⠛⠛⠛⠛⠛⠛⠛⠒⠒⠒⠋⠉⠀⠸⠚⢇⠀⠀
⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠇⢤⣨⠇⠀
⠀⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⢻⡀⣸⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⠛⠉⠁⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⢠⢄⣀⣤⠤⠴⠒⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⠀⠀⠀
⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⢷⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀
⠀⠀⢀⡷⢤⣤⣀⣀⣀⣀⣠⠤⠾⣤⣀⡘⠛⠶⠶⠶⠶⠖⠒⠋⠙⠓⠲⢤⣀⠀
⠀⠀⠘⠧⣀⡀⠈⠉⠉⠁⠀⠀⠀⠀⠈⠙⠳⣤⣄⣀⣀⣀⠀⠀⠀⠀⠀⢀⣈⡇


Ralph says: ${greeting}
Ralphex Loops: ${status}
EOF
  echo ""
}

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

if [ "${RALPH_FORCE:-}" != "1" ]; then
  if [ "${RALPH_DISABLED:-}" == "1" ] || [ -f "$SCRIPT_DIR/.ralph-disabled" ] || [ -f "$SCRIPT_DIR/.ralphex-disabled" ]; then
    print_banner "bi!" "DEACTIVATED 🔴"
    echo "Ralphex is deactivated. Remove .ralphex-disabled (or .ralph-disabled) or set RALPH_FORCE=1 to run."
    exit 0
  fi
fi

print_banner "hi!" "ACTIVE 🟢"

# Codex preflight checks
if [[ "$TOOL" == "codex" ]]; then
  if [[ "$CODEX_DRIVER" == "opencode" ]]; then
    if ! command -v opencode >/dev/null 2>&1; then
      echo "Error: opencode CLI not found. Install from: https://opencode.ai"
      exit 1
    fi
    if ! opencode auth list 2>&1 | grep -q "OpenAI"; then
      echo "Error: opencode has no OpenAI credentials."
      echo "Run: opencode auth login"
      exit 1
    fi
  else
    if ! command -v codex >/dev/null 2>&1; then
      echo "Error: codex CLI not found. Install with: npm install -g @openai/codex"
      exit 1
    fi

    if [[ "${CODEX_SKIP_LOGIN_CHECK:-}" != "1" ]]; then
      CODEX_LOGIN_STATUS=$(codex login status 2>&1 || true)
      if echo "$CODEX_LOGIN_STATUS" | grep -q "Not logged in"; then
        if [[ -n "${OPENAI_API_KEY:-}" ]]; then
          echo "Codex not logged in; attempting auto-login with OPENAI_API_KEY."
          printf "%s" "$OPENAI_API_KEY" | codex login --with-api-key >/dev/null 2>&1 || true
          CODEX_LOGIN_STATUS=$(codex login status 2>&1 || true)
        fi

        if echo "$CODEX_LOGIN_STATUS" | grep -q "Not logged in"; then
          if command -v opencode >/dev/null 2>&1 && opencode auth list 2>&1 | grep -q "OpenAI"; then
            echo "Codex not logged in; falling back to opencode (OpenAI OAuth)."
            CODEX_DRIVER=opencode
          else
            echo "Error: codex is not logged in."
            echo "Run: codex login"
            echo "Or use an API key: printenv OPENAI_API_KEY | codex login --with-api-key"
            echo "Or bypass login check (if you manage auth elsewhere): CODEX_SKIP_LOGIN_CHECK=1"
            echo "Or use opencode: CODEX_DRIVER=opencode"
            exit 1
          fi
        fi
      fi
    fi
  fi
fi

if [[ "$TOOL" == "codex" ]]; then
  if [ "$MAX_ITERATIONS" -eq 0 ]; then
    echo "Starting Ralph - Tool: $TOOL ($CODEX_DRIVER) - Max iterations: infinite"
  else
    echo "Starting Ralph - Tool: $TOOL ($CODEX_DRIVER) - Max iterations: $MAX_ITERATIONS"
  fi
else
  if [ "$MAX_ITERATIONS" -eq 0 ]; then
    echo "Starting Ralph - Tool: $TOOL - Max iterations: infinite"
  else
    echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
  fi
fi

i=0
while true; do
  i=$((i + 1))
  if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$i" -gt "$MAX_ITERATIONS" ]; then
    break
  fi
  echo ""
  echo "==============================================================="
  if [ "$MAX_ITERATIONS" -eq 0 ]; then
    echo "  Ralph Iteration $i of infinite ($TOOL)"
  else
    echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  fi
  echo "==============================================================="

  # Run Codex with the ralph prompt
  if [[ "$CODEX_DRIVER" == "opencode" ]]; then
      OPENCODE_MESSAGE=${CODEX_OPENCODE_MESSAGE:-"Follow the instructions in the attached CODEX.md file. You have full permission to proceed without asking for approvals."}
      OUTPUT=$(opencode run --model "$CODEX_MODEL" --agent "$CODEX_AGENT" --dir "$SCRIPT_DIR" --file "$SCRIPT_DIR/CODEX.md" -- "$OPENCODE_MESSAGE" 2>&1 | tee /dev/stderr) || true
    else
    # Codex: hard-locked command with approval bypass
    CODEX_CMD="codex exec --dangerously-bypass-approvals-and-sandbox"
      OUTPUT=$(cat "$SCRIPT_DIR/CODEX.md" | $CODEX_CMD 2>&1 | tee /dev/stderr) || true
    fi
  
  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi
  
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
