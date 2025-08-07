#!/bin/bash

##
# @file release.sh
# @brief Script for tagging with a changelog the repository.
# see: https://semver.org/
##

# @describe Check if the version is ready for release
release_is_version() {
    local version="$1"
    [[ "${version}" =~ ^v([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)$ ]]
}

# @describe Check version string
release_version_check() {
    local version="$1"
    release_is_version "${version}" || {
        printf "error: the %s version is not ready for release\n" "${version}"
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
    LAST_TAG_COMMIT="tags/$(git describe --tags HEAD 2>/dev/null)"
    LAST_TAG_COMMIT="${LAST_TAG_COMMIT%%-*}"

    local BEGIN_COMMIT

    if [ "${LAST_TAG_COMMIT}" == "" ]; then
        # Last tag commit
        BEGIN_COMMIT="${FIRST_COMMIT}"
    else
        # From the first repo commit
        BEGIN_COMMIT="${LAST_TAG_COMMIT}"
        version="v1.0.0"
    fi

    # Get the commit range selecting by conventional commit types
    cc_types=(fix feat docs style refactor perf test build ci chore)
    opts=()
    for item in "${cc_types[@]}"; do
        opts+=(--grep="^!${item}")
        opts+=(--grep="^${item}")
    done
    COMMITS="$(git log "${BEGIN_COMMIT}..HEAD" "${opts[@]}" --format="- %s (%h)")"

    version_major="${version#v}"
    version_major="${version_major%%.*}"
    version_minor="${version#v*.}"
    version_minor="${version_minor%%.*}"
    version_patch="${version#v*.}"
    version_patch="${version_patch#*.}"
    version_patch="${version_patch%%-*}"

    # Check for broken changes
    if [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^!" 2>&1)" != "" ]; then
        version_major=$((version_major + 1))
        version_minor="0"
        version_patch="0"
    elif [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^feat:" 2>&1)" != "" ]; then
        version_minor=$((version_minor + 1))
        version_patch="0"
    elif [ "$(git log "${BEGIN_COMMIT}..HEAD" --grep="^fix:" 2>&1)" != "" ]; then
        version_patch=$((version_patch + 1))
    fi
    version="v${version_major}.${version_minor}.${version_patch}"

    # Print the log output
    printf "Changes on %s:\n" "${version}"
    printf "%s\n" "${COMMITS}"
}

# @describe Release entrypoint
release_main() {
    local version
    version="$(./tools/next-version.sh)"
    local output="TAG_MESSAGE"
    release_version_check "${version}"
    release_generate_changelog "${version}" >"${output}"
    cat TAG_MESSAGE
    git tag "${version}" --file TAG_MESSAGE
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    release_main "$@"
    exit $?
fi
