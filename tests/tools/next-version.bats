#!/usr/bin/env bats

# see: https://bats-core.readthedocs.io/en/stable/writing-tests.html

setup() {
    load ../../tools/next-version.sh
}

@test "first_repo_commit" {
    local mock_idx_git=0
    local mock_count_git=0
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("rev-list --max-parents=0 HEAD")
        rets+=(0)
        output+=("c69f53a126059f527c507e0dc028b1e790fbdef0")

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return ${rets[$mock_idx_git]}
        }
        exit 1
    }
    export -f git

    run first_repo_commit
    unset git
    [ "${status}" -eq 0 ]
    [ "${output}" == "c69f53a126059f527c507e0dc028b1e790fbdef0" ]
}

@test "last_tag_commit_no_tags" {
    local mock_idx_git=0
    local mock_count_git=0
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("describe --tags HEAD^")
        output+=("")
        rets+=(128)

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            ret=${rets[$mock_idx_git]}
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return $ret
        }
        exit 1
    }
    export -f git

    run last_tag_commit
    unset git
    printf "status=%s\n" "$status"
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}

@test "last_tag_commit_tag" {
    local mock_idx_git=0
    local mock_count_git=0
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("describe --tags HEAD^")
        output+=("v0.1.0")
        rets+=(128)

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            ret=${rets[$mock_idx_git]}
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return $ret
        }
        exit 1
    }
    export -f git

    run last_tag_commit
    unset git
    printf "status=%s\n" "$status"
    [ "${status}" -eq 0 ]
    [ "${output}" == "v0.1.0" ]
}

@test "describe_version" {
    local mock_idx_git=0
    local mock_count_git=0
    local expected_version="v1.0.0-10-dirty"
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("describe --tags --dirty")
        output+=("${expected_version}")
        rets+=(0)

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            ret=${rets[$mock_idx_git]}
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return $ret
        }
        exit 1
    }
    export -f git

    run describe_version
    unset git
    [ "${status}" -eq 0 ]
    printf "output=%s\n" "${output}"
    printf "expected_version=%s\n" "${expected_version}"
    [ "${output}" == "${expected_version}" ]
}

@test "has_major_changes_true" {
    git() {
        local args
        local ret
        local output
        args='log c69f53a126059f527c507e0dc028b1e790fbdef0..HEAD --grep=^! --format=%s'
        output="!feat: clean-up legacy api"
        [ "$*" == "${args}" ] && {
            printf "%s" "${output}"
            ret=0
        }
        [ "$*" != "${args}" ] && {
            printf "debug: args='%s'; output='%s'; ret='%s'\n" \
                "${args}" \
                "${output}" \
                "${ret}"
            ret=127
        }
        return $ret
    }
    export -f git

    run has_major_changes c69f53a126059f527c507e0dc028b1e790fbdef0 HEAD
    unset git
    printf "status=%s; output='%s'\n" "${status}" "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}

@test "has_major_changes_false" {
    git() {
        local args
        local ret
        local output
        args='log c69f53a126059f527c507e0dc028b1e790fbdef0..HEAD --grep=^! --format=%s'
        output=""
        [ "$*" == "${args}" ] && {
            printf "%s" "${output}"
            ret=1
        }
        [ "$*" != "${args}" ] && {
            printf "debug: args='%s'; output='%s'; ret='%s'\n" \
                "${args}" \
                "${output}" \
                "${ret}"
            ret=127
        }
        return $ret
    }
    export -f git

    run has_major_changes c69f53a126059f527c507e0dc028b1e790fbdef0 HEAD
    unset git
    printf "status=%s; output='%s'\n" "${status}" "${output}"
    [ "${status}" -eq 1 ]
    [ "${output}" == "" ]

}

@test "has_minor_changes" {
    local mock_idx_git=0
    local mock_count_git=0
    local begin_commit="c69f53a126059f527c507e0dc028b1e790fbdef0"
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("log c69f53a126059f527c507e0dc028b1e790fbdef0..HEAD --grep=^feat: --format=%s")
        output+=("feat: add new subcommand")
        rets+=(0)

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            ret=${rets[$mock_idx_git]}
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return $ret
        }
        exit 1
    }
    export -f git

    run has_minor_changes "${begin_commit}" HEAD
    unset git
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}

@test "has_patch_changes" {
    local mock_idx_git=0
    local mock_count_git=0
    local begin_commit="c69f53a126059f527c507e0dc028b1e790fbdef0"
    git() {
        local args=()
        local rets=()
        local output=()
        args+=("log ${begin_commit}..HEAD --grep=^fix: --format=%s")
        output+=("fix: add route to POST /events")
        rets+=(0)

        [ "$*" == "${args[$mock_idx_git]}" ] && {
            printf "%s" "${output[$mock_idx_git]}"
            ret=${rets[$mock_idx_git]}
            mock_idx_git=$((mock_idx_git + 1))
            mock_count_git=$((mock_count_git + 1))
            return $ret
        }
        exit 1
    }
    export -f git

    run has_patch_changes "${begin_commit}" HEAD
    unset git
    [ "${status}" -eq 0 ]
    [ "${output}" == "" ]
}
