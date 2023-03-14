#!/bin/bash
function query_channels() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2^^}"; shift ;; # uppercase
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    ALL_CHANNELS="[]"
    PAGE=1
    QUERY_OUTPUT=
    while [[ $PAGE -gt 0 ]]; do
        echo "query page $PAGE" >&2
        printf -v QUERY_CMD "$CLI query ibc channel channels --page %s" "$PAGE"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
        CHANNELS=`echo $QUERY_OUTPUT | jq ".data.channels"`
        LENGTH=`echo $CHANNELS | jq length`
        echo "length $LENGTH" >&2
        if [[ $LENGTH == 0 ]];then
            break
        fi
        ALL_CHANNELS=`echo "$ALL_CHANNELS" | jq ". + $CHANNELS"`
        PAGE=`expr $PAGE + 1`
    done
    echo $QUERY_OUTPUT | jq "{ cmd: .cmd, data: $ALL_CHANNELS}"
}