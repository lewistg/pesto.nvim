#!/usr/bin/bash
#
# This script gets bash command line completions. The Bazel's bash completion
# script is rather large, so this script works as a persistent "completion server".
#
# Keep in sync with lua/pesto/cli/bazel_bash_completion/bazel_bash_completion_client.lua
#
# See: The "Programmable Completion" section in `man bash`.
#
# Arguments:
#   - The command. Either "serve" or "health-check"
#   - The Bazel completion script path
#   - Whether logging is enabled or not

set -euo pipefail

#######################################
# Constants
#######################################

# See: The "Programmable Completion" section in `man bash`.
declare COMP_LINE
declare COMP_POINT
declare COMP_WORDS
declare COMP_CWORD

declare LOGGING_ENABLED

declare -r SCRIPT_NAME="$(realpath "$0")"

# The bazel completion function (e.g., the function set up by /etc/bash_completion.d)
declare BAZEL_COMPLETE_FUNCTION

#######################################
# Initializes the BAZEL_COMPLETE_FUNCTION
# Globals:
#   BAZEL_COMPLETE_FUNCTION
# Arguments:
#   Path to the bazel completion script (likely somewhere in /etc/bash_completion.d)
#######################################
function init_bazel_complete_function() {
    local bazel_completion_script="$1"

    if [[ ! -f "$bazel_completion_script" ]]; then
        echo "error:could not find completion script: $bazel_completion_script" >&2
        return 1
    fi

    source "$bazel_completion_script"

    read -ra bazel_comp_spec < <(complete -p bazel)
    for ((i=0; i<${#bazel_comp_spec[@]}; i+=1)); do
        if [[ ${bazel_comp_spec[i]} = "-F" ]]; then
            BAZEL_COMPLETE_FUNCTION="${bazel_comp_spec[((i + 1))]}"
            readonly BAZEL_COMPLETE_FUNCTION
            break
        fi
    done

    if [[ -z "$BAZEL_COMPLETE_FUNCTION" ]]; then
        echo "error: failed to set BAZEL_COMPLETE_FUNCTION" >&2
        return 1
    fi

    return 0
}

function reset_comp_parameters() {
    COMP_LINE=""
    COMP_WORDS=()
}

function log() {
    if [[ "$LOGGING_ENABLED" = "true" ]]; then
        echo "$SCRIPT_NAME: $1" >> /tmp/pesto-complete-bazel.log
    fi
}

#######################################
# Starts the bash completion server
# Globals:
#   COMP_LINE
#   COMP_WORDS
#   COMP_POINT
#   COMP_CWORD
# Arguments:
#   None
#######################################
function serve() {
    local START_ARG_TYPE="cwd"

    local expected_arg_type="$START_ARG_TYPE"

    local compword_len=0
    local compword_index=0

    while true; do
        IFS="" read -r line

        log "received line: $line"

        arg="${line#*:}"
        arg_type="${line%%:*}"

        if [[ -z "$arg_type" || "$arg_type" != "$expected_arg_type" ]]; then
            echo "error: unexpected arg type \"$arg_type\" expected \"$expected_arg_type\"" 2>&1
            return 1
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
                echo "error: unexpected arg_type \"$arg_type\"" >&2
                ;;
        esac

        if [[ "$expected_arg_type" = "done" ]]; then
            log "finished parsing completion request"

            "$BAZEL_COMPLETE_FUNCTION"

            echo "compreply_len:${#COMPREPLY[@]}"
            for ((i=0; i<"${#COMPREPLY[@]}"; i+=1)); do
                echo "compreply:${COMPREPLY["$i"]}"
            done

            log "sent response"

            expected_arg_type="$START_ARG_TYPE"
            reset_comp_parameters
        fi
    done
}

function main() {
    local command="$1"

    local bazel_completion_script="${2:-"/etc/bash_completion.d/bazel"}"

    LOGGING_ENABLED="${3:-"false"}"
    readonly LOGGING_ENABLED


    case "$command" in
        "serve")
            if ! init_bazel_complete_function "$bazel_completion_script"; then
                echo "error:failed to load bazel completion function"
                return 1
            fi
            log "starting server"
            serve
            return $?
            ;;
        "check-health")
            if ! init_bazel_complete_function "$bazel_completion_script"; then
                return 1
            fi
            ;;
        *)
            echo "error:unrecognized command: $command" >&2
            return 1
            ;;
    esac
}

main "$@"
