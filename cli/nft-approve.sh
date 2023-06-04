#!/bin/bash

function nft_approve() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --spender) SPENDER="$2"; shift ;;
            --duration) DURATION="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$FROM" ]
    then
        echo "--from is required" >&2
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

    if [ -z "$SPENDER" ]
    then
        echo "--SPENDER is required" >&2
        return 1
    fi

    if [ -z "$DURATION" ]
    then
        echo "NOTE: approval duration will be set for next 2 minutes. Or pass --duration [\"+2 minutes\"|\"+2 days\"]." >&2
        DURATION="+2 minutes"
    fi

    if [[ "$ICS721_MODULE" == wasm ]]
    then
        echo "====> wait for NFT $TOKEN is owned by $FROM <====" >&2
        printf -v ASSERT_TOKEN_QUERY_CMD "ark assert nft token-owner \
--collection $COLLECTION \
--token $TOKEN \
--owner $FROM \
--max-call-limit $MAX_CALL_LIMIT"
        echo "$ASSERT_TOKEN_QUERY_CMD " >&2
        ASSERT_TOKEN_QUERY_OUTPUT=$($ASSERT_TOKEN_QUERY_CMD)
        # return in case of error
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            echo "$ASSERT_TOKEN_QUERY_OUTPUT" >&2
            return $EXIT_CODE
        fi

        echo "====> approving NFT $TOKEN for spender $SPENDER <====" >&2
        printf -v MSG '{"approve": {"spender": "%s", "token_id":"%s", "expires": {"at_time": "%s"}}}' \
"$SPENDER" "$TOKEN" $(date -d "$DURATION" +%s%N) # approval for 2 minutes
        APPROVAL_CMD="$CLI tx wasm execute $COLLECTION '$MSG' --from $WALLET_MINTER --gas-prices $GAS_PRICES --gas $GAS --gas-adjustment $GAS_ADJUSTMENT -b $BROADCAST_MODE --yes"
    else
        echo "Approve not supported for module $ICS721_MODULE" >&2
        return 1
    fi

    echo "step 1" >&2
    APPROVAL_CMD_OUTPUT=`execute_cli "$APPROVAL_CMD"`
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]
    then
        echo "$APPROVAL_CMD_OUTPUT" >&2
        return "$EXIT_CODE"
    fi
    TXHASH=`echo $APPROVAL_CMD_OUTPUT | jq -r '.data.txhash'`
    if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
    then
        echo "ERROR no tx found!" >&2
        echo $APPROVAL_CMD_OUTPUT >&2
        return 1
    fi

    # query tx for making sure it succeeds!
    QUERY_OUTPUT=`query_tx --chain $CHAIN --tx $TXHASH --max-call-limit $MAX_CALL_LIMIT`
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]
    then
        echo "$QUERY_OUTPUT" >&2
        return "$EXIT_CODE"
    fi

    INITIAL_CMD=`echo $APPROVAL_CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
    RESULT=`echo "{}" | jq "{ cmd: \"$INITIAL_CMD\", data: {tx: \"$TXHASH\", id: \"$TOKEN\", collection: \"$COLLECTION\", spender: \"$SPENDER\", duration: \"$DURATION\"}}"`
    echo $RESULT | jq
}

export -f nft_approve