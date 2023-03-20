#!/bin/bash

# get function in case not yet initialised
source ./call-until-success.sh
function ics721_transfer() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --recipient) RECIPIENT="$2"; shift ;;
            --target-chain) TARGET_CHAIN="${2,,}"; shift ;; # lowercase
            --source-channel) SOURCE_CHANNEL="${2}"; shift ;;
            --relay) RELAY="true";;
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

    # for checking NFT receival in collection on target chain, target channel and target port is needed
    # let's query as pre-task for saving time, before transferring, this way we also check whether channel is correct
    echo "====> query channel and its counter part (for NFT retrieval on target chain) <====" >&2
    SOURCE_CHANNEL_CMD="ark query channel channel --chain $CHAIN --channel $SOURCE_CHANNEL"
    SOURCE_CHANNEL_OUTPUT=$($SOURCE_CHANNEL_CMD 2>/dev/null)
    # - return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi
    SOURCE_PORT=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.port_id'`
    if [[ -z "$SOURCE_PORT" ]] || [[ "$SOURCE_PORT" = null ]];then
        echo "missing port_id" >&2
        return 1;
    fi
    TARGET_CHANNEL=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.counterparty.channel_id'`
    if [[ -z "$TARGET_CHANNEL" ]] || [[ "$TARGET_CHANNEL" = null ]];then
        echo "missing counterparty.channel_id" >&2
        return 1;
    fi
    TARGET_PORT=`echo "$SOURCE_CHANNEL_OUTPUT" | jq -r '.counterparty.port_id'`
    if [[ -z "$TARGET_PORT" ]] || [[ "$TARGET_PORT" = null ]];then
        echo "missing counterparty.channel_id" >&2
        return 1;
    fi
    echo "$SOURCE_CHANNEL_OUTPUT" | jq >&2

    echo "====> wait for NFT $TOKEN is owned by $FROM <====" >&2
    if [[ "$ICS721_MODULE" == wasm ]]
    then
        printf -v QUERY_TOKEN_CMD "ark query collection token --chain $CHAIN --collection $COLLECTION --token $TOKEN"
    else
        # workaround since single token query on uptick doesn't work yet - https://github.com/game-of-nfts/gon-evidence/issues/368
        printf -v QUERY_TOKEN_CMD "ark query collection tokens --chain $CHAIN --collection $COLLECTION"
    fi
    CALL_COUNT="$MAX_CALL_LIMIT"
    printf "$QUERY_TOKEN_CMD " >&2
    while [[ ! "$FROM" = "$TOKEN_OWNER" ]];do
        QUERY_TOKEN_OUTPUT=$(call_until_success \
--cmd "$QUERY_TOKEN_CMD" \
--max-call-limit $MAX_CALL_LIMIT 2>/dev/null)
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
        CALL_COUNT=$(($CALL_COUNT - 1))
        if [ $CALL_COUNT -lt 1 ]
        then
            printf "\n" >&2
            echo "$QUERY_TOKEN_OUTPUT" >&2
            echo "Max call limit reached" >&2
            return 1
        fi
        printf "." >&2 # progress bar
    done;
    printf "\n" >&2

    if [[ "$ICS721_MODULE" == wasm ]]
    then
        # ======== wasm module
        # ====== send token to ICS721 contract
        TIMESTAMP=`date -d "+5 min" +%s%N` # time in nano seconds, other options: "+1 day"
        printf -v RAW_MSG '{
"receiver": "%s",
"channel_id": "%s",
"timeout": { "timestamp": "%s" } }' \
"$RECIPIENT" \
"$SOURCE_CHANNEL" \
"$TIMESTAMP"
        echo "====> base64 encoding message for transfer to ICS721 contract <====" >&2
        echo "$RAW_MSG" | jq >&2
        # Base64 encode msg
        MSG=`echo "$RAW_MSG" | base64 | xargs | sed 's/ //g'` # xargs concats multiple lines into one (with spaces), sed removes spaces
        printf -v EXECUTE_MSG '{"send_nft": {
