#!/bin/bash

source "lib/log.lib.sh"

# Verify if there are some dependency to process
registry_check_any_dependency() {
    [ ${#deps[@]} -gt 0 ] || exit 0
}

# Verify if the prefix is ".lib.sh"
registry_is_lib() {
    local lib="$1"
    [ "${lib%%.lib.sh}" != "${lib}" ]
}

# Install dependencies at lib/ directory
registry-install() {
    registry_check_any_dependency
    local repo=""
    for ((i = 0; i < ${#deps[@]}; i++)); do
        item="${deps[$i]}"
        if registry_is_lib "$item"; then
            [ "${repo}" != "" ] || {
                log_fatal "no repository was specified for '${item}'"
            }
            local output
            output="$(mktemp /tmp/registry.XXXXXXX)"
            local version
            if [[ "${item}" =~ @ ]]; then
                version="${item#*@}"
                shellfile="${item%@*}"
            else
                version="latest"
                shellfile="${item}"
            fi
            [ ! -e "lib/${shellfile}" ] || continue
            log_info "Retrieving '${shellfile}@${version}' from '${repo}'"
            if [ "${version}" == "latest" ]; then
                for version in main master; do
                    curl -sLo "${output}" "${repo}/blob/${version}/${shellfile}" ||
                           curl -sLo "${output}" "https://${repo}/blob/${version}/lib/${shellfile}" ||
                           log_fatal "downloading 'https://${repo}/blob/${version}/lib/${shellfile}'"
                done
            else
                curl -sLo "${output}" "${repo}/blob/${version}/${shellfile}" ||
                       curl -sLo "${output}" "https://${repo}/blob/${version}/lib/${shellfile}" ||
                       log_fatal "downloading 'https://${repo}/blob/${version}/lib/${shellfile}'"
            fi
            mv "${output}" "lib/${shellfile}"
            log_info "'${shellfile}@${version}' updated"
            rm -f "${output}"
        else
            repo="${item}"
            log_trace "Changing to repo '${repo}'"
        fi
    done
}

# Show help text
registry-help() {
    cat <<EOF
  help     Show this information about the commands.
  install  Install the script dependencies at lib/
EOF
}

# Assure .git directory exist
check_git_dir() {
    [ -e ".git" ] || {
        printf "error: it is expected to run from a repository base\n" >&2
        exit 1
    }
}

# Assure dependencies.sh exists
check_dependencies_exist() {
    [ -e "dependencies.sh" ] || {
        printf "warning: no 'dependencies.sh' file was found: nothing to install\n" >&2
        exit 0
    }
}

# run global checks
registry_global_checks() {
    check_git_dir
    check_dependencies_exist
}

# main registry function
main() {
    registry_global_checks

    # Include dependencies.sh
    source "dependencies.sh"

    local cmd="$1"
    shift 1
    case "$cmd" in
        "install" | "help")
            "registry-${cmd}" "$@"
            ;;
        *) ;;
    esac
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    set -e
    main "$@"
fi
