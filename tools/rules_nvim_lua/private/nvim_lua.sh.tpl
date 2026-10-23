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

NVIM_BIN="$(rlocation "{{NVIM_BIN}}")"
ENTRY_POINT="$(rlocation "{{ENTRY_POINT}}")"

"$NVIM_BIN" --clean -l "$ENTRY_POINT"
