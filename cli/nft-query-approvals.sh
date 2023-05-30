#!/bin/bash
function nft_query_approvals() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="$2"; shift ;;
            --collection) COLLECTION="$2"; shift ;;
            --token) TOKEN="$2"; shift ;;
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

    if [ -z "$TOKEN" ]
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
        # owner_of query also contains approvals info
        printf -v QUERY_APPROVALS_MSG '{"owner_of": {"token_id": "%s"}}' "$TOKEN"
        printf -v QUERY_APPROVALS_CMD "$CLI query wasm contract-state smart $COLLECTION '$QUERY_APPROVALS_MSG'"
        QUERY_APPROVALS_OUTPUT=`execute_cli "$QUERY_APPROVALS_CMD"`
    else
        echo "Approvals not supported for module $ICS721_MODULE" >&2
        return 1
    fi

    echo $QUERY_APPROVALS_OUTPUT
}

export -f nft_query_approvals