#!/bin/bash

# Helper method, returns successful (exit code 0) when token is owned by recipient
function nft_assert_token_owner() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --owner) OWNER="$2"; shift ;;
            --max-call-limit) MAX_CALL_LIMIT="$2"; shift ;;
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

    if [ -z "$OWNER" ]
    then
        echo "--owner is required" >&2
        return 1
    fi

    if [ -z "$MAX_CALL_LIMIT" ]
    then
        echo "--max-call-limit is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [[ "$ICS721_MODULE" == wasm ]]
    then
        printf -v QUERY_TOKEN_CMD "ark query collection token --chain $CHAIN --collection $COLLECTION --token $TOKEN"
    else
        # workaround since single token query on uptick doesn't work yet - https://github.com/game-of-nfts/gon-evidence/issues/368
        printf -v QUERY_TOKEN_CMD "ark query collection tokens --chain $CHAIN --collection $COLLECTION"
    fi
    CALL_COUNT="$MAX_CALL_LIMIT"
    printf "$QUERY_TOKEN_CMD " >&2
    while [[ $CALL_COUNT -gt 0 ]];do
        QUERY_TOKEN_OUTPUT=$(call_until_success \
--cmd "$QUERY_TOKEN_CMD" \
--max-call-limit $MAX_CALL_LIMIT 2>/dev/null) # suppress error messages
        # return in case of error
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            printf "\n" >&2
            echo "$QUERY_TOKEN_OUTPUT" >&2
            return $EXIT_CODE
        fi
        if [[ "$ICS721_MODULE" == wasm ]]
        then
            # ======== wasm module
            TOKEN_OWNER=`echo $QUERY_TOKEN_OUTPUT | jq -r '.data.access.owner'`
        else
            # ======== nft-transfer module
            TOKEN_OWNER=`echo $QUERY_TOKEN_OUTPUT | jq -r ".data[] | select( .id | contains(\"$TOKEN\")) | .owner"`
        fi
        # break in case expected owner matches
        [[ "$OWNER" = "$TOKEN_OWNER" ]] && break

        # query again and check whether owner has changed
        CALL_COUNT=$(($CALL_COUNT - 1))
        if [ $CALL_COUNT -lt 1 ]
        then
            printf "\n" >&2
            echo "$QUERY_TOKEN_OUTPUT" >&2
            echo "Max call limit reached" >&2
            echo "$TOKEN owner: $TOKEN_OWNER, expected: $OWNER" >&2
            return 1
        fi
        printf "." >&2 # progress bar
    done;
    printf "\n" >&2

}