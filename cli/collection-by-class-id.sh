#!/bin/bash
function collection_by_class_id() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN=""${2,,}""; shift ;; # lowercase
            --class-id) CLASS_ID="$2"; shift ;;
            --dest-port) DEST_PORT="$2"; shift ;;
            --max-call-limit) MAX_CALL_LIMIT="$2"; shift ;;
            --sleep) SLEEP="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$CLASS_ID" ]
    then
        echo "--class-id is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ -z "$MAX_CALL_LIMIT" ]
    then
        MAX_CALL_LIMIT=30
        echo "--max-call-limit not defined, set max call to $MAX_CALL_LIMIT" >&2
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        if [ -z "$DEST_PORT" ]
        then
            echo "--dest-port is required" >&2
            return 1
        fi
        if [[ ! "$DEST_PORT" == wasm.* ]]
        then
            echo "Port does not start with 'wasm.': $DEST_PORT" >&2
            return 1
        fi

        DEST_CONTRACT_ICS721=${DEST_PORT#"wasm."}

        COLLECTION=
        printf -v QUERY_MSG '{"nft_contract":{"class_id":"%s"}}' "$CLASS_ID"
        printf -v QUERY_CMD "$CLI query wasm contract-state smart\
            %s\
            '%s'"\
            "$DEST_CONTRACT_ICS721"\
            "$QUERY_MSG"
        CALL_COUNT="$MAX_CALL_LIMIT"
        printf "retrieving class-id: $QUERY_CMD" >&2
        while [[ -z "$COLLECTION" ]] || [[ "$COLLECTION" = null ]]; do
            CALL_COUNT=$(($CALL_COUNT - 1))
            if [[ ${SLEEP+x} ]];then
                sleep "$SLEEP"
            fi
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD" 2>/dev/null`
            EXIT_CODE=$?
            if [ "$EXIT_CODE" -ne 0 ]; then
                printf "\n" >&2
                echo "ERROR!" >&2
                return $EXIT_CODE;
            fi
            COLLECTION=`echo $QUERY_OUTPUT | jq -r '.data.data'`
            printf "." >&2 # progress bar
            if [ $CALL_COUNT -lt 1 ]
            then
                printf "<====\n" >&2
                echo "Max call limit reached!" >&2
                QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
                return 1
            fi
        done
        printf "\n" >&2
    else
        COLLECTION=
        printf -v QUERY_CMD "$CLI query nft-transfer class-hash '%s'" "$CLASS_ID"
        CALL_COUNT="$MAX_CALL_LIMIT"
        printf "retrieving class-hash" >&2
        while [[ -z "$COLLECTION" ]] || [[ "$COLLECTION" = null ]]; do
            CALL_COUNT=$(($CALL_COUNT - 1))
            if [[ ${SLEEP+x} ]];then
                sleep "$SLEEP"
            fi
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD" 2>/dev/null`
            EXIT_CODE=$?
            if [ "$EXIT_CODE" -eq 0 ]; then
                CLASS_HASH=`echo $QUERY_OUTPUT | jq -r '.data.hash'`
                COLLECTION="ibc/$CLASS_HASH"
            fi
            printf "." >&2 # progress bar
            if [ $CALL_COUNT -lt 1 ]
            then
                printf "\n" >&2
                echo "Max call limit reached!" >&2
                QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
                return 1
            fi
        done
        printf "\n" >&2


    fi

    if [ ! -z "$COLLECTION" ]
    then
        # ESCAPED_CLASS_ID=`echo $CLASS_ID | sed 's/\//\\\\\//g'` # escape slash
        echo $QUERY_OUTPUT | jq "{ cmd: .cmd, data: { class_id: \""$CLASS_ID"\", collection: \""$COLLECTION"\" } }"
        return 0
    else
        echo "no collections found: $QUERY_OUTPUT" >&2
        return 1
    fi
}