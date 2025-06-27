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
    local version
    if [ -n "${VERSION}" ]; then
        version="${VERSION}"
    elif [ -e ".git" ]; then
        version="$(git describe --tags --dirty 2>/dev/null)"
        if [ "${version:0:1}" != "v" ]; then
            version="v1.0.0"
        fi
    else
        version="unknown"
    fi
    printf "%s\n" "${version}"
}

version_main() {
    version_generate
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    version_main "$@"
    exit $?
fi
