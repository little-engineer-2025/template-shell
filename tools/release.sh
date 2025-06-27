#!/bin/bash

##
# @file release.sh
# @brief Script for tagging with a changelog the repository.
##

release_is_version() {
    local version="$1"
    [[ "${version}" =~ ^v([:digit:]+).([:digit:]+).([:digit:]+)$ ]]
}

release_is_on_sync() {
    local version="$1"
    ! release_is_version "${version}" && [[ "${version}" =~ ^v[:digit:]+.[:digit:]+.[:digit:]+(-[:digit:]+)?(-dirty)?$ ]]
}

release_is_dirty() {
    local version="$1"
    ! release_is_version "${version}" && [[ "${version}" =~ ^v[:digit:]+.[:digit:]+.[:digit:]+(-[:digit:]+)?-dirty$ ]]
}

# @describe Check version string
release_version_check() {
    local version="$1"
    ! release_is_on_sync "${version}" || {
        print "error: there are changes pending to merge\n" >&2
        exit 1
    }
    ! release_is_dirty "${version}" || {
        print "error: there are changes pending to commit\n" >&2
        exit 1
    }
}

# @describe Generate changelog message
release_generate_changelog() {
    local version="$1"

    # Get the first commit hash
    local FIRST_COMMIT
    FIRST_COMMIT="$(git rev-list --max-parents=0 HEAD)"

    # Get the last tagged commit
    local LAST_TAG_COMMIT
    LAST_TAG_COMMIT="$(git describe --tags --abrev=0 2>/dev/null)"

    local BEGIN_COMMIT

    if [ "${LAST_TAG_COMMIT}" == "" ]; then
        # Last tag commit
        BEGIN_COMMIT="${FIRST_COMMIT}"
    else
        # From the first repo commit
        BEGIN_COMMIT="${LAST_TAG_COMMIT}"
        version="v1.0.0-$(git rev-parse --short HEAD)"
        echo "Changes:"
    fi
    echo "BEGIN_COMMIT=${BEGIN_COMMIT}"

    # Get the commit range
            # --grep="^\!?(fix|feat|docs|style|refactor|perf|test|build|ci|chore):" \
    COMMITS="$(
        git log "${BEGIN_COMMIT}..HEAD" \
            --grep="^!fix:" \
            --grep="^fix:" \
            --grep="^!feat:" \
            --grep="^feat:" \
            --grep="^!docs:" \
            --grep="^docs:" \
            --grep="^!style:" \
            --grep="^style:" \
            --grep="^!refactor:" \
            --grep="^refactor:" \
            --grep="^!perf:" \
            --grep="^perf:" \
            --grep="^!test:" \
            --grep="^test:" \
            --grep="^!build:" \
            --grep="^build:" \
            --grep="^!ci:" \
            --grep="^ci:" \
            --grep="^!chore:" \
            --grep="^chore:" \
            --format="- %s (%h)"
    )"

    version_major="${version#v}"
    version_major="${version_major%%.*}"
    version_minor="${version#v*.}"
    version_minor="${version_minor%%.*}"
    version_patch="${version#v*.}"
    version_patch="${version_patch#*.}"
    version_patch="${version_patch%%-*}"

    printf "debug: version_major='%s' version_minor='%s' version_patch='%s'\n" "${version_major}" "${version_minor}" "${version_patch}"

    # Check for broken changes
    if [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^!")" != "" ]; then
        version_major=$((version_major + 1))
        version_minor="0"
        version_patch="0"
    elif [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^feat:")" != "" ]; then
        version_minor=$((version_minor + 1))
        version_patch="0"
    elif [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^fix:")" != "" ]; then
        version_patch=$((version_patch + 1))
    fi

    # Print the log output
    echo "Changes on ${version}:"
    echo "${COMMITS}"
}

# @describe tag current commit
release_tag_commit() {
    local version="$1"
    git tag -a "${version}" -m "TAG_MESSAGE"
}

# @describe Release entrypoint
release_main() {
    local version
    version="$(./tools/next-version.sh)"
    #local output="TAG_MESSAGE"
    local output="/dev/stdout"
    release_version_check "${version}"
    release_generate_changelog "${version}" >"${output}"
    echo release_tag_commit "${version}"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    release_main "$@"
    exit $?
fi