"contract": "%s",
"token_id": "%s",
"msg": "%s"}}'\
            "$CONTRACT_ICS721"\
            "$TOKEN"\
            "$MSG"
        CMD="$CLI tx wasm execute '$COLLECTION' '$EXECUTE_MSG' \
--from "$FROM" \
--gas-prices "$GAS_PRICES" \
--gas "$GAS" \
--gas-adjustment "$GAS_ADJUSTMENT" \
-b "$BROADCAST_MODE" \
--yes"
    else
        # ======== nft-transfer module
        # --packet-timeout-timestamp: packet timeout timestamp in nanoseconds from now (5min)
        CMD="$CLI tx nft-transfer transfer '$ICS721_PORT' '$SOURCE_CHANNEL' '$RECIPIENT' '$COLLECTION' '$TOKEN' \
--from "$FROM" \
--fees "$FEES" \
--packet-timeout-timestamp 300000000000 \
-b "$BROADCAST_MODE" \
--yes"
    fi

    BACKTRACK=false
    BACK_TO_HOME=false
    echo "====> transferring $TOKEN from $CHAIN to $TARGET_CHAIN, collection: $COLLECTION <====" >&2
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
    echo "====> waiting for TX $TXHASH <====" >&2
    printf -v TX_QUERY_CMD "ark query chain tx --chain %s --tx %s --max-call-limit %s" $CHAIN $TXHASH $MAX_CALL_LIMIT
    TX_QUERY_OUTPUT=`$TX_QUERY_CMD`
    # return in case of error
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]; then
        return $EXIT_CODE
    fi

    HERMES_CMD="hermes --config ../config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $ICS721_PORT >&2"
    echo "====> manually relaying $SOURCE_CHANNEL on $CHAIN <====" >&2
    if [ "$RELAY" = "true" ]; then
        echo "hermes --config ../config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $ICS721_PORT" >&2
        hermes --config ../config.toml clear packets --chain "$CHAIN_ID" --channel "$SOURCE_CHANNEL" --port "$ICS721_PORT" >&2
    else
        echo "skip: hermes --config ../config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $ICS721_PORT" >&2
    fi

    # ====== check receival on target chain
    # - for target class id, we need: dest port, dest channel, source classId
    # get class id from tx
    echo "====> retrieving target class id <====" >&2
    if [[ "$ICS721_MODULE" == wasm ]]
    then
        SOURCE_CLASS_ID=`echo "$TX_QUERY_OUTPUT" | jq '.data.logs[0].events[] | select(.type == "wasm") | .attributes[] | select(.key =="class_id")' | jq -r '.value'`
    else
        SOURCE_CLASS_ID=`echo "$TX_QUERY_OUTPUT" | jq -r '.data.tx.body.messages[0].class_id'`
        # ibc class is a hash like "ibc/hash", hash contains class id
        if [[ "$SOURCE_CLASS_ID" == ibc/* ]];then
            # get class id based on hash
            printf -v CLASS_TRACE_CMD "$CLI query nft-transfer class-trace $SOURCE_CLASS_ID"
            CLASS_TRACE_OUTPUT=`call_until_success \
--cmd "$CLASS_TRACE_CMD" \
--max-call-limit $MAX_CALL_LIMIT`
            # return in case of error
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]; then
                return $EXIT_CODE
            fi
            CLASS_TRACE_PATH=`echo $CLASS_TRACE_OUTPUT | jq -r '.data.class_trace.path'`
            if [[ -z "$CLASS_TRACE_PATH" ]] || [[ "$CLASS_TRACE_PATH" = null ]];then
                echo "missing .data.class_trace.path" >&2
                return 1;
            fi

            CLASS_TRACE_BASE_CLASS_ID=`echo $CLASS_TRACE_OUTPUT | jq -r '.data.class_trace.base_class_id'`
            if [[ -z "$CLASS_TRACE_BASE_CLASS_ID" ]] || [[ "$CLASS_TRACE_BASE_CLASS_ID" = null ]];then
                echo "missing .data.class_trace.base_class_id" >&2
                return 1;
            fi
            SOURCE_CLASS_ID=${CLASS_TRACE_PATH}/"$CLASS_TRACE_BASE_CLASS_ID"
        fi
    fi
    echo "source class id: $SOURCE_CLASS_ID" >&2
    if [[ -z "$SOURCE_CLASS_ID" ]] || [[ "$SOURCE_CLASS_ID" = null ]];then
        echo "missing class_id in tx $TXHASH" >&2
        return 1;
    fi

    # create target class id based on source class id
    # check if back track/returning back to previous chain
    if [[ $SOURCE_CLASS_ID = ${SOURCE_PORT}/${SOURCE_CHANNEL}* ]];then
        BACKTRACK=true
        # remove source port and source channel
        TARGET_CLASS_ID=${SOURCE_CLASS_ID#"${SOURCE_PORT}/${SOURCE_CHANNEL}/"}
        # home has no port and channel, so there is no slash ('/')!
        if [[ ! "$TARGET_CLASS_ID" = */* ]];then
            # transfer from 1st/home chain
            BACK_TO_HOME=true
        fi
    else
        TARGET_CLASS_ID="$TARGET_PORT/$TARGET_CHANNEL/$SOURCE_CLASS_ID"
    fi
    echo "target class id: $TARGET_CLASS_ID" >&2

    if [[ "$BACK_TO_HOME" = true ]]; then
        echo "Transferring back to home chain" >&2
        TARGET_COLLECTION=$TARGET_CLASS_ID
    else
        if [[ "$BACKTRACK" = true ]]; then
            echo "Transferring back to previous chain" >&2
            TARGET_COLLECTION=$TARGET_CLASS_ID
        fi
        echo "====> find collection at $TARGET_CHAIN with class id $TARGET_CLASS_ID <====" >&2
        printf -v QUERY_TARGET_COLLECTION_CMD "ark query ics721 class-id \
--chain %s \
--dest-port %s \
--class-id %s \
--sleep 1 \
--max-call-limit %s" \
"$TARGET_CHAIN" \
"$TARGET_PORT" \
"$TARGET_CLASS_ID" \
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
        echo "$QUERY_TARGET_COLLECTION_OUTPUT" | jq >&2
    fi

    # make sure token is owned by recipient on target chain
    echo "====> checking NFT $TOKEN, owned by $RECIPIENT on target chain $TARGET_CHAIN <====" >&2
    # switch and read env/config from target chain!
    SOURCE_CHAIN=$CHAIN # backup
    ark select chain $TARGET_CHAIN
    TARGET_CHAIN_ID=$CHAIN_ID
    if [[ "$ICS721_MODULE" == wasm ]]
    then
        printf -v QUERY_TARGET_TOKEN_CMD "ark query collection token --chain $TARGET_CHAIN --collection $TARGET_COLLECTION --token $TOKEN"
    else
        # workaround since single token query on uptick doesn't work yet - https://github.com/game-of-nfts/gon-evidence/issues/368
        printf -v QUERY_TARGET_TOKEN_CMD "ark query collection tokens --chain $TARGET_CHAIN --collection $TARGET_COLLECTION"
    fi
    TARGET_OWNER=
    CALL_COUNT="$MAX_CALL_LIMIT"
    printf "$QUERY_TARGET_TOKEN_CMD " >&2
    while [[ ! "$RECIPIENT" = "$TARGET_OWNER" ]];do
        QUERY_TARGET_TOKEN_OUTPUT=$(call_until_success \
--cmd "$QUERY_TARGET_TOKEN_CMD" \
--max-call-limit $MAX_CALL_LIMIT \
--sleep 1 2>/dev/null)
        # return in case of error
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]; then
            # switch back
            ark select chain $SOURCE_CHAIN
            printf "\n" >&2
            echo "$QUERY_TARGET_TOKEN_OUTPUT" >&2
            # echo "ERROR, NFT $TOKEN on target chain owned by: $TARGET_OWNER" >&2
            return $EXIT_CODE
        fi
        if [[ "$ICS721_MODULE" == wasm ]]
        then
            # ======== wasm module
            TARGET_OWNER=`echo $QUERY_TARGET_TOKEN_OUTPUT | jq -r '.data.access.owner'`
        else
            # ======== nft-transfer module
            TARGET_OWNER=`echo $QUERY_TARGET_TOKEN_OUTPUT | jq -r ".data[] | select( .id | contains(\"$TOKEN\")) | .owner"`
        fi
        if [[ "$RECIPIENT" = "$TARGET_OWNER" ]];then
            break
        fi
        CALL_COUNT=$(($CALL_COUNT - 1))
        if [ $CALL_COUNT -lt 1 ]
        then
            printf "\n" >&2
            echo "$QUERY_TARGET_TOKEN_OUTPUT" >&2
            echo "Max call limit reached" >&2
            return 1
        fi
        printf "." >&2 # progress bar
    done
    printf "\n" >&2
    # switch back
    ark select chain $SOURCE_CHAIN

    echo "====> successful transfer of $TOKEN from $CHAIN to $TARGET_CHAIN <====" >&2
    ESCAPED_CMD=`echo $CMD | sed 's/"/\\\\"/g'` # escape double quotes
    echo "{}" | jq "{\
        cmd: \"$ESCAPED_CMD\",\
        source: {\
            chain: \"$CHAIN\",\
            chain_id: \"$CHAIN_ID\",\
            port: \"$SOURCE_PORT\",\
            channel: \"$SOURCE_CHANNEL\",\
            collection: \"$COLLECTION\",\
            class_id: \"$SOURCE_CLASS_ID\",\
            from: \"$FROM\",\
        },\
        target: {\
            chain: \"$TARGET_CHAIN\",\
            chain_id: \"$TARGET_CHAIN_ID\",\
            port: \"$TARGET_PORT\",\
            channel: \"$TARGET_CHANNEL\",\
            collection: \"$TARGET_COLLECTION\",\
            class_id: \"$TARGET_CLASS_ID\",\
            recipient: \"$TARGET_OWNER\",\
        },\
        tx: \"$TXHASH\",\
        id: \"$TOKEN\"\
    }"
}
