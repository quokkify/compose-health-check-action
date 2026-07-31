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

@test "build command transports shell metacharacters as data" {
  marker="$(mktemp)"
  rm -f "$marker"
  payload="$(printf 'docker compose --project-name \"$(touch %s)\" up -d \"web`touch %s`\" \"quote \\\" newline\nservice\"' "$marker" "$marker")"
  run bash -c 'mapfile -d "" -t cmd < <(DOCKER_COMMAND_INPUT="$1" bash "$2"); printf "%s\\n" "${cmd[@]}"' _ "$payload" "$BATS_TEST_DIRNAME/../../lib/build-compose-command.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'$(touch '* ]]
  [[ "$output" == *'`touch '* ]]
  [[ "$output" == *$'newline\nservice'* ]]
  [ ! -e "$marker" ]
}
