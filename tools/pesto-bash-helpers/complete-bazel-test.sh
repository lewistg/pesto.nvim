#!/usr/bin/bash
#
# This script can be used as a manual test for pesto-bash-complete-bazel.sh
#
# Run this script in the the directory

set -euo pipefail

completion_script="$(dirname $0)/complete-bazel.sh"

coproc completion_script_proc { "$completion_script"; }

# Submit basic completion request
>&"${completion_script_proc[1]}" cat <<-EOF
cwd:$CWD
comp_line:bazel build //
compword_len:3
compword:bazel
compword:build
compword://
comp_point:23
comp_cword:2
EOF

# Output completions
while IFS= read -r line <&"${completion_script_proc[0]}"; do
    echo "$line"
done
