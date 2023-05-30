#!/bin/bash

function nft_transfer() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --recipient) RECIPIENT="$2"; shift ;;
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

    if [ -z "$RECIPIENT" ]
    then
        echo "--recipient is required" >&2
        return 1
    fi

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

    echo "====> transferring NFT $TOKEN to recipient $RECIPIENT <====" >&2

    if [[ "$ICS721_MODULE" == wasm ]]
    then
        printf -v TRANSFER_MSG '{"transfer_nft": {"token_id":"%s", "recipient":"%s"}}' \
"$TOKEN" "$RECIPIENT"
        printf -v TRANSFER_CMD "$CLI tx wasm execute '$COLLECTION' '$TRANSFER_MSG' \
--from $FROM \
--gas-prices $GAS_PRICES \
--gas $GAS \
--gas-adjustment $GAS_ADJUSTMENT \
-b $BROADCAST_MODE --yes"
    else
        printf -v TRANSFER_CMD "$CLI tx $ICS721_MODULE transfer '$RECIPIENT' '$COLLECTION' '$TOKEN' \
--from $FROM \
--fees $FEES \
-b $BROADCAST_MODE --yes"
    fi

    # execute
    CALL_COUNT="$MAX_CALL_LIMIT"
    echo "$TRANSFER_CMD" >&2
    while [[ 1 -gt 0 ]]; do
        if [[ "$CALL_COUNT" -eq 0 ]]
        then
            echo "Max call limit reached" >&2
            echo $ERROR >&2
            return 1
        fi
        CALL_COUNT=$(($CALL_COUNT - 1))
        TRANSFER_CMD_OUTPUT=`execute_cli "$TRANSFER_CMD"`
        NFT_TRANSFER_EXIT_CODE=$?
        if [[ $NFT_TRANSFER_EXIT_CODE != 0 ]]
        then
            continue
        fi
        TXHASH=`echo $TRANSFER_CMD_OUTPUT | jq -r '.data.txhash'`
        if [[ -z "$TXHASH" ]] && [[ "$TXHASH" = null ]]
        then
            echo "ERROR no tx found!" >&2
            continue
        fi
        echo "TX: $TXHASH" >&2

        # query tx for making sure it succeeds!
        QUERY_OUTPUT=`query_tx --chain $CHAIN --tx $TXHASH --max-call-limit $MAX_CALL_LIMIT`
        QUERY_NFT_TRANSFER_TX_EXIT_CODE=$?
        if [[ $QUERY_NFT_TRANSFER_TX_EXIT_CODE == 0 ]]
        then
            break
        fi
    done

    echo "succesfully transferred, tx: $TXHASH" >&2
    echo "$QUERY_OUTPUT"
}

export -f nft_transfer