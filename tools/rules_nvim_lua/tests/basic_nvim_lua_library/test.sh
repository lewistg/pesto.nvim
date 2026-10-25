#!/usr/bin/env bash

set -euo pipefail

ROOT="$(dirname "$0")"

result="$("$ROOT"/basic_nvim_lua_library_runner.sh)"
expected_result="abc"

[ "$result" == "$expected_result" ]
