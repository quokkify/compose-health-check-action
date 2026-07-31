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

@test "explicit command project wins over input when compose has no label" {
  marker="$(mktemp)"
  rm -f "$marker"
  docker() {
    printf '%s\n' "$*" >>"$marker"
    case "$1" in
      info) printf 'linux/amd64\n' ;;
      ps)
        if [[ "$*" == *'label=com.docker.compose.project=target'* ]]; then
          printf '\n'
        else
          printf 'foreigncid\n'
        fi
        ;;
    esac
  }
  DOCKER_HEALTH_PROJECT_NAME_INPUT="foreign"
  COMPOSE_PROJECT_NAME="foreign"
  source "$BATS_TEST_DIRNAME/../../entrypoint.sh"

  for variant in '-p target' '--project-name target' '--project-name=target'; do
    read -r -a command <<<"docker compose $variant up -d web"
    run resolve_project_name "${command[@]}"
    [ "$status" -eq 0 ]
    [ "$output" = "target" ]
  done

  DOCKER_HEALTH_PROJECT_SCOPE="$output"
  run get_service_runtime_tag web
  [ "$status" -eq 0 ]
  [ "$output" = "NO_CONTAINERS" ]
  ! grep -F 'foreign' "$marker" >/dev/null
  rm -f "$marker"
}
