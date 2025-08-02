#!/usr/bin/env bats

setup() {
    load ../../tools/check-missed.sh
}

@test "has_pending_commits_true" {
    git() {
        [ "$*" == "status --porcelain" ] && {
            printf "?? tests/tools/check-missed.bats\n"
            return 0
        }
        printf "args='%s'; ret=127\n" "$*"
        return 127
    }
    export -f git
    run has_pending_commits
    unset git
    printf "status=%s; output='%s'" "${status}" "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}

@test "has_pending_commits_false" {
    git() {
        [ "$*" == "status --porcelain" ] && {
            printf ""
            return 0
        }
        return 127
    }
    export -f git
    run has_pending_commits
    unset git
    unset wc
    printf "status=%s; output='%s'" "${status}" "${output}"
    [ "${status}" -eq 1 ]
    [ "${output}" == "" ]
}

@test "check_missed_format_true" {
    make() {
        [ "$*" == "format" ] && {
            printf "shfmt -i 4 -ci -kp -w  dependencies.sh hello.sh lib/log.lib.sh tests/hello_test.bats tests/tools/check-commits.bats tests/tools/check-missed.bats tests/tools/next-version.bats toolbox.sh tools/check-commits.sh tools/check-missed.sh tools/next-version.sh tools/registry.sh tools/release.sh\n"
            return 1
        }
        return 127
    }
    has_pending_commits() {
        [ "$*" == "" ] && {
            return 1
        }
    }
    export -f make has_pending_commits
    run check_missed_format
    unset make has_pending_commits
    printf "status=%s; output='%s'\n" "${status}" "${output}"
    [ "${status}" == 0 ]
    [ "${output}" == "" ]
}

@test "check_missed_format_false" {
    make() {
        [ "$*" == "format" ] && {
            printf "shfmt -i 4 -ci -kp -w  dependencies.sh hello.sh lib/log.lib.sh tests/hello_test.bats tests/tools/check-commits.bats tests/tools/check-missed.bats tests/tools/next-version.bats toolbox.sh tools/check-commits.sh tools/check-missed.sh tools/next-version.sh tools/registry.sh tools/release.sh\n"
            return 0
        }
        return 127
    }
    has_pending_commits() {
        [ "$*" == "" ] && {
            return 0
        }
    }
    export -f make has_pending_commits
    run check_missed_format
    unset make has_pending_commits
    printf "status=%s; output='%s'\n" "${status}" "${output}"
    [ "${status}" == 1 ]
    [ "${output}" == "" ]
}

@test "check_missed_linter_true" {
    make() {
        [ "$*" == "lint" ] && {
            return 0
        }
        return 127
    }
    run check_missed_linter
    unset make
    [ "${status}" == 0 ]
    [ "${output}" == "" ]
}

@test "check_missed_linter_false" {
    make() {
        [ "$*" == "lint" ] && {
            return 1
        }
        return 127
    }
    run check_missed_linter
    unset make
    printf "status=%s; output='%s'" "${status}" "${output}"
    [ "${status}" == 1 ]
    [ "${output}" == "" ]
}

@test "check_failed_test_true" {
    make() {
        [ "$*" == "test" ] && {
            return 0
        }
    }
    export -f make
    run check_failed_test
    unset make
    [ "${status}" -eq 0 ]
}

@test "check_failed_test_false" {
    make() {
        [ "$*" == "false" ] && {
            return 0
        }
    }
    export -f make
    run check_failed_test
    unset make
    [ "${status}" -ne 0 ]
}

@test "check_pending_commits_true" {
    has_pending_commits() {
        return 1
    }
    export -f has_pending_commits
    run check_pending_commits
    unset has_pending_commits
    [ "${status}" -eq 0 ]
}

@test "check_pending_commits_false" {
    has_pending_commits() {
        return 0
    }
    export -f has_pending_commits
    run check_pending_commits
    unset has_pending_commits
    [ "${status}" -ne 0 ]
}

# --- main

@test "main_fail_on_check_pending_commits" {
    check_pending_commits() {
        return 1
    }
    export -f check_pending_commits
    run main
    unset -f check_pending_commits
    printf "status=%s; output=%s\n" "${status}" "${output}"
    [ "${status}" -eq 1 ]
    [ "${output}" == "warning: check 'git status'" ]
}

@test "main_fail_on_check_missed_format" {
    check_pending_commits() {
        return 0
    }
    check_missed_format() {
        return 1
    }
    export -f check_pending_commits check_missed_format
    run main
    unset -f check_pending_commits check_missed_format
    [ "${status}" -eq 1 ]
    [ "${output}" == "warning: you missed 'make format': check 'git status'" ]
}

@test "main_fail_on_check_missed_linter" {
    check_pending_commits() {
        return 0
    }
    check_missed_format() {
        return 0
    }
    check_missed_linter() {
        return 1
    }
    export -f check_pending_commits check_missed_format check_missed_linter
    run main
    unset -f check_pending_commits check_missed_format check_missed_linter
    [ "${status}" -eq 1 ]
    [ "${output}" == "warning: you missed 'make lint': check 'make lint'" ]
}

@test "main_fail_on_check_failed_test" {
    check_pending_commits() {
        return 0
    }
    check_missed_format() {
        return 0
    }
    check_missed_linter() {
        return 0
    }
    check_failed_test() {
        return 1
    }
    export -f check_pending_commits check_missed_format check_missed_linter check_failed_test
    run main
    unset -f check_pending_commits check_missed_format check_missed_linter check_failed_test
    printf "status=%s; output=%s\n" "${status}" "${output}"
    [ "${status}" -eq 1 ]
    [ "${output}" == "warning: you missed 'make test': some test is failing" ]
}

@test "main_fail_on_check_commit_messages" {
    check_pending_commits() {
        return 0
    }
    check_missed_format() {
        return 0
    }
    check_missed_linter() {
        return 0
    }
    check_failed_test() {
        return 0
    }
    check_commit_messages() {
        return 1
    }
    export -f check_pending_commits check_missed_format check_missed_linter check_failed_test check_commit_messages
    run main
    unset -f check_pending_commits check_missed_format check_missed_linter check_failed_test check_commit_messages
    [ "${status}" -eq 1 ]
    [ "${output}" == "warning: align commits to conventional commits: see docs/CONTRIBUTING.md" ]
}

@test "main_success" {
    check_pending_commits() {
        return 0
    }
    check_missed_format() {
        return 0
    }
    check_missed_linter() {
        return 0
    }
    check_failed_test() {
        return 0
    }
    check_commit_messages() {
        return 0
    }
    export -f check_pending_commits check_missed_format check_missed_linter check_failed_test check_commit_messages
    run main
    unset -f check_pending_commits check_missed_format check_missed_linter check_failed_test check_commit_messages
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}
