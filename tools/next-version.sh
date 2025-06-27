#!/bin/bash

# @filename next-version.sh
# @brief Generate the next version to tag the repository based on conventional
#        commits.

# @description Generate the next version; bear in mind that VERSION environment
# variable override the output for this function. The version printed out in the
# standard output follow the format "vMAJOR.MINOR.PATCH[-CHANGES][-dirty]" for
# instance: "v1.0.0", "v1.0.0-dirty", "v1.0.0-12-dirty", "v1.0.0-8"
# Where:
#   - MAJOR is the major version; it is incremented when a breaking change is
#     found.
#   - MINOR is the minor version; it is incremented when a feature change is
#     found.
#   - PATCH is the patch version; it is incremented when a fix is found.
#   - CHANGES is a number representing how many commits exists from the last
#     tagged version.
#   - "-dirty" is added when we have a repository state that has new files or
#     pending changes in stage to commit.
version_generate() {
    # Get the first commit hash
    local FIRST_COMMIT
    FIRST_COMMIT="$(git rev-list --max-parents=0 HEAD)"

    # Get the last tagged commit
    local LAST_TAG_COMMIT
    LAST_TAG_COMMIT="$(git describe --tags HEAD^ 2>/dev/null)"
    LAST_TAG_COMMIT="${LAST_TAG_COMMIT%%-*}"

    local BEGIN_COMMIT
    if [ "${LAST_TAG_COMMIT}" == "" ]; then
        # Last tag commit
        BEGIN_COMMIT="${FIRST_COMMIT}"
    else
        # From the first repo commit
        BEGIN_COMMIT="${LAST_TAG_COMMIT}"
    fi

    local version
    if [ -n "${VERSION}" ]; then
        version="${VERSION}"
    elif [ -e ".git" ]; then
        version="$(git describe --tags --dirty 2>/dev/null)"
        if [ "${version:0:1}" != "v" ]; then
            version="v1.0.0"
            printf "%s\n" "${version}"
            exit 0
        else
            version="${version%%-*}"
        fi
    else
        version="unknown"
    fi

    version_major="${version#v}"
    version_major="${version_major%%.*}"
    version_minor="${version#v*.}"
    version_minor="${version_minor%%.*}"
    version_patch="${version#v*.}"
    version_patch="${version_patch#*.}"
    version_patch="${version_patch%%-*}"

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
    version="v${version_major}.${version_minor}.${version_patch}"

    printf "%s\n" "${version}"
}

version_main() {
    version_generate
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    version_main "$@"
    exit $?
fi
