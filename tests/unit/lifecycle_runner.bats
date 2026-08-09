#!/usr/bin/env bats

setup() {
  TEST_ROOT="$(mktemp -d)"
  ACTION_ROOT="$TEST_ROOT/action"
  mkdir -p "$ACTION_ROOT"
  cp "$BATS_TEST_DIRNAME/../../entrypoint.sh" "$ACTION_ROOT/entrypoint.original.sh"
  cat >"$ACTION_ROOT/entrypoint.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
printf 'entrypoint:%s:%s\n' "${BOOTSTRAP_TOKEN:-missing}" "$*"
SCRIPT
  chmod +x "$ACTION_ROOT/entrypoint.sh"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

@test "errexit failure in before hook prevents Compose lifecycle" {
  cat >"$TEST_ROOT/before.sh" <<'SCRIPT'
set -e
false
echo should-not-run
SCRIPT

  run env \
    SCRIPT_DIR="$ACTION_ROOT" \
    before_compose_hook_input="hooks/before.sh" \
    resolved_before_hook="$TEST_ROOT/before.sh" \
    compose_profiles_input="storage redis" \
    bash "$BATS_TEST_DIRNAME/../../lib/run-lifecycle.sh" docker compose up -d

  [ "$status" -eq 1 ]
  [[ "$output" != *"should-not-run"* ]]
  [[ "$output" != *"entrypoint:"* ]]
}

@test "before exports and profile arguments reach entrypoint and after hook" {
  cat >"$TEST_ROOT/before.sh" <<'SCRIPT'
printf 'before:%s\n' "$*"
export BOOTSTRAP_TOKEN=ready
SCRIPT
  cat >"$TEST_ROOT/after.sh" <<'SCRIPT'
printf 'after:%s\n' "$*"
SCRIPT

  run env \
    SCRIPT_DIR="$ACTION_ROOT" \
    before_compose_hook_input="hooks/before.sh" \
    after_health_hook_input="hooks/after.sh" \
    resolved_before_hook="$TEST_ROOT/before.sh" \
    resolved_after_hook="$TEST_ROOT/after.sh" \
    compose_profiles_input="storage redis" \
    bash "$BATS_TEST_DIRNAME/../../lib/run-lifecycle.sh" docker compose up -d

  [ "$status" -eq 0 ]
  [[ "$output" == *"before:storage redis"* ]]
  [[ "$output" == *"entrypoint:ready:docker compose up -d"* ]]
  [[ "$output" == *"after:storage redis"* ]]
}

@test "docker-command mode does not pass ignored profiles to hooks" {
  cat >"$TEST_ROOT/before.sh" <<'SCRIPT'
printf 'hook-argc:%s\n' "$#"
SCRIPT

  run env \
    SCRIPT_DIR="$ACTION_ROOT" \
    before_compose_hook_input="hooks/before.sh" \
    resolved_before_hook="$TEST_ROOT/before.sh" \
    compose_profiles_input="storage redis" \
    docker_command_input="docker compose up -d" \
    bash "$BATS_TEST_DIRNAME/../../lib/run-lifecycle.sh" docker compose up -d

  [ "$status" -eq 0 ]
  [[ "$output" == *"hook-argc:0"* ]]
}
