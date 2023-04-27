#!/bin/bash
ARGS=$@

source ./execute-cli.sh
source ./query-tx.sh

function create_collection() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --chain) CHAIN=""${2,,}""; shift ;; # uppercase
            --name) NAME="$2"; shift ;;
            --data) DATA="$2"; shift ;;
            --symbol) SYMBOL="$2"; shift ;;
            --uri) URI="$2"; shift ;;
            --label) LABEL="$2"; shift ;; # WASM
            --code-id) CODE_ID="${2}"; shift ;;
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --description) DESCRIPTION="$2"; shift ;; # NFT module
            --description=*) DESCRIPTION="${1:14}" ;; # NFT module
            --from) FROM="$2"; shift ;;
            --admin) ADMIN="$2"; shift ;;
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

    if [ -z $FROM ]
    then
        echo "--from is required" >&2
        return 1
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        if [ -z "$CODE_ID" ]
        then
            echo "--code-id is required" >&2
            return 1
        fi
        if [ -z $LABEL ]
        then
            echo "--label is required on all contracts!" >&2
            return 1
        fi
        if [ -z $SYMBOL ]
        then
            echo "--symbol is required!" >&2
            return 1
        fi
        # instantiate
        echo "====> $CHAIN: creating collection (symbol: $SYMBOL, label: "$LABEL", minter: $FROM)  <====" >&2
        printf -v INSTANTIATE_MSG '{"name":"%s", "symbol":"%s", "minter":"%s"}' "$NAME" "$SYMBOL" $FROM
        printf -v CMD "$CLI tx wasm instantiate $CODE_ID \'$INSTANTIATE_MSG\'\
            --from $FROM --label '$LABEL'\
            %s\
            --gas-prices $GAS_PRICES --gas $GAS --gas-adjustment $GAS_ADJUSTMENT\
            -b $BROADCAST_MODE --yes"\
            "$( [ ! -z $ADMIN ] && echo "--admin $ADMIN" || echo "--no-admin")"

        CMD_OUTPUT=`execute_cli "$CMD"`
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]
        then
            echo "$QUERY_OUTPUT" >&2
            return "$EXIT_CODE" >&2
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
        COLLECTION=`echo $QUERY_OUTPUT|jq -r '.data.logs[0].events[0].attributes[0].value'`
        # $CLI query wasm contract-state smart $COLLECTION '{"contract_info": {}}' --output json | jq
        # return contract
        INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
        RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$COLLECTION\"}"`
        echo $RESULT | jq
        return 0
    else
        if [ "$ICS721_MODULE" = nft ]
        then
            if [ -z "$COLLECTION" ]
            then
                echo "--collection is required" >&2
                return 1
            fi

            echo "====> $CHAIN: creating collection $COLLECTION, from: $FROM  <====" >&2
            printf -v CMD "$CLI tx $ICS721_MODULE issue $COLLECTION\
                %s\
                %s\
                %s\
                %s\
                %s\
                --mint-restricted=true --update-restricted=true\
                --from "$FROM"\
                --fees "$FEES"\
                -b "$BROADCAST_MODE" --yes"\
                "$( [ ! -z "$SYMBOL" ] && echo "--symbol \"$SYMBOL\"" || echo "")"\
                "$( [ ! -z "$DATA" ] && echo "--data '$DATA'" || echo "")"\
                "$( [ ! -z "$NAME" ] && echo "--name \"$NAME\"" || echo "")"\
                "$( [ ! -z "$URI" ] && echo "--uri \"$URI\"" || echo "")"\
                "$( [ ! -z "$DESCRIPTION" ] && echo "--description=\"$DESCRIPTION\"" || echo "")"
            CMD_OUTPUT=`execute_cli "$CMD"`
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]
            then
                echo "$QUERY_OUTPUT" >&2
                return "$EXIT_CODE" >&2
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
                return "$EXIT_CODE" >&2
            fi
            INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
            RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$COLLECTION\"}"`
            echo $RESULT | jq
            return 0
        elif [ "$ICS721_MODULE" = collection ]
        then
            if [ -z "$COLLECTION" ]
            then
                echo "--collection is required" >&2
                return 1
            fi

            echo "====> $CHAIN: creating collection $COLLECTION, from: $FROM  <====" >&2
            printf -v CMD "$CLI tx $ICS721_MODULE issue $COLLECTION\
                %s\
                %s\
                --mint-restricted=true --update-restricted=true\
                --from $FROM\
                --fees $FEES\
                -b $BROADCAST_MODE --yes"\
                "$( [ ! -z $SYMBOL ] && echo "--symbol $SYMBOL" || echo "")"\
                "$( [ ! -z "$NAME" ] && echo "--name \"$NAME\"" || echo "")"

            CMD_OUTPUT=`execute_cli "$CMD"`
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]
            then
                echo "$QUERY_OUTPUT" >&2
                return "$EXIT_CODE" >&2
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
                return $EXIT_CODE >&2
            fi
            INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
            RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$COLLECTION\"}"`
            echo $RESULT | jq
            return 0
        else
            if [ -z "$SYMBOL" ]
            then
                echo "--symbol is required" >&2
                return 1
            fi
            if [ -z "$NAME" ]
            then
                echo "--name is required" >&2
                return 1
            fi
            echo "====> $CHAIN: creating collection (symbol: $SYMBOL, name: $NAME, from: $FROM)  <====" >&2
            printf -v CMD "$CLI tx $ICS721_MODULE create \"$SYMBOL\" --name \"$NAME\"\
                %s\
                %s\
                %s\
                --from "$FROM"\
                --fees "$FEES"\
                -b "$BROADCAST_MODE" --yes"\
                "$( [ ! -z $URI ] && echo "--uri $URI" || echo "")"\
                "$( [ ! -z "$DATA" ] && echo "--data '$DATA'" || echo "")"\
                "$( [ ! -z "$DESCRIPTION" ] && echo "--description=\"$DESCRIPTION\"" || echo "")" # --description not documented in CLI...

            CMD_OUTPUT=`execute_cli "$CMD"`
            EXIT_CODE=$?
            if [ $EXIT_CODE != 0 ]
            then
                echo "$QUERY_OUTPUT" >&2
                return "$EXIT_CODE" >&2
            fi
            TXHASH=`echo $CMD_OUTPUT | jq -r '.data.txhash'`
            if [ -z "$TXHASH" ] && [ "$TXHASH" = null ]
            then
                echo "ERROR no tx found!" >&2
                echo "$CMD_OUTPUT" >&2
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
            COLLECTION=`jq --argjson j "$QUERY_OUTPUT" -r -n '$j.data.tx.body.messages[0].id'`
            INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
            RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, id: \"$COLLECTION\"}"`
            echo $RESULT | jq
            return 0
        fi
    fi
    return 1
}