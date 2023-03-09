#!/bin/bash
function collection_by_class_id() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN=""${2^^}""; shift ;; # uppercase
            --source-class-id) SOURCE_CLASS_ID="$2"; shift ;;
            --dest-channel) DEST_CHANNEL="$2"; shift ;;
            --dest-port) DEST_PORT="$2"; shift ;;
            *) echo "Unknown parameter: $1" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$SOURCE_CLASS_ID" ]
    then
        echo "--source-class-id is required" >&2
        return 1
    fi

    if [ -z "$DEST_CHANNEL" ]
    then
        echo "--dest-channel is required" >&2
        return 1
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    CLASS_ID=
    if [ "$ICS721_MODULE" == wasm ]
    then
        if [ -z "$DEST_PORT" ]
        then
            echo "'--dest-port' not defined, using $ICS721_PORT" >&2
            DEST_PORT="$ICS721_PORT"
        fi

        if [[ ! "$DEST_PORT" == wasm.* ]]
        then
            echo "Port does not start with 'wasm.': $DEST_PORT" >&2
            return 1
        fi

        DEST_CONTRACT_ICS721=${ICS721_PORT#"wasm."}

        CLASS_ID="$DEST_PORT/$DEST_CHANNEL/$SOURCE_CLASS_ID"
        printf -v QUERY_MSG '{"nft_contract":{"class_id":"%s"}}' "$CLASS_ID"
        printf -v QUERY_CMD "$CLI query wasm contract-state smart\
            %s\
            '%s'"\
            "$DEST_CONTRACT_ICS721"\
            "$QUERY_MSG"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
        EXIT_CODE=$?
        if [ "$EXIT_CODE" -ne 0 ]; then
            return $EXIT_CODE;
        fi
        COLLECTION=`echo $QUERY_OUTPUT | jq -r '.data.data'`
    else
        if [ -z "$DEST_PORT" ]
        then
            echo "'--dest-port' not defined, using 'nft-transfer'" >&2
            DEST_PORT="nft-transfer"
        fi

        CLASS_ID="$DEST_PORT/$DEST_CHANNEL/$SOURCE_CLASS_ID"
        printf -v QUERY_CMD "$CLI query nft-transfer class-hash '%s'" "$CLASS_ID"
        QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
        EXIT_CODE=$?
        if [ "$EXIT_CODE" -ne 0 ]; then
            return $EXIT_CODE;
        fi
        CLASS_HASH=`echo $QUERY_OUTPUT | jq -r '.data.hash'`
        COLLECTION="ibc/$CLASS_HASH"
    fi

    if [ ! -z "$COLLECTION" ]
    then
        # ESCAPED_CLASS_ID=`echo $CLASS_ID | sed 's/\//\\\\\//g'` # escape slash
        echo $QUERY_OUTPUT | jq "{ cmd: .cmd, data: { classId: \""$CLASS_ID"\", collection: \""$COLLECTION"\" } }"
        return 0
    else
        echo "no collections found: $QUERY_OUTPUT" >&2
        return 1
    fi
}