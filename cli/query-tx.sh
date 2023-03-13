#!/bin/bash
function query_tx() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --cli) CLI="$2"; shift ;;
            --tx) TX="$2"; shift ;;
            --max-call-limit) MAX_CALL_LIMIT="$2"; shift ;;
            *) echo "Unknown parameter: $1" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CLI" ]
    then
        echo "--tx is required" >&2
        return 1
    fi

    if [ -z "$TX" ]
    then
        echo "--tx is required" >&2
        return 1
    fi

    if [ -z "$MAX_CALL_LIMIT" ]
    then
        MAX_CALL_LIMIT=30
        echo "--max-call-limit not defined, set max call to $MAX_CALL_LIMIT" >&2
    fi

    # source in case not yet initialised
    source ./call-until-success.sh >&2

    QUERY_CMD="$CLI query tx $TX"
    call_until_success --cmd "$QUERY_CMD" --max-call-limit "$MAX_CALL_LIMIT"
}