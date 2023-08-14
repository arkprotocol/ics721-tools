#!/bin/bash
function query_tx() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --chain) CHAIN="$2"; shift ;;
            --tx) TX="$2"; shift ;;
            --max-call-limit) MAX_CALL_LIMIT="$2"; shift ;;
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
    source "$ARK_CLI_DIR"/call-until-success.sh >&2

    QUERY_CMD="$CLI query tx $TX"
    call_until_success --cmd "$QUERY_CMD" --max-call-limit "$MAX_CALL_LIMIT"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi
}

export -f query_tx