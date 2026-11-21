# Changelog

## [2.4.1](https://github.com/quokkify/compose-health-check-action/compare/v2.4.0...v2.4.1) (2026-11-21)


### 🐛 Bug Fixes

* stop container output from injecting workflow commands ([#140](https://github.com/quokkify/compose-health-check-action/issues/140)) ([b6ae87a](https://github.com/quokkify/compose-health-check-action/commit/b6ae87a2d57f0f3baa542f5752dd272410010ca7))


### 📦 Dependencies

* **docker-compose:** update busybox:1.38 docker digest to a46257e ([#144](https://github.com/quokkify/compose-health-check-action/issues/144)) ([24b279c](https://github.com/quokkify/compose-health-check-action/commit/24b279cd10000ca6b43f05e0c4cd471e56949691))
* **github-actions:** update actions/download-artifact digest to 9000827 ([#114](https://github.com/quokkify/compose-health-check-action/issues/114)) ([421ca28](https://github.com/quokkify/compose-health-check-action/commit/421ca28285d46e6cfd5380f1bc55f2289d354876))
* **github-actions:** update actions/upload-artifact digest to cf430e0 ([#115](https://github.com/quokkify/compose-health-check-action/issues/115)) ([f1b7db9](https://github.com/quokkify/compose-health-check-action/commit/f1b7db9d88241c6ee96496d2fd64f4677082707d))
* **github-actions:** update bats-core/bats-action action to v4.1.0 ([#139](https://github.com/quokkify/compose-health-check-action/issues/139)) ([829f3db](https://github.com/quokkify/compose-health-check-action/commit/829f3db45ce76d31a683fd5f6b26211d3d6b8097))
* **github-actions:** update dorny/test-reporter digest to d1b5dff ([#117](https://github.com/quokkify/compose-health-check-action/issues/117)) ([e6a4633](https://github.com/quokkify/compose-health-check-action/commit/e6a4633ab921bb7b70799a8ffdf17ca7bb2ac8f1))

## v2.4.0 (09.08.2026)

- Added optional repository-owned `before-compose-hook` and `after-health-hook` lifecycle scripts around Compose startup and built-in health checks.
- Resolved and validated both hook paths inside `GITHUB_WORKSPACE` before startup, rejecting absolute paths, traversal, missing files, and workspace-escaping symlinks.
- Ran hooks in a strict lifecycle shell so before-hook exports reach Compose interpolation and unhandled hook failures stop the lifecycle with the original exit status.
- Passed normalized Compose profiles to hooks while preserving `docker-command` profile-precedence semantics.
- Suppressed successful JSON lifecycle output when bootstrap, Compose health, or project readiness fails, with execution-level Bats regression coverage.

## v2.3.0 (31.07.2026)

- Hardened composite-action input transport so shell metacharacters cannot be evaluated as generated shell source.
- Corrected Compose service parsing for scaled services and operand-taking options, including `--no-attach` and `-t`/`--timeout`.
- Made explicit `-p`/`--project-name` selection authoritative with Docker Compose last-value-wins semantics and safe ordered fallbacks when no containers exist yet.
- Scoped container discovery and diagnostics to the resolved Compose project and fail closed when the project cannot be resolved.
- Pinned internal workflow actions to immutable commits and disabled persisted checkout credentials.

## v2.2.0 (27.01.2026)

- When `docker compose up` fails but a container exits with non-zero, treat it as unhealthy and print health/log diagnostics.

## v2.1.1 (23.01.2026)

- Fixed `compose-services` input wiring to avoid unbound variable errors in GitHub Actions.
- On `docker compose` failures, print logs for unhealthy/exited containers to aid diagnostics.

## v2.1.0 (23.01.2026)

- Added `log-lines` input to control diagnostics output length
- Added Bats coverage for `log-lines` in v1/v2 flows
- Added `compose-services` (new) and deprecated `services` input
- Added `compose-profiles` input to pass compose profiles in input-based mode
- Reused compose command builder across action and tests to avoid drift
- Added project name inputs (`compose-project-name`, `auto-apply-project-name`, `project-name-env-file`)
- Auto-detect project name from running compose containers and persist to env file

## v2.0.0 (18.01.2026)

- Added `docker-command` input to run a custom `docker compose` command
- Default to checking all services when none are specified
- Hardened input parsing to avoid unsafe eval/word-splitting
- Expanded Bats coverage with v1/v2 flows and quoted-path scenarios

## v1.1.1 (18.01.2026)

- Added bats tests [#33](https://github.com/ylazakovich/compose-health-check-action/pull/33)
- Improved test infra
  - enable parallel run (1 test.bats per 1 runner) [#37](https://github.com/ylazakovich/compose-health-check-action/pull/37)
  - speed up docker compose [#43](https://github.com/ylazakovich/compose-health-check-action/pull/43)
- Update docs [#45](https://github.com/ylazakovich/compose-health-check-action/pull/45)

## v1.1.0 (23.12.2025)

- Added JSON report generation mechanism with configurable output format (text, json, or both) [#23](https://github.com/ylazakovich/compose-health-check-action/pull/23)
  - Introduced `report-format` input and `report_json_b64` output for machine-readable health check reports
  - Enhanced summary statistics with aggregated counters across all service states
- Implemented comprehensive test suite using BATS (Bash Automated Testing System) [#24](https://github.com/ylazakovich/compose-health-check-action/pull/24)
  - Added test coverage for healthy, unhealthy, compose-failed, and no-services scenarios
  - Replaced individual workflow-based tests with unified BATS test runner and JUnit reporting

## v1.0.2 [\*](https://github.com/ylazakovich/compose-health-check-action/pull/18) (22.12.2025)

- Added support for one-shot containers with `depends_on` relations by detecting exit codes
- Improved service status detection to include stopped containers and categorize states (HEALTHY, COMPLETED, UNHEALTHY, FAILED, UP, NO_CONTAINERS)
- Enhanced summary statistics to reflect actual runtime states across all services

## v1.0.1 (23.11.2025)

- patch: resolve issue with additional-compose-args (#17)

## v0.1.1 (23.11.2025)

**Bugfix & Stability Release**

This release significantly improves the reliability and consistency of the action in real CI environments, especially when using multi-file Docker Compose setups and nested directory structures.

### 🚀 Improved

- Enhanced compatibility between GitHub Runners and Docker Compose.
- Removed the `--project-directory` flag to prevent incorrect path resolution on GitHub Actions.
- Ensured consistent behavior both locally (`act`) and on GitHub-hosted runners.
- The `docker compose config --services` command is now executed with the same `-f ...` flags as the main `docker compose` invocation, providing accurate service detection.
- Improved the **Detected services** section — all services from the compose configuration are now listed correctly.
- Increased stability of the healthcheck cycle for large multi-service Docker Compose stacks.

### 🐛 Fixed

- Fixed an issue where the “Detected services” table appeared empty in external projects.
- Corrected the working directory resolution inside GitHub Action runs.
- Eliminated GitHub Actions warnings:  
  _“Unexpected input(s) … valid inputs are …”_  
  caused by legacy internal action paths in CI tests.
- Internal CI now properly uses the root-level `action.yml` instead of the legacy subdirectory version.
- Resolved issues that appeared after moving `action.yml` to the repository root.

### 🔧 Internal

- Refactored `docker_health_check.sh`:
  - improved construction of the main compose command,
  - unified behavior between local shells and GitHub Runners,
  - added groundwork for future support of job-like services (`exited 0` behavior).

---

## v0.1.0 — Pre-release for internal testing (23.11.2025)

This is the first pre-release of the Compose Health Check Action.

The purpose of this version is to validate functionality in real CI/CD pipelines before publishing the stable `v1.0.0` release and submitting the action to GitHub Marketplace.

### Features included in this pre-release:

- Automatic health checks for specified Docker Compose services
- Support for multiple compose files
- Configurable timeout
- Workflow failure if services do not reach a healthy state
- Simple and reproducible usage within GitHub Actions

### Example usage:

```yaml
- name: Run healthcheck
  uses: ylazakovich/compose-health-check-action@v0.1.0
  with:
    compose-files: |
      docker-compose.yml
    services: "web"
    timeout: "60"
```
