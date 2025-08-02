#!/bin/bash

##
# @file check-commits.sh
# @brief script for github pipeline that check commits
#        are aligned with conventional commits.
# insights from: GPT-4o mini
##

is_valid_message() {
    local msg="$1"
    [[ "${msg}" =~ ^(wip[[:space:]])?\!?(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert):[[:space:]].*$ ]]
}

check_commit_message() {
    local msg="$1"
    if ! is_valid_message "${msg}"; then
        printf "error: invalid commit: %s\n" "${msg}" >&2
        return 1
    fi
    return 0
}

read_remote() {
    local priority=(upstream origin)
    for item in "${priority[@]}"; do
        if git remote | grep -q "${item}"; then
            printf "%s\n" "${item}"
            return 0
        fi
    done
    return 1
}

main() {
    local remote
    local ret=0
    remote="$(read_remote)"
    [ "${remote}" != "" ] || {
        printf "error: could not find an expected remote\n"
        return 1
    }
    export remote
    readarray -t commit_message <<<"$(git log "${remote}"/main..HEAD --pretty=format:%s)"
    ret=0
    for msg in "${commit_message[@]}"; do
        check_commit_message "${msg}" || ret=1
    done
    return $ret
}

if [ "$(realpath "${BASH_SOURCE[0]}")" == "$(realpath "$0")" ]; then
    main "$@"
    exit $?
fi
