#!/usr/bin/env bats

setup() {
    load ../hello.sh
}

@test "hello world" {
    result="$(main)"
    [ "${result}" == "Hello World!" ]
}
