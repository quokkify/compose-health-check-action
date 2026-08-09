#!/usr/bin/env bash
set -euo pipefail

hook_path="${1:-}"
workspace="${2:-${GITHUB_WORKSPACE:-}}"
hook_name="${3:-lifecycle hook}"

if [[ -z "$hook_path" ]]; then
  exit 0
fi

if [[ -z "$workspace" ]]; then
  echo "GITHUB_WORKSPACE is required when $hook_name is configured." >&2
  exit 1
fi

python3 - "$workspace" "$hook_path" "$hook_name" <<'PY'
from pathlib import Path
import sys

workspace_raw, hook_raw, hook_name = sys.argv[1:]

if any(character.isspace() or ord(character) < 32 or ord(character) == 127 for character in hook_raw):
    raise SystemExit(f"{hook_name} must be a repository-relative path without whitespace or control characters")

hook = Path(hook_raw)
if not hook_raw or hook.is_absolute() or hook_raw.startswith("~") or ":" in hook_raw:
    raise SystemExit(f"{hook_name} must be a repository-relative path")
if any(part in {"", ".", ".."} for part in hook.parts):
    raise SystemExit(f"{hook_name} must not contain empty, dot, or traversal components")

workspace = Path(workspace_raw).resolve(strict=True)
candidate = (workspace / hook).resolve(strict=True)
try:
    candidate.relative_to(workspace)
except ValueError as error:
    raise SystemExit(f"{hook_name} must resolve inside GITHUB_WORKSPACE") from error
if not candidate.is_file():
    raise SystemExit(f"{hook_name} must resolve to a regular file")

print(candidate)
PY
