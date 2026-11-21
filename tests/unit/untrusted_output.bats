#!/usr/bin/env bats

# Regression guard: container-controlled output must not be able to inject
# GitHub workflow commands (::error::, ::add-mask::, ::stop-commands::, ...)
# into the job log.

setup() {
  source "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  spoof_log() {
    printf '::error::spoofed\n'
    printf '::add-mask::x\n'
    printf '::stop-commands::guessed\n'
    printf 'regular line\n'
  }
}

begin_token() { sed -n 's/^::stop-commands::\([0-9a-f]\{32\}\)$/\1/p' <<<"$1" | head -n 1; }

@test "regression guard: spoofed workflow commands sit between stop-commands markers" {
  run bash -c 'source "$1"; printf "::error::spoofed\n::add-mask::x\n" | emit_untrusted' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  [ "$status" -eq 0 ]
  token="$(begin_token "$output")"
  [ -n "$token" ]
  mapfile -t lines <<<"$output"
  [ "${lines[0]}" = "::stop-commands::$token" ]
  [ "${lines[1]}" = "::error::spoofed" ]
  [ "${lines[2]}" = "::add-mask::x" ]
  [ "${lines[3]}" = "::$token::" ]
  [ "${#lines[@]}" -eq 4 ]
}

@test "regression guard: token differs between runs" {
  run bash -c 'source "$1"; echo hi | emit_untrusted' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  first="$(begin_token "$output")"
  run bash -c 'source "$1"; echo hi | emit_untrusted' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  second="$(begin_token "$output")"
  [ -n "$first" ]
  [ -n "$second" ]
  [ "$first" != "$second" ]
}

@test "regression guard: closing marker is emitted when the log command exits non-zero" {
  run bash -c 'set -euo pipefail; source "$1"; { printf "::error::spoofed\n"; exit 3; } | emit_untrusted' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  token="$(begin_token "$output")"
  [ -n "$token" ]
  [[ "$output" == *$'\n'"::$token::" ]]
}

@test "indent prefix is applied and unterminated last line is kept" {
  run bash -c 'source "$1"; printf "a\nb" | emit_untrusted "    "' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  [[ "$output" == *$'\n    a\n    b\n::'* ]]
}

@test "regression guard: container logs and probe output in diagnostics are guarded" {
  docker() {
    case "$1" in
      logs) printf '::error::spoofed\n::add-mask::x\n'; return 1 ;;
      inspect)
        case "$*" in
          *json*) printf '[{"Output":"::error::probe"}]\n' ;;
          *Health.Status*) printf 'unhealthy\n' ;;
          *) printf 'running\n' ;;
        esac
        ;;
      info) printf 'linux/amd64\n' ;;
    esac
  }
  source "$BATS_TEST_DIRNAME/../../entrypoint.sh"
  DOCKER_HEALTH_UNHEALTHY_TARGETS=("web|cid1")
  DOCKER_HEALTH_LOG_LINES=5
  run print_unhealthy_services_details
  [ "$status" -eq 0 ]
  for payload in '::error::spoofed' '::add-mask::x' '::error::probe'; do
    # every payload line is preceded by an open marker and followed by its close marker
    awk -v p="$payload" '
      /^::stop-commands::/ { open=1; next }
      /^::[0-9a-f]{32}::$/ { open=0; next }
      index($0, p) && !open { bad=1 }
      END { exit bad }
    ' <<<"$output"
  done
  [ "$(grep -c '^::stop-commands::' <<<"$output")" -eq "$(grep -c '^::[0-9a-f]\{32\}::$' <<<"$output")" ]
}

@test "regression guard: an enormous single line is truncated with a visible suffix" {
  run bash -c 'source "$1"; head -c 200000 /dev/zero | tr "\0" "a" | emit_untrusted "  "' _ "$BATS_TEST_DIRNAME/../../lib/logging.sh"
  [ "$status" -eq 0 ]
  mapfile -t lines <<<"$output"
  [ "${#lines[@]}" -eq 3 ]
  [ "${#lines[1]}" -le $((2 + 4096 + 20)) ]
  [[ "${lines[1]}" == *"…[truncated]" ]]
  [[ "${lines[2]}" =~ ^::[0-9a-f]{32}::$ ]]
}
