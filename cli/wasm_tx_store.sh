#!/bin/bash
ARGS=$@

source "$ARK_CLI_DIR"/execute-cli.sh
source "$ARK_CLI_DIR"/query-tx.sh

function wasm_tx_store() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --chain) CHAIN=""${2,,}""; shift ;; # lowercase
            --file) FILE="$2"; shift ;;
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

    if [ -z $FROM ]
    then
        echo "--from is required" >&2
        return 1
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        # upload
        echo "====> $CHAIN: uploading $FILE)  <====" >&2
        printf -v CMD "$CLI tx wasm store $FILE --fees $FEES --gas $GAS --gas-adjustment $GAS_ADJUSTMENT -b $BROADCAST_MODE --from $WALLET_DEV --yes"
        CMD_OUTPUT=`execute_cli "$CMD"`
        EXIT_CODE=$?
        if [ $EXIT_CODE != 0 ]
        then
            echo "$CMD_OUTPUT" >&2
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
        # retrieve code id
        CODE_ID=`echo $QUERY_OUTPUT|jq '.data.logs[0].events[] | select(.type == "store_code") | .attributes[] | select(.key =="code_id")' | jq -r '.value'`
        INITIAL_CMD=`echo $CMD_OUTPUT | jq -r '.cmd' | sed 's/"/\\\\"/g'` # escape double quotes
        RESULT=`echo $QUERY_OUTPUT | jq "{ cmd: \"$INITIAL_CMD\", data: .data, code_id: \"$CODE_ID\"}"`
        echo $RESULT | jq
    else
        echo "$ICS721_MODULE is not a WASM module" >&2
        return 1
    fi
    return 0
}

export -f wasm_tx_store