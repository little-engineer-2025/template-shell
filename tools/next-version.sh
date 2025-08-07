#!/bin/bash

# @filename next-version.sh
# @brief Generate the next version to tag the repository based on conventional
#        commits.

first_repo_commit() {
    git rev-list --max-parents=0 HEAD
}

last_tag_commit() {
    result="$(git describe --tags HEAD^ 2>/dev/null)"
    result="${result%%-*}"
    printf "%s" "${result}"
}

describe_version() {
    git describe --tags --dirty 2>/dev/null
}

has_major_changes() {
    local begin_commit="$1"
    local end_commit="$2"
    [ "$(git log "${begin_commit}..${end_commit}" --grep="^!" --format="%s")" != "" ]
}

has_minor_changes() {
    local begin_commit="$1"
    local end_commit="$2"
    [ "$(git log "${begin_commit}..${end_commit}" --grep="^feat:" --format="%s")" != "" ]
}

has_patch_changes() {
    local begin_commit="$1"
    local end_commit="$2"
    [ "$(git log "${begin_commit}..${end_commit}" --grep="^fix:" --format="%s")" != "" ]
}

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
    FIRST_COMMIT="$(first_repo_commit)"

    # Get the last tagged commit
    local LAST_TAG_COMMIT
    LAST_TAG_COMMIT="$(last_tag_commit)"

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
        version="$(describe_version)"
        # NOTE This check could vary depending on the versioning
        if [ "${version:0:1}" != "v" ]; then
            version="v0.1.0"
            printf "%s\n" "${version}"
            return 0
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
    if has_major_changes "${BEGIN_COMMIT}" HEAD; then
        version_major=$((version_major + 1))
        version_minor="0"
        version_patch="0"
    elif has_minor_changes "${BEGIN_COMMIT}" HEAD; then
        version_minor=$((version_minor + 1))
        version_patch="0"
    elif has_patch_changes "${BEGIN_COMMIT}" HEAD; then
        version_patch=$((version_patch + 1))
    else
        version_patch=$((version_patch + 1))
    fi
    version="v${version_major}.${version_minor}.${version_patch}"

    printf "%s\n" "${version}"
}

main() {
    version_generate
}

if [ "$(realpath "${BASH_SOURCE[0]}")"  == "$(realpath "$0")"  ]; then
    main "$@"
    exit $?
fi
