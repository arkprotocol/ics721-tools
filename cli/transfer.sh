#!/bin/bash
ARGS="$@" # backup all args

# get function in case not yet initialised
[[ ! $(type -t call_until_success) == function ]] && source ./call-until-success.sh

function transfer_ics721() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --recipient) RECIPIENT="$2"; shift ;;
            --source-class-id) SOURCE_CLASS_ID="$2"; shift ;;
            --target-chain) TARGET_CHAIN="${2,,}"; shift ;; # lowercase
            --source-channel) SOURCE_CHANNEL="${2}"; shift ;;
            --relay) RELAY="true";;
            *) echo "Unknown parameter: $1" >&2; return 1 ;;
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

    if [ -z "$RECIPIENT" ]
    then
        echo "--recipient is required" >&2
        return 1
    fi

    if [ -z "$TARGET_CHAIN" ]
    then
        echo "--target-chain is required" >&2
        return 1
    fi

    if [ -z "$SOURCE_CHANNEL" ]
    then
        echo "--source-channel is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ -z $FROM ]
    then
        echo "--from is required" >&2
        return 1
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        # ======== wasm module
        # ====== send token to ICS721 contract
        TIMESTAMP=`date -d "+1 day" +%s%N` # time in nano seconds
        printf -v RAW_MSG '{
            "receiver": "%s",
            "channel_id": "%s",
            "timeout": { "timestamp": "%s" } }'\
            "$RECIPIENT"\
            "$SOURCE_CHANNEL"\
            "$TIMESTAMP"
        echo "base64 encoding message for transfer to ICS721 contract: $RAW_MSG" >&2
        # Base64 encode msg
        MSG=`echo "$RAW_MSG" | base64 | xargs | sed 's/ //g'` # xargs concats multiple lines into one (with spaces), sed removes spaces
        printf -v EXECUTE_MSG '{
            "send_nft": {
                "contract": "%s",
                "token_id": "%s",
                "msg": "%s"}}'\
            "$CONTRACT_ICS721"\
            "$TOKEN"\
            "$MSG"
        CMD="$CLI tx wasm execute '$COLLECTION' '$EXECUTE_MSG'\
            --from "$FROM"\
            --gas-prices "$GAS_PRICES" --gas "$GAS" --gas-adjustment "$GAS_ADJUSTMENT"\
            -b "$BROADCAST_MODE" --yes"
    else
        # ======== nft-transfer module
        CMD="$CLI tx nft-transfer transfer '$ICS721_PORT' '$SOURCE_CHANNEL' '$RECIPIENT' '$COLLECTION' '$TOKEN'\
            --from "$FROM"\
            --fees "$FEES"\
            -b "$BROADCAST_MODE" --yes"
    fi

    echo "====> transferring $TOKEN (collection: $COLLECTION), from $CHAIN to $TARGET_CHAIN  <====" >&2
    CMD_OUTPUT=`execute_cli "$CMD"`
    # return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi
    TXHASH=`echo "$CMD_OUTPUT"|jq -r '.data.txhash'`
    if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
    then
        echo "ERROR no tx found!" >&2
        echo "$CMD_OUTPUT" >&2
        return 1
    fi

    # query tx for making sure it succeeds!
    ark query chain tx --cli "$CLI" --tx "$TXHASH" --max-call-limit "$MAX_CALL_LIMIT"
    # return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi

    if [ "$RELAY" = "true" ]; then
        echo "====> relaying $SOURCE_CHANNEL on $CHAIN <====" >&2
        echo "hermes --config ../config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $ICS721_PORT" >&2
        hermes --config ../config.toml clear packets --chain "$CHAIN_ID" --channel "$SOURCE_CHANNEL" --port "$ICS721_PORT" >&2
    fi

    # ====== check receival on target chain
    # - for target class id, we need: dest port, dest channel, source classId
    echo "====> query counter-part channel for $SOURCE_CHANNEL <====" >&2
    SOURCE_CHANNEL_OUTPUT=`ark query channel channel --chain "$CHAIN" --channel "$SOURCE_CHANNEL"`
    # - return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi
    SOURCE_PORT=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.port_id'`
    TARGET_CHANNEL=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.counterparty.channel_id'`
    TARGET_PORT=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.counterparty.port_id'`
    if [ -z "$SOURCE_CLASS_ID" ]
    then
        echo "--source-class-id not defined, using collection $COLLECTION" >&2
        SOURCE_CLASS_ID="$COLLECTION"
    fi
    echo "====> find class-id at $TARGET_CHAIN, target port: $TARGET_PORT, target channel: $TARGET_CHANNEL, source class id: $SOURCE_CLASS_ID <====" >&2
    printf -v QUERY_TARGET_COLLECTION_CMD "ark query ics721 class-id\
        --chain %s\
        --dest-port %s\
        --dest-channel %s\
        --source-class-id %s\
        --sleep 1\
        --max-call-limit %s"\
        "$TARGET_CHAIN"\
        "$TARGET_PORT"\
        "$TARGET_CHANNEL"\
        "$SOURCE_CLASS_ID"\
        "$MAX_CALL_LIMIT"
    QUERY_TARGET_COLLECTION_OUTPUT=`execute_cli "$QUERY_TARGET_COLLECTION_CMD"`
    # return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        echo "error query target collection $QUERY_TARGET_COLLECTION_OUTPUT " >&2
        return $EXIT_CODE
    fi
    TARGET_COLLECTION=`echo "$QUERY_TARGET_COLLECTION_OUTPUT" | jq -r '.data.collection'`
    TARGET_CLASS_ID=`echo "$QUERY_TARGET_COLLECTION_OUTPUT" | jq -r '.data.class_id'`
    if [[ ! ${TARGET_COLLECTION+x} ]] || [[ ${TARGET_COLLECTION} = null ]];then
        echo "No collection found: $TARGET_COLLECTION, output: $QUERY_TARGET_COLLECTION_OUTPUT" >&2
        return 1
    fi
    # make sure token is owned by recipient on target chain
    echo "====> query token $TOKEN at $TARGET_CHAIN and collection $TARGET_COLLECTION <====" >&2
    printf -v QUERY_TARGET_TOKEN_CMD "ark query collection token\
        --chain %s\
        --collection %s\
        --token %s" "$TARGET_CHAIN" "$TARGET_COLLECTION" "$TOKEN"
    QUERY_TARGET_TOKEN_OUTPUT=`call_until_success\
        --cmd "$QUERY_TARGET_TOKEN_CMD"\
        --max-call-limit $MAX_CALL_LIMIT\
        --sleep 1`
    # return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi
    TARGET_OWNER=`echo "$QUERY_TARGET_TOKEN_OUTPUT" | jq -r '.owner'`
    echo "====> NFT recipient on target chain: $TARGET_OWNER <====" >&2
    if [ "$RECIPIENT" = "$TARGET_OWNER" ]
    then
        echo NFT "$TOKEN" owned on target chain by "$RECIPIENT" >&2
    else
        echo ERROR, relay not successful, nft returned to owner "$FROM" >&2
        return 1
    fi

    ESCAPED_CMD=`echo $CMD | sed 's/"/\\\\"/g'` # escape double quotes
    echo "{}" | jq "{\
        cmd: \"$ESCAPED_CMD\",\
        tx: \"$TXHASH\",\
        source: {\
            chain: \"$CHAIN\",\
            collection: \"$COLLECTION\",\
            class_id: \"$SOURCE_CLASS_ID\",\
            channel: \"$SOURCE_CHANNEL\",\
            port: \"$SOURCE_PORT\"\
        },\
        target: {\
            chain: \"$TARGET_CHAIN\",\
            collection: \"$TARGET_COLLECTION\",\
            class_id: \"$TARGET_CLASS_ID\",\
            channel: \"$TARGET_CHANNEL\",\
            port: \"$TARGET_PORT\"\
        }\
    }"
}
