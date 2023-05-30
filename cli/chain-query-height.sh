#!/bin/bash

function chain_query_height() {
    ARGS=$@ # backup args
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    ark select chain $CHAIN

    if [[ "$CLI" = iris ]];then
        # workaround since iris block query does not return JSON!
        NEXT_HEIGHT=`eval $CLI query block | grep height | tail -n 1 | cut -d'"' -f 2`
    else
        NEXT_HEIGHT=`$CLI query block | jq -r '.block.header.height'`
    fi
    echo "{\"chain\": \"$CHAIN\", \"height\": $NEXT_HEIGHT}"
}

export -f chain_query_height