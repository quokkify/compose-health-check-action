#!/usr/bin/env bats

@test "runtime lookup scopes same-named service to resolved project" {
  marker="$(mktemp)"
  rm -f "$marker"
  docker() {
    printf '%s\n' "$*" >>"$marker"
    case "$1" in
      info)
        printf 'linux/amd64\n'
        ;;
      ps)
        if [[ "$*" == *'target-project'* ]]; then
          printf 'targetcid\n'
        else
          printf 'foreigncid\n'
        fi
        ;;
      inspect)
        if [[ "$*" == *targetcid* ]]; then
          case "$*" in
            *Health.Status*) printf 'healthy\n' ;;
            *Health\}\}*) printf 'yes\n' ;;
            *Status*) printf 'running\n' ;;
          esac
        fi
        ;;
    esac
  }
  source "$BATS_TEST_DIRNAME/../../entrypoint.sh"
  DOCKER_HEALTH_PROJECT_SCOPE="target-project"
  run get_service_runtime_tag web
  [ "$status" -eq 0 ]
  [ "$output" = "HEALTHY" ]
  grep -F 'label=com.docker.compose.project=target-project' "$marker"
  ! grep -F 'label=com.docker.compose.service=web' "$marker" >/dev/null || true
  rm -f "$marker"
}

@test "runtime lookup fails closed without resolved project" {
  docker() { printf 'unexpected docker call\n' >&2; return 1; }
  source "$BATS_TEST_DIRNAME/../../entrypoint.sh"
  DOCKER_HEALTH_PROJECT_SCOPE=""
  run get_service_runtime_tag web
  [ "$status" -eq 0 ]
  [ "$output" = "NO_CONTAINERS" ]
  [[ "$output" != *"unexpected docker call"* ]]
}
