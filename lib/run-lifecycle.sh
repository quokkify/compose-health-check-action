#!/usr/bin/env bash
set -euo pipefail

: "${SCRIPT_DIR:?SCRIPT_DIR is required}"

before_compose_hook_input="${before_compose_hook_input:-}"
after_health_hook_input="${after_health_hook_input:-}"
resolved_before_hook="${resolved_before_hook:-}"
resolved_after_hook="${resolved_after_hook:-}"
docker_command_input="${docker_command_input:-}"
compose_profiles_input="${compose_profiles_input:-}"

hook_profiles=()
if [[ -z "$docker_command_input" && -n "$compose_profiles_input" ]]; then
  read -r -a hook_profiles <<<"$(tr '\n' ' ' <<<"$compose_profiles_input")"
fi

run_hook() {
  local hook_name="$1"
  local hook_input="$2"
  local resolved_hook="$3"
  [[ -n "$hook_input" ]] || return 0

  echo "Running $hook_name: $hook_input"
  # Hooks are repository-owned code. Source them so before-compose exports
  # remain available to Docker Compose interpolation in this lifecycle.
  # Reset positional parameters first: `source file` with no explicit
  # arguments would otherwise leak run_hook's own arguments.
  set -- "${hook_profiles[@]}"
  # The resolver already canonicalized this repository-owned path inside GITHUB_WORKSPACE.
  # shellcheck disable=SC1090
  source "$resolved_hook" "$@"
}

run_hook "before-compose-hook" "$before_compose_hook_input" "$resolved_before_hook"
bash "${SCRIPT_DIR}/entrypoint.sh" "$@"
run_hook "after-health-hook" "$after_health_hook_input" "$resolved_after_hook"
