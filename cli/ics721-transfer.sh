#!/bin/bash

# get function in case not yet initialised
source "$ARK_CLI_DIR"/call-until-success.sh
function ics721_transfer() {
    ARGS=$@ # backup args
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;;
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --recipient) RECIPIENT="$2"; shift ;;
            --port) PORT="${2}"; shift ;;
            --target-chain) TARGET_CHAIN="${2,,}"; shift ;; # lowercase
            --source-channel) SOURCE_CHANNEL="${2}"; shift ;;
            --relay) RELAY="true";;
            --fee) FEE="true";;
            --duration) DURATION="$2"; shift ;;
            --amount) AMOUNT="$2"; shift ;;
            --proxy) PROXY="$2"; shift ;;
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

    if [ -z "$PORT" ]
    then
        echo "--port is required" >&2
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

    if [ -z "$DURATION" ]
    then
        echo "NOTE: approval duration will be set for next 5 minutes. Or pass --duration [\"+5 minutes\"|\"+2 days\"]." >&2
        DURATION="+5 minutes"
    fi

    ark select chain "$CHAIN"
    SELECT_CHAIN_EXIT_CODE=$?
    if [ "$SELECT_CHAIN_EXIT_CODE" -ne 0 ]; then
        return $SELECT_CHAIN_EXIT_CODE;
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
    echo "$SOURCE_CHANNEL_CMD" >&2
    SOURCE_CHANNEL_OUTPUT=$($SOURCE_CHANNEL_CMD 2>/dev/null)
    # - return in case of error
    ARK_QUERY_CHANNL_EXIT_CODE=$?
    if [ $ARK_QUERY_CHANNL_EXIT_CODE != 0 ]; then
        return $ARK_QUERY_CHANNL_EXIT_CODE
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
    ASSERT_TOKEN_QUERY_CMD=("ark" "assert" "nft" "token-owner" "--chain" "$CHAIN" "--collection" "$COLLECTION" "--token" "$TOKEN" "--owner" "$FROM" "--max-call-limit" "$MAX_CALL_LIMIT")
    echo "${ASSERT_TOKEN_QUERY_CMD[@]}" >&2
    ASSERT_TOKEN_QUERY_OUTPUT=$("${ASSERT_TOKEN_QUERY_CMD[@]}")

    # return in case of error
    ASSERT_TOKEN_QUERY_EXIT_CODE=$?
    if [ $ASSERT_TOKEN_QUERY_EXIT_CODE != 0 ]; then
        echo "$ASSERT_TOKEN_QUERY_OUTPUT" >&2
        return $ASSERT_TOKEN_QUERY_EXIT_CODE
    fi

    echo "====> transferring $TOKEN from $CHAIN to $TARGET_CHAIN, collection: $COLLECTION <====" >&2
    if [[ "$ICS721_MODULE" == wasm ]]
    then
        # ======== wasm module
        if [[ ! "$PORT" == wasm.* ]]
        then
            echo "Port does not start with 'wasm.': $PORT" >&2
            return 1
        fi
        # ====== send token to ICS721 contract
        TIMESTAMP=`date -d "$DURATION" +%s%N` # time in nano seconds, other options: "+1 day"
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
        # send nft either to (1) ICS721 or (2) via proxy, in case of proxy it may also have (3) transfer fee
        # (1) send_nft: call from collection to ics721
        # (2) send_nft: call from collection to proxy
        # (3) bridge_nft: call from proxy (which then sub calls transfer_nft from collection to proxy, and forwards cw721_receive_msg to ics721)
        ICS721_CONTRACT=${PORT#"wasm."} # remove 'wasm.' prefix
        # in case fee is provided, we need to call proxy, otherwise we call collection
        PROXY_OR_COLLECTION_CALL=$( [ ! -z "$FEE" ] && echo "invoke_send_nft" || echo "send_nft")
        # in case fee is provided, we need to provide collection, so outgoing proxy knows where NFT comes from,
        # otherwise for `send_nft` we need to provide contract where NFT is send to
        COLLECTION_OR_CONTRACT=$( [ ! -z "$FEE" ] && echo "collection" || echo "contract")
        if [ ! -z "$FEE" ]; then
            COLLECTION_OR_CONTRACT_VALUE="$COLLECTION"
        elif [ ! -z "$PROXY" ]; then
            COLLECTION_OR_CONTRACT_VALUE="$PROXY"
        else
            COLLECTION_OR_CONTRACT_VALUE="$ICS721_CONTRACT"
        fi
        printf -v EXECUTE_MSG '{"%s": {
"%s": "%s",
"token_id": "%s",
"msg": "%s"}}'\
        "$PROXY_OR_COLLECTION_CALL"\
        "$COLLECTION_OR_CONTRACT"\
        "$COLLECTION_OR_CONTRACT_VALUE"\
        "$TOKEN"\
        "$MSG"


        PROXY_OR_COLLECTION=$( [ ! -z "$FEE" ] && echo "$PROXY" || echo "$COLLECTION")
        CMD="$CLI tx wasm execute '$PROXY_OR_COLLECTION' '$EXECUTE_MSG' \
--from "$FROM" \
--gas-prices "$CLI_GAS_PRICES" \
--gas "$CLI_GAS" \
--gas-adjustment "$CLI_GAS_ADJUSTMENT" \
-b "$CLI_BROADCAST_MODE" \
--chain-id $CHAIN_ID --node $CHAIN_NODE \
--yes"
    else
        # ======== nft-transfer module
        TIMEOUT=`expr $(date -d "2000-01-01 $DURATION" +%s%N) - $(date -d "2000-01-01" +%s%N)` # --packet-timeout-timestamp: packet timeout timestamp in nanoseconds from now
        CMD="$CLI tx nft-transfer transfer '$PORT' '$SOURCE_CHANNEL' '$RECIPIENT' '$COLLECTION' '$TOKEN' \
--from "$FROM" \
--fees "$CLI_FEES" \
--packet-timeout-timestamp $TIMEOUT \
-b "$CLI_BROADCAST_MODE" \
--chain-id $CHAIN_ID --node $CHAIN_NODE \
--yes"
    fi

    BACKTRACK=false
    BACK_TO_HOME=false
    # add optional amount
    printf -v CMD "$CMD %s" "$( [ ! -z "$AMOUNT" ] && echo "--amount $AMOUNT" || echo "")"
    CMD_OUTPUT=`execute_cli "$CMD"`
    # return in case of error
    CMD_EXIT_CODE=$?
    if [ $CMD_EXIT_CODE != 0 ]; then
        return $CMD_EXIT_CODE
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
    TX_QUERY_EXIT_CODE=$?
    if [ $TX_QUERY_EXIT_CODE != 0 ]; then
        echo "$TX_QUERY_OUTPUT" >&2
        return $TX_QUERY_EXIT_CODE
    fi
    TX_HEIGHT=`echo "$TX_QUERY_OUTPUT" | jq -r '.data.height'`

    HERMES_CMD="hermes --config $HERMES_DIR/config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $PORT >&2"
    echo "====> manually relaying $SOURCE_CHANNEL on $CHAIN <====" >&2
    if [ "$RELAY" = "true" ]; then
        echo "hermes --config $HERMES_DIR/config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $PORT" >&2
        hermes --config $HERMES_DIR/config.toml clear packets --chain "$CHAIN_ID" --channel "$SOURCE_CHANNEL" --port "$PORT" >&2
    else
        echo "skip: hermes --config $HERMES_DIR/config.toml clear packets --chain $CHAIN_ID --channel $SOURCE_CHANNEL --port $PORT" >&2
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
            CLASS_TRACE_EXIT_CODE=$?
            if [ $CLASS_TRACE_EXIT_CODE != 0 ]; then
                return $CLASS_TRACE_EXIT_CODE
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
        QUERY_TARGET_COLLECTION_EXIT_CODE=$?
        if [ $QUERY_TARGET_COLLECTION_EXIT_CODE != 0 ]; then
            echo "error query target collection $QUERY_TARGET_COLLECTION_OUTPUT " >&2
            return $QUERY_TARGET_COLLECTION_EXIT_CODE
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
    ASSERT_TOKEN_QUERY_CMD=("ark" "assert" "nft" "token-owner" "--chain" "$CHAIN" "--collection" "$TARGET_COLLECTION" "--token" "$TOKEN" "--owner" "$RECIPIENT" "--max-call-limit" "$MAX_CALL_LIMIT")
    echo "${ASSERT_TOKEN_QUERY_CMD[@]}" >&2
    ASSERT_TOKEN_QUERY_OUTPUT=$(${ASSERT_TOKEN_QUERY_CMD[@]})

    # return in case of error
    ASSERT_TOKEN_QUERY_EXIT_CODE=$?
    if [ $ASSERT_TOKEN_QUERY_EXIT_CODE != 0 ]; then
        # switch back
        ark select chain $SOURCE_CHAIN
        echo "$ASSERT_TOKEN_QUERY_OUTPUT" >&2
        return $ASSERT_TOKEN_QUERY_EXIT_CODE
    fi

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
            owner: \"$FROM\",\
        },\
        target: {\
            chain: \"$TARGET_CHAIN\",\
            chain_id: \"$TARGET_CHAIN_ID\",\
            port: \"$TARGET_PORT\",\
            channel: \"$TARGET_CHANNEL\",\
            collection: \"$TARGET_COLLECTION\",\
            class_id: \"$TARGET_CLASS_ID\",\
            owner: \"$RECIPIENT\",\
        },\
        tx: \"$TXHASH\",\
        height: \"$TX_HEIGHT\",\
        id: \"$TOKEN\",\
        amount: \"$AMOUNT\",\
        duration: \"$DURATION\"\
    }"
}

export -f ics721_transfer