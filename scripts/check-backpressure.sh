#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${RALPH_PROJECT_ROOT:-$PWD}"

has_quality_checks() {
  local package_json="$ROOT_DIR/package.json"
  if [ -f "$package_json" ]; then
    if command -v jq >/dev/null 2>&1; then
      if jq -e '.scripts | type == "object" and (has("test") or has("lint") or has("typecheck") or has("check"))' "$package_json" >/dev/null 2>&1; then
        return 0
      fi
    else
      if grep -q '"test"\|"lint"\|"typecheck"\|"check"' "$package_json" 2>/dev/null; then
        return 0
      fi
    fi
  fi

  local files=(
    "$ROOT_DIR/pyproject.toml"
    "$ROOT_DIR/tox.ini"
    "$ROOT_DIR/pytest.ini"
    "$ROOT_DIR/setup.cfg"
    "$ROOT_DIR/Makefile"
    "$ROOT_DIR/go.mod"
    "$ROOT_DIR/Cargo.toml"
    "$ROOT_DIR/gradlew"
    "$ROOT_DIR/build.gradle"
    "$ROOT_DIR/build.gradle.kts"
    "$ROOT_DIR/pom.xml"
    "$ROOT_DIR/composer.json"
    "$ROOT_DIR/Gemfile"
    "$ROOT_DIR/Rakefile"
  )

  local file
  for file in "${files[@]}"; do
    if [ -f "$file" ] || [ -x "$file" ]; then
      return 0
    fi
  done

  if ls "$ROOT_DIR"/*.csproj >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

if has_quality_checks; then
  echo "Backpressure check: OK"
  exit 0
fi

echo "Backpressure check: FAILED"
echo "No quality checks detected. Add a test/typecheck/lint command or config before running Ralphex."
exit 1
