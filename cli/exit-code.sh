#!/bin/bash

function exit_code() {
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        echo "EXIT_CODE: $EXIT_CODE" >&2
        return $EXIT_CODE
    fi
    return 0
}

export -f exit_code