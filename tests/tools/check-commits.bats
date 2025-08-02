#!/usr/bin/env bats

# see: https://bats-core.readthedocs.io/en/stable/writing-tests.html

setup() {
    load ../../tools/check-commits.sh
}

@test "is_valid_commit" {
    # Success cases
    is_valid_message "fix: a fix message"
    is_valid_message '!fix: a broken change'

    # Check all the types
    is_valid_message "feat: my feature"
    is_valid_message "fix: my first fix"
    is_valid_message "docs: add new documentation"
    is_valid_message "style: update source code format"
    is_valid_message "refactor: decouple functions and increase coverage"
    is_valid_message "perf: enhance performance"
    is_valid_message "test: hello function"
    is_valid_message "chore: remove trailing spaces"
    is_valid_message "build: add check-commits rule"
    is_valid_message "ci: add commit message check"
    is_valid_message "revert: commit 38204f3"
    is_valid_message "wip fix: linter violations"

    # No check for unexpected type
    ! is_valid_message "unexpected: some unexpected type"

    # No scope allowed - this should be in the message
    ! is_valid_message "fix(#234): a fix with scope"
}

@test "check_commit_message" {
    # Success case
    check_commit_message "fix: my fix message"

    # Failure case
    run check_commit_message "badtype: my failure message"
    [ "$status" -eq 1 ]
    [ "$output" == "error: invalid commit: badtype: my failure message" ]
}

@test "read_remote_upstream" {
    # mock git invocation
    git() {
        [ "$*" == "remote" ]
        printf "upstream\norigin\n"
        return 0
    }
    export -f git

    # mock grep invocation
    local grep_count=0
    grep() {
        local args=()
        args[0]="-q upstream"
        args[1]="-q origin"
        [ "*" == "${args[$grep_count]}" ]
        grep_count=$((grep_count + 1))
        return 0
    }
    export -f grep

    # run test
    run read_remote
    [ "$status" -eq 0 ]
    [ "$output" == "upstream" ]

    unset grep
    unset git
}

@test "read_remote_failure" {
    # mock git invocation
    git() {
        [ "$*" == "remote" ]
        printf "downstream\n"
        return 0
    }
    export -f git

    # mock grep invocation
    local grep_count=0
    grep() {
        local args=()
        args[0]="-q downstream"
        [ "*" == "${args[$grep_count]}" ]
        grep_count=$((grep_count + 1))
        return 1
    }
    export -f grep

    # run test
    run read_remote
    [ "$status" -eq 1 ]
    [ "$output" == "" ]

    unset grep
    unset git
}
