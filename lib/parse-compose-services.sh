#!/usr/bin/env bash
# Parse service operands from a docker compose up command without executing it.
# The result is returned in COMPOSE_SERVICES_FROM_CMD as an array.
collect_compose_services_from_up() {
  local -a cmd_args=("$@")
  COMPOSE_SERVICES_FROM_CMD=()
  local i token up_index=-1

  for ((i = 0; i < ${#cmd_args[@]}; i++)); do
    if [[ "${cmd_args[i]}" == "up" ]]; then
      up_index=$i
      break
    fi
  done
  ((up_index >= 0)) || return 0

  for ((i = up_index + 1; i < ${#cmd_args[@]}; i++)); do
    token="${cmd_args[i]}"
    if [[ "$token" == "--" ]]; then
      ((i++))
      while ((i < ${#cmd_args[@]})); do
        COMPOSE_SERVICES_FROM_CMD+=("${cmd_args[i]}")
        ((i++))
      done
      break
    fi

    # These up options consume the following token. Keep this list explicit
    # so option operands (notably --scale's SERVICE=NUM) cannot become targets.
    case "$token" in
      --scale|--profile|-p|--project-name|--pull|--timeout|--wait-timeout|--exit-code-from|--attach|--stop-timeout)
        ((i + 1 < ${#cmd_args[@]})) && ((i++))
        continue
        ;;
      --scale=*|--profile=*|--project-name=*|--pull=*|--timeout=*|--wait-timeout=*|--exit-code-from=*|--attach=*|--stop-timeout=*)
        continue
        ;;
    esac
    [[ "$token" == -* ]] && continue
    COMPOSE_SERVICES_FROM_CMD+=("$token")
  done
}
