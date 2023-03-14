#!/bin/bash
function query_tokens() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN=""${2^^}""; shift ;; # uppercase
            --collection) COLLECTION="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$COLLECTION" ]
    then
        echo "--collection is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        printf -v QUERY_MSG '{"all_tokens":{"limit": 100}}'
        printf -v QUERY_CMD "$CLI query wasm contract-state smart\
            %s\
            '%s'"\
            "$COLLECTION"\
            "$QUERY_MSG"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
        TOKENS=`echo $QUERY_OUTPUT | jq '.data.data.tokens'`
    else
        printf -v QUERY_CMD "$CLI query $ICS721_MODULE collection '$COLLECTION'"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`

        if [ "$ICS721_MODULE" = nft ] || [ "$ICS721_MODULE" = collection ]
        then
            TOKENS=`echo $QUERY_OUTPUT | jq '.data.collection.nfts'`
        else
            TOKENS=`echo $QUERY_OUTPUT | jq '.data.onfts'`
        fi

    fi

    if [ ! -z "$TOKENS" ] && [ ! -z "$QUERY_OUTPUT" ]
    then
        COUNT=`echo $TOKENS | jq length`
        echo "$COUNT tokens found" >&2
        echo $QUERY_OUTPUT | jq "{ cmd: .cmd, data: $TOKENS}"
        return 0
    else
        echo "no collections found: $QUERY_OUTPUT" >&2
        return 1
    fi
}