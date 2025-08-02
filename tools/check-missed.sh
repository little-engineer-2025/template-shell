#!/bin/bash

source "lib/log.lib.sh"

##
# Check missed actions in the repository
##

has_pending_commits() {
    [ "$(git status --porcelain | wc -l)" -ne 0 ]
}

check_missed_format() {
    make format &>/dev/null || true
    ! has_pending_commits
}

check_missed_linter() {
    make lint &>/dev/null
}

check_failed_test() {
    make test &>/dev/null
}

check_pending_commits() {
    ! has_pending_commits
}

check_commit_messages() {
    ! ./tools/check-commits.sh
}

main() {
    local checks=()
    local msgs=()
    checks+=("check_pending_commits")
    msgs+=("check 'git status'")

    checks+=("check_missed_format")
    msgs+=("you missed 'make format': check 'git status'")

    checks+=("check_missed_linter")
    msgs+=("you missed 'make lint': check 'make lint'")

    checks+=("check_failed_test")
    msgs+=("you missed 'make test': some test is failing")

    checks+=("check_commit_messages")
    msgs+=("align commits to conventional commits: see docs/CONTRIBUTING.md")

    for ((idx = 0; idx < ${#checks[@]}; idx++)); do
        "${checks[$idx]}" || {
            log_warning "${msgs[$idx]}" >&2
            return 1
        }
    done
}

if [ "$(realpath "${BASH_SOURCE[0]}")" == "$(realpath "$0")" ]; then
    main "$@"
    exit $?
fi
