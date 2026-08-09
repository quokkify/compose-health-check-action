#!/usr/bin/env bats

setup() {
  workspace="$(mktemp -d)"
  mkdir -p "$workspace/hooks"
  printf '#!/usr/bin/env bash\n' >"$workspace/hooks/readiness.sh"
  resolver="$BATS_TEST_DIRNAME/../../lib/resolve-lifecycle-hook.sh"
}

teardown() {
  rm -rf "$workspace"
}

@test "resolves a regular repository-relative lifecycle hook" {
  run bash "$resolver" "hooks/readiness.sh" "$workspace" "after-health-hook"
  [ "$status" -eq 0 ]
  [ "$output" = "$workspace/hooks/readiness.sh" ]
}

@test "rejects traversal absolute whitespace and missing lifecycle hooks" {
  for path in "../outside.sh" "/tmp/outside.sh" "hooks/readiness script.sh" "hooks/missing.sh"; do
    run bash "$resolver" "$path" "$workspace" "before-compose-hook"
    [ "$status" -ne 0 ]
  done
}

@test "rejects a hook symlink that resolves outside the workspace" {
  outside="$(mktemp)"
  ln -s "$outside" "$workspace/hooks/outside.sh"

  run bash "$resolver" "hooks/outside.sh" "$workspace" "after-health-hook"
  [ "$status" -ne 0 ]
  [[ "$output" == *"inside GITHUB_WORKSPACE"* ]]

  rm -f "$outside"
}
