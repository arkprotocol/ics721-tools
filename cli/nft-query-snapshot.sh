#!/bin/bash
function nft_query_snapshot() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="$2"; shift ;;
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

    ALL_TOKENS_OUTPUT=`ark query collection tokens --chain $CHAIN --collection $COLLECTION`
    ALL_TOKENS_EXIT_CODE=$?
    if [[ "$ALL_TOKENS_EXIT_CODE" -ne 0 ]]; then
        return $ALL_TOKENS_EXIT_CODE;
    fi
    if [ "$ICS721_MODULE" == wasm ]
    then
        echo "!!!! ==== Please have some good time with your friends! This query takes ~2tokens per second! ==== !!!!" >&2
        # all tokens is in format: ["id1", "id2", ...]
        SNAPSHOT="[]"
        for ROW in $(echo $ALL_TOKENS_OUTPUT | jq -r '.data[] | @base64'); do # base encode since it may have spaces!
            TOKEN_ID=`echo ${ROW} | base64 --decode`
            echo "\"$TOKEN_ID\"" >&2
            printf -v ALL_NFT_INFO_MSG '{"all_nft_info":{"token_id": "%s"}}' "$TOKEN_ID"
            printf -v ALL_NFT_INFO_CMD "$CLI query wasm contract-state smart \
%s \
'%s'" \
"$COLLECTION" \
"$ALL_NFT_INFO_MSG"
            ALL_NFT_INFO_OUTPUT=`execute_cli "$ALL_NFT_INFO_CMD" 2>/dev/null`
            ALL_NFT_INFO_EXIT_CODE=$?
            if [[ "$ALL_NFT_INFO_EXIT_CODE" -ne 0 ]]; then
                return $ALL_NFT_INFO_EXIT_CODE;
            fi
            TOKEN_INFO=`echo $ALL_NFT_INFO_OUTPUT | jq "{id: \"$TOKEN_ID\", owner: .data.data.access.owner}"`
            SNAPSHOT=`echo $SNAPSHOT | jq -c ". + [$TOKEN_INFO]"`
        done
        echo "ALL_NFT_INFO_OUTPUT: <$ALL_NFT_INFO_OUTPUT>" >&2
        RESULT=`echo $ALL_NFT_INFO_OUTPUT | jq "{cmd: \"ark query nft snapshot --collection $COLLECTION --chain $CHAIN\", data: $SNAPSHOT}"`

    else
        # all tokens is in format: [{"id": ..., "name": ..., "owner": ...}, ...]
        RESULT="$ALL_TOKENS_OUTPUT"

    fi

    if [ ! -z "$RESULT" ]
    then
        echo $RESULT
        return 0
    else
        echo "no tokens founds!" >&2
        return 1
    fi
}

export -f nft_query_snapshot