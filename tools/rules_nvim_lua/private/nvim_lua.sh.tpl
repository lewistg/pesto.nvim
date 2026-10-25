#!/usr/bin/env bash

set -euo pipefail

# Copy-pasted from the Bazel Bash runfiles library v3. [1]
# [1]: https://github.com/bazel-contrib/rules_shell/blob/main/shell/runfiles/runfiles.bash
# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

# We don't want the runfiles library to resolve runfiles using the manifest. We
# do this by unsetting RUNFILES_MANIFEST_FILE (see the implementation of
# rlocation). If we use the manifest we are unable to look up intermediate
# parent directories like the "lua root dirs."
#
# When the "binary" is run using bazel run, the RUNFILES_DIR directory will not
# be set, so we set it here.
#
# (Runfiles are so frustrating.)
unset RUNFILES_MANIFEST_FILE
RUNFILES_DIR="${RUNFILES_DIR:-$0.runfiles}"

NVIM_BIN="$(rlocation "{{NVIM_BIN}}")"
ENTRY_POINT="$(rlocation "{{ENTRY_POINT}}")"

ENTRY_POINT_ARGS="{{ENTRY_POINT_ARGS}}"
if [ -z "$ENTRY_POINT_ARGS" ]; then
    ENTRY_POINT_ARGS="/dev/null"
else
    ENTRY_POINT_ARGS="$(rlocation "{{ENTRY_POINT_ARGS}}")"
fi

export LUA_PATH=""
LUA_PATH_ROOTS=(
    {{LUA_PATH_ROOTS}}
)
for path in "${LUA_PATH_ROOTS[@]}"; do
    path=$(rlocation "$path")
    paths="${path}/?.lua;${path}/?/init.lua"
    if [ -n "$LUA_PATH" ]; then
        LUA_PATH="${LUA_PATH};$paths"
    else
        LUA_PATH="$paths"
    fi
done

"$NVIM_BIN" --clean \
    -l \
    "$ENTRY_POINT" \
    $(< "$ENTRY_POINT_ARGS")
