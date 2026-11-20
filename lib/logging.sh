#!/bin/bash
# ============================================================================
#  Common logging utilities for Bash scripts
# ============================================================================

info() { printf "\033[1;36mℹ️  %s\033[0m\n" "$*"; }
warning() { printf "\033[1;33m⚠️  %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m❌ %s\033[0m\n" "$*"; }

fatal() {
  error "$@"
  exit 1
}

# Reads untrusted text (container logs, probe output, compose output) on stdin
# and prints it line by line, optionally prefixed with $1, between GitHub
# `::stop-commands::<token>` markers so it cannot inject workflow commands
# into the job log. The token is random per call, so the text cannot guess or
# close it. The closing marker is printed when stdin reaches EOF, which happens
# even when the producing command failed.
emit_untrusted() {
  local indent="${1:-}" token line
  token="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"
  if [[ ! "$token" =~ ^[0-9a-f]{32}$ ]]; then
    cat >/dev/null
    printf '%s[output withheld: could not generate a log guard token]\n' "$indent"
    return 0
  fi

  printf '::stop-commands::%s\n' "$token"
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s%s\n' "$indent" "$line"
  done
  printf '::%s::\n' "$token"
}
