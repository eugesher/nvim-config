#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
nvim=${NVIM:-$(command -v nvim)}
parent=$(cd "${TEST_SANDBOX_PARENT:-$repo/..}" && pwd)
dir=$parent
while [[ $dir != / ]]; do
  if [[ -e $dir/.git ]]; then
    echo "TEST_SANDBOX_PARENT must be outside a git repository: $dir/.git" >&2
    exit 2
  fi
  dir=$(dirname "$dir")
done
sandbox=$(mktemp -d "$parent/.ptest.XXXXXX")
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox"/{home,config,data,state,cache,run}

timeout -s KILL "${TEST_TIMEOUT:-300}" env -i \
  PATH=/usr/bin:/bin \
  LANG=C.UTF-8 \
  HOME="$sandbox/home" \
  TEST_SANDBOX="$sandbox" \
  XDG_CONFIG_HOME="$sandbox/config" \
  XDG_DATA_HOME="$sandbox/data" \
  XDG_STATE_HOME="$sandbox/state" \
  XDG_CACHE_HOME="$sandbox/cache" \
  XDG_RUNTIME_DIR="$sandbox/run" \
  GIT_CEILING_DIRECTORIES="$sandbox" \
  GIT_CONFIG_NOSYSTEM=1 \
  GIT_CONFIG_GLOBAL=/dev/null \
  "$nvim" --clean --headless -i NONE -n -l "$repo/tests/run.lua" "$@"
