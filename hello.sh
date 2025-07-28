#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright (c) 9999  First and Last name <email@example.com>

[ "$(realpath "${BASH_SOURCE[0]}")"  == "$(realpath "$0")" ] && BASEDIR="$(dirname "$(realpath "$0")")"

# shellcheck disable=SC1091
source "${BASEDIR}/lib/log.lib.sh"

main() {
    echo "Hello World!"
}

if [ "$(realpath "${BASH_SOURCE[0]}")"  == "$(realpath "$0")" ]; then
    main "$@"
    exit $?
fi
