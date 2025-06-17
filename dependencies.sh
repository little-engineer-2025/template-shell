#!/bin/bash
#
# Dependencies file written as a shell script
# It is an array of arrays where each item is:
# - First position indicate the source git repository.
# - Next are the shell scripts to retrieve.
deps=()
deps+=(github.com/avisiedo/shell-lib log.lib.sh)
