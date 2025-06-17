#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright (c) 9999  First and Last name <email@example.com>

[ "${BASH_SOURCE[0]}" == "$0" ] && BASEDIR="$(dirname "$(realpath "$0")")"

# shellcheck disable=SC1091
source "${BASEDIR}/lib/log.lib.sh"

main() {
    echo "Hello World!"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi
