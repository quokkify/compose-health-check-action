#!/usr/bin/env bats

@test "composite action does not interpolate inputs inside run source" {
  action="$BATS_TEST_DIRNAME/../../action.yml"
  run awk '/^      run: \|/ { in_run=1; next } in_run && /\$\{\{ inputs\./ { found=1 } END { exit found ? 1 : 0 }' "$action"
  [ "$status" -eq 0 ]
}

@test "all shell-consumed public inputs have stable env mappings" {
  action="$BATS_TEST_DIRNAME/../../action.yml"
  for name in compose-files additional-compose-args services compose-services report-format docker-command compose-profiles; do
    env_name="$(printf '%s' "$name" | tr '[:lower:]-' '[:upper:]_')_INPUT"
    grep -F "$env_name: \${{ inputs.$name }}" "$action"
  done
}

@test "payload metacharacters remain data in shell variables" {
  payload='$(touch /tmp/compose-health-check-action-payload) `touch /tmp/compose-health-check-action-backtick` "quoted"'
  marker="$(mktemp)"
  run bash -c 'value="$1"; printf "%s" "$value" > "$2"' _ "$payload" "$marker"
  [ "$status" -eq 0 ]
  [ "$(cat "$marker")" = "$payload" ]
  [ ! -e /tmp/compose-health-check-action-payload ]
  [ ! -e /tmp/compose-health-check-action-backtick ]
  rm -f "$marker"
}
