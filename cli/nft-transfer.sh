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
    TRANSFER_CMD_OUTPUT=`execute_cli "$TRANSFER_CMD"`
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]
    then
        echo "$TRANSFER_CMD_OUTPUT" >&2
        return "$EXIT_CODE"
    fi
    TXHASH=`echo $TRANSFER_CMD_OUTPUT | jq -r '.data.txhash'`
    if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
    then
        echo "ERROR no tx found!" >&2
        echo $TRANSFER_CMD_OUTPUT >&2
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

    #clear;tx=`iris tx nft transfer iaa1488wwr235vka7j722hzacpk0plxw33ksqyneuz ibc/571895A89A58FFE9FE57C36DC949D647C0B6A900FCA2531905CAECCA30FC86DB gir1/taitruong --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f -y --output json --fees 2000uiris | jq -r '.txhash'`; echo $tx; while [[ -z "" ]]; do iris query tx $tx --output json | jq '.height';done
    echo "succesfully transferred, tx: $TXHASH" >&2

}