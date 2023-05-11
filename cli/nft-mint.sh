#!/bin/bash
function nft_mint() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --chain) CHAIN=""${2,,}""; shift ;; # lowercase
            --collection) COLLECTION_ID="$2"; shift ;;
            --token) TOKEN="$2"; shift ;;
            --data) DATA="$2"; shift ;;
            --uri) URI="$2"; shift ;;
            --name) NAME="$2"; shift ;;
            --recipient) RECIPIENT="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z $CHAIN ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ -z $RECIPIENT ]
    then
        echo "--recipient is required" >&2
        return 1
    fi

    if [ -z $FROM ]
    then
        echo "--from is required" >&2
        return 1
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        if [ -z "$TOKEN" ]
        then
            echo "--token is required" >&2
            return 1
        fi

        if [ -z "$COLLECTION_ID" ]
        then
            echo "--collection not defined, using $CONTRACT_CW721" >&2
            COLLECTION_ID="$CONTRACT_CW721"
        fi

        echo "====> minting $TOKEN on chain $CHAIN <====" >&2
        printf -v MINT_MSG '{"mint": {"token_id":"%s", "owner":"%s" %s}}'\
            "$TOKEN" "$RECIPIENT"\
            "$( [ ! -z $URI ] && echo ", \"token_uri\": \"$URI\"" || echo "")"
        printf -v CMD "$CLI tx wasm execute %s '$MINT_MSG'\
            --from $FROM\
            --gas-prices $GAS_PRICES --gas $GAS --gas-adjustment $GAS_ADJUSTMENT\
            -b $BROADCAST_MODE --yes"\
            "$COLLECTION_ID"
        CMD_OUTPUT=`execute_cli "$CMD"`
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]
        then
            echo "$CMD_OUTPUT" >&2
            return "$EXIT_CODE"
        fi
        TXHASH=`echo $CMD_OUTPUT | jq -r '.data.txhash'`
        if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
        then
            echo "ERROR no tx found!" >&2
            echo $CMD_OUTPUT >&2
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

        INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
        RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$TOKEN\"}"`
        echo $RESULT | jq
        return 0
    else
        if [ -z "$COLLECTION_ID" ]
        then
            echo "--collection not defined, using $DENOM_ID" >&2
            COLLECTION_ID="$DENOM_ID"
        fi

        if [ "$ICS721_MODULE" = nft ] || [ "$ICS721_MODULE" = collection ]
        then
            if [ -z $TOKEN ]
            then
                echo "--token is required" >&2
                return 1
            fi

            echo "====> minting $TOKEN on chain $CHAIN <====" >&2
            printf -v CMD "$CLI tx $ICS721_MODULE mint '$COLLECTION_ID' '$TOKEN' \
--from $FROM \
--recipient $RECIPIENT \
%s \
%s \
%s \
--fees $FEES \
-b $BROADCAST_MODE --yes" \
"$( [ ! -z "$URI" ] && echo "--uri '$URI'" || echo "")" \
"$( [ ! -z "$DATA" ] && echo "--data '$DATA'" || echo "")" \
"$( [ ! -z "$NAME" ] && echo "--name '$NAME'")"
            CMD_OUTPUT=`execute_cli "$CMD"`
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]
            then
                echo "$CMD_OUTPUT" >&2
                return "$EXIT_CODE"
            fi
            TXHASH=`echo $CMD_OUTPUT | jq -r '.data.txhash'`
            if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
            then
                echo "ERROR no tx found!" >&2
                echo $CMD_OUTPUT >&2
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

            INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
            RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$TOKEN\"}"`
            echo $RESULT | jq
            return 0
        else
            if [ ! -z "$TOKEN" ]
            then
                echo "ERROR: unknown flag --token" >&2
                return 1
            fi
            if [ -z "$URI" ]
            then
                echo "ERROR: --uri is required" >&2
                return 1
            fi
            echo "====> minting on collection $COLLECTION_ID and chain $CHAIN <====" >&2
            printf -v CMD "$CLI tx $ICS721_MODULE mint '$COLLECTION_ID' \
--from $FROM \
--recipient $RECIPIENT \
--media-uri '$URI' \
%s \
%s \
--fees $FEES \
-b $BROADCAST_MODE --yes" \
"$( [ ! -z "$DATA" ] && echo "--data '$DATA'" || echo "")" \
"$( [ ! -z "$NAME" ] && echo "--name '$NAME'")"
            CMD_OUTPUT=`execute_cli "$CMD"`
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]
            then
                echo "$CMD_OUTPUT" >&2
                return "$EXIT_CODE"
            fi
            TXHASH=`echo $CMD_OUTPUT | jq -r '.data.txhash'`
            if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
            then
                echo "ERROR no tx found!" >&2
                echo $CMD_OUTPUT >&2
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

            # query nft
            TOKEN=`echo $QUERY_OUTPUT|jq -r '.data.tx.body.messages[0].id'`
            INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
            RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$TOKEN\"}"`
            echo $RESULT | jq
            return 0
        fi
        return 1
    fi

}