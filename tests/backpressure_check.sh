#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/check-backpressure.sh"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir/scripts"
cp "$SCRIPT" "$tmp_dir/scripts/check-backpressure.sh"
chmod +x "$tmp_dir/scripts/check-backpressure.sh"

if "$tmp_dir/scripts/check-backpressure.sh" >/dev/null 2>&1; then
  echo "Expected failure when no checks configured"
  exit 1
fi

cat > "$tmp_dir/package.json" <<'EOF'
{"scripts":{"test":"echo ok"}}
EOF

if ! RALPH_PROJECT_ROOT="$tmp_dir" "$tmp_dir/scripts/check-backpressure.sh" >/dev/null 2>&1; then
  echo "Expected success when test script present"
  exit 1
fi

echo "ok"
