#!/usr/bin/env bats

@test "scaled compose up parses service after --scale operand" {
  source "$BATS_TEST_DIRNAME/../../lib/parse-compose-services.sh"
  collect_compose_services_from_up docker compose --profile default -p project up -d --scale web=2 web
  [[ "${COMPOSE_SERVICES_FROM_CMD[*]}" == "web" ]]
}

@test "equals scale and project/profile options do not become services" {
  source "$BATS_TEST_DIRNAME/../../lib/parse-compose-services.sh"
  collect_compose_services_from_up docker compose --profile=default --project-name=project up --scale=web=2 --wait-timeout 30 web api
  [[ "${COMPOSE_SERVICES_FROM_CMD[*]}" == "web api" ]]
}

@test "scale without explicit service leaves auto-discovery to compose config" {
  source "$BATS_TEST_DIRNAME/../../lib/parse-compose-services.sh"
  collect_compose_services_from_up docker compose -p project up --scale web=2 --
  [[ "${#COMPOSE_SERVICES_FROM_CMD[@]}" -eq 0 ]]
}

@test "operand-taking no-attach option does not become a service" {
  source "$BATS_TEST_DIRNAME/../../lib/parse-compose-services.sh"
  collect_compose_services_from_up docker compose up --no-attach worker web
  [[ "${COMPOSE_SERVICES_FROM_CMD[*]}" == "web" ]]
}

@test "explicit boundary preserves service-like option names" {
  source "$BATS_TEST_DIRNAME/../../lib/parse-compose-services.sh"
  collect_compose_services_from_up docker compose up -- --service-with-dash web
  [[ "${COMPOSE_SERVICES_FROM_CMD[*]}" == "--service-with-dash web" ]]
}
