#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Alejandro Visiedo <alejandro.visiedo@gmail.com>
#
# Requires: check.lib.sh

LOG_DEBUG=1
LOG_TRACE=2
LOG_INFO=3
LOG_WARNING=4
LOG_ERROR=5
LOG_FATAL=6

LOG_DEFAULT="${LOG_INFO}"
LOG_CURRENT="${LOG_DEFAULT}"

log_debug() {
    [ ! $LOG_DEBUG -ge $LOG_CURRENT ] || printf "debug: %s\n" "$*" >&2
}

log_trace() {
    [ ! $LOG_TRACE -ge $LOG_CURRENT ] || printf "trace: %s\n" "$*" >&2
}

log_info() {
    [ ! $LOG_INFO -ge $LOG_CURRENT ] || printf "info: %s\n" "$*" >&2
}

log_warning() {
    [ ! $LOG_WARNING -ge $LOG_CURRENT ] || printf "warning: %s\n" "$*" >&2
}

log_error() {
    [ ! $LOG_ERROR -ge $LOG_CURRENT ] || printf "error: %s\n" "$*" >&2
}

log_fatal() {
    [ ! $LOG_FATAL -ge $LOG_CURRENT ] || printf "fatal: %s\n" "$*" >&2
    exit 1
}

log_set_level() {
    local new_level="$1"
    is_number "${new_level}"
    if [ "${new_level}" -lt $LOG_DEBUG ]; then
        return 1
    elif [ "${new_level}" -gt $LOG_FATAL ]; then
        return 1
    fi
    LOG_CURRENT="${new_level}"
}

log_level() {
    return $LOG_CURRENT
}
