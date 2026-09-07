#!/usr/bin/bash

set -euo pipefail

# Copy-pasted from the Bazel Bash runfiles library v3. [1]
# [1]: https://github.com/bazel-contrib/rules_shell/blob/main/shell/runfiles/runfiles.bash
#
# --- begin runfiles.bash initialization v3 ---
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

NVIM_BIN="$(rlocation {{NVIM_BIN_RUNFILE_PATH}})"

LUA_ROOT_DIRS=(
    {{LUA_ROOT_DIRS}}
)

declare LUA_PATH=""
for lua_root_dir in "${LUA_ROOT_DIRS[@]}"; do
    lua_runfile_root_dir="$(rlocation "$lua_root_dir")"
    LUA_PATH="${lua_runfile_root_dir}/?.lua;$LUA_PATH"
    LUA_PATH="${lua_runfile_root_dir}/?/init.lua;$LUA_PATH"
done

ENTRY_POINT="$(rlocation {{ENTRY_POINT_RUNFILE_PATH}})"
PREDEFINED_ENTRY_POINT_ARGS=(
    {{PREDEFINED_ENTRY_POINT_ARGS}}
)

# Tip: If there are issues with runfiles, use `$ RUNFILES_LIB_DEBUG=1 bazel run ...` to get debug info
if [[ -n "${NVIM_LUA_DEBUG:-}" ]]; then
    echo "INFO[NVIM_LUA]: NVIM_BIN: $NVIM_BIN"
    echo "INFO[NVIM_LUA]: LUA_PATH: ${LUA_PATH:-}"
    echo "INFO[NVIM_LUA]: PREDEFINED_ENTRY_POINT_ARGS: ${PREDEFINED_ENTRY_POINT_ARGS:-}"
fi

export LUA_PATH
"$NVIM_BIN" \
    --clean \
    -l \
    "$ENTRY_POINT" \
    "${PREDEFINED_ENTRY_POINT_ARGS[@]}"
