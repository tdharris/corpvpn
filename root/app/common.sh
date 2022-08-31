#!/usr/bin/env bash

log() { 
    local -r level="$1"
    shift
    echo -e "[${level^^}] [docker-entrypoint.sh] $(date '+%Y-%m-%d %H:%M:%S.%3N') $*" >/proc/1/fd/1 2>&1
}

fail() {
  log error "$1"
  exit 1
}

retry() {
  local n=1
  local max=5
  local delay=3
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        log error "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}
