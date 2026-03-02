#!/usr/bin/bash
#
# This script gets bash command line completions. The Bazel's bash completion
# script is rather large, so this script works as a daemon.
#
# Keep in sync with lua/pesto/cli/bazel_bash_completion/bazel_bash_completion_client.lua
#
# See: The "Programmable Completion" section in `man bash`.
#
# Arguments:
#   The Bazel completion script path

set -euo pipefail

BAZEL_COMPLETION_SCRIPT="${1:-"/etc/bash_completion.d/bazel"}"
LOGGING_ENABLED="${2:-"false"}"
SCRIPT_NAME="$(realpath "$0")"

if [[ ! -f "$BAZEL_COMPLETION_SCRIPT" ]]; then
    echo "error:could not find completion script: $BAZEL_COMPLETION_SCRIPT" >&2
    exit 1
fi

source "$BAZEL_COMPLETION_SCRIPT"

read -ra bazel_comp_spec < <(complete -p bazel)
for ((i=0; i<${#bazel_comp_spec[@]}; i+=1)); do
    if [[ ${bazel_comp_spec[i]} = "-F" ]]; then
        bazel_complete_function="${bazel_comp_spec[((i + 1))]}"
        break
    fi
done

if [[ -z "$bazel_complete_function" ]]; then
    echo "error:failed to parse bazel completion function" >&2
    exit 1
fi

function reset_comp_parameters() {
    COMP_LINE=""
    COMP_WORDS=()
}

function log() {
    if [[ "$LOGGING_ENABLED" = "true" ]]; then
        echo "$SCRIPT_NAME: $1" >> /tmp/pesto-complete-bazel.log
    fi
}

START_ARG_TYPE="cwd"
expected_arg_type="$START_ARG_TYPE"
compword_len=0
compword_index=0

while true; do
    IFS="" read -r line

    log "received line: $line"

    arg="${line#*:}"
    arg_type="${line%%:*}"

    if [[ -z "$arg_type" || "$arg_type" != "$expected_arg_type" ]]; then
        echo "error:unexpected arg type \"$arg_type\" expected \"$expected_arg_type\""
        reset_comp_parameters
        continue
    fi

    case "$arg_type" in
        "reset")
            reset_comp_parameters
            expected_arg_type="$START_ARG_TYPE"
            ;;
        "cwd")
            cd "$arg"
            expected_arg_type="comp_line"
            ;;
        "comp_line")
            COMP_LINE="$arg"
            expected_arg_type="comp_word_len"
            ;;
        "comp_word_len")
            compword_len="$arg"
            compword_index=0
            COMP_WORDS=()
            expected_arg_type="comp_word"
            ;;
        "comp_word")
            COMP_WORDS+=("$arg")
            ((compword_index+=1))
            if [[ "$compword_index" -ge "$compword_len" ]]; then
                expected_arg_type="comp_point"
            fi
            ;;
        "comp_point")
            COMP_POINT="$arg"
            expected_arg_type="comp_cword"
            ;;
        "comp_cword")
            COMP_CWORD="$arg"
            expected_arg_type="done"
            ;;
        *)
            # Should never get here...
            echo "error:unexpected arg_type \"$arg_type\""
            ;;
    esac

    if [[ "$expected_arg_type" = "done" ]]; then
        log "finished parsing completion request"

        "$bazel_complete_function"

        echo "compreply_len:${#COMPREPLY[@]}"
        for ((i=0; i<"${#COMPREPLY[@]}"; i+=1)); do
            echo "compreply:${COMPREPLY["$i"]}"
        done

        expected_arg_type="$START_ARG_TYPE"
        reset_comp_parameters
    fi
done
