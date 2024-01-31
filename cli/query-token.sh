#!/bin/bash
function query_token() {
    ARGS="$@"
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION_ID="$2"; shift ;; # NFT module
            --token) TOKEN_ID="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$COLLECTION_ID" ]
    then
        echo "--collection is required" >&2
        return 1
    fi

    if [ -z "$TOKEN_ID" ]
    then
        echo "--token is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        printf -v QUERY_MSG '{"all_nft_info":{"token_id": "%s"}}' "$TOKEN_ID"
        printf -v QUERY_CMD "$CLI query wasm contract-state smart\
            %s\
            '%s' --chain-id $CHAIN_ID --node $CHAIN_NODE"\
            "$COLLECTION_ID"\
            "$QUERY_MSG"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
        QUERY_OUTPUT=`echo $QUERY_OUTPUT | jq '{cmd: .cmd, data: .data.data, owner: .data.data.access.owner}'`
    else
        if [ "$ICS721_MODULE" = nft ] || [ "$ICS721_MODULE" = collection ]
        then
            printf -v QUERY_CMD "$CLI query $ICS721_MODULE token '$COLLECTION_ID' '$TOKEN_ID'"
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
            QUERY_OUTPUT=`echo $QUERY_OUTPUT | jq '{cmd: .cmd, data: .data, owner: .data.owner}'`
        else
            printf -v QUERY_CMD "$CLI query '$ICS721_MODULE' asset '$COLLECTION_ID' '$TOKEN_ID'"
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
            QUERY_OUTPUT=`echo $QUERY_OUTPUT | jq '{cmd: .cmd, data: .data, owner: .data.owner}'`
        fi
    fi

    if [ ! -z "$QUERY_OUTPUT" ]
    then
        echo $QUERY_OUTPUT
        return 0
    else
        echo "no collections found: $QUERY_OUTPUT" >&2
        return 1
    fi
}

export query_token