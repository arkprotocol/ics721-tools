#!/bin/bash
function query_collections() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --owner) OWNER="${2,,}"; shift ;; # lowercase
            --limit) LIMIT="${2}"; shift ;;
            --offset) OFFSET="${2}"; shift ;;
            --code-id) CODE_ID="${2}"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$LIMIT" ]
    then
        LIMIT=100
        echo "--limit not set, default: $LIMIT" >&2
    fi

    ark select chain "$CHAIN"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 0 ]; then
        return $EXIT_CODE;
    fi

    if [ "$ICS721_MODULE" == wasm ]
    then
        if [ -z "$CODE_ID" ]
        then
            echo "--code-id is required" >&2
            return 1
        fi
        ALL_COLLECTIONS="[]"
        PAGE=1
        if [[ ${OFFSET+x} ]];then
            PAGE="$OFFSET"
        fi
        QUERY_OUTPUT=
        while [[ $PAGE -gt 0 ]]; do
            # echo "query page $PAGE" >&2
            printf -v QUERY_CMD "$CLI query wasm list-contract-by-code %s --page %s --chain-id $CHAIN_ID --node $CHAIN_NODE" "$CODE_ID" "$PAGE"
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
            EXECUTE_CLI_EXIT_CODE=$?
            if [[ "$EXECUTE_CLI_EXIT_CODE" -ne 0 ]]; then
                return $EXECUTE_CLI_EXIT_CODE;
            fi
            COLLECTIONS=`echo $QUERY_OUTPUT | jq -c '.data.contracts'`
            # check result is not empty
            LENGTH=`echo $COLLECTIONS | jq length`
            echo "length $LENGTH" >&2
            if [[ "$LENGTH" == 0 ]];then
                break
            fi
            # add to list
            ALL_COLLECTIONS=`echo "$ALL_COLLECTIONS" | jq ". + $COLLECTIONS"`
            PAGE=`expr $PAGE + 1`
        done
        # map only collection and creator
        readarray -t CONTRACTS < <(echo $ALL_COLLECTIONS | jq -c '.[]')
        echo "Processing ${#CONTRACTS[@]} contracts" >&2
        OWNED_COLLECTIONS="[]"
        for CONTRACT in "${CONTRACTS[@]}"; do
            CONTRACT=`echo $CONTRACT|xargs` # remove double quotes
            QUERY_CMD="$CLI query wasm contract $CONTRACT --chain-id $CHAIN_ID --node $CHAIN_NODE"
            CREATOR=`execute_cli "$QUERY_CMD"| jq '.data.contract_info.creator'`
            EXECUTE_CLI_EXIT_CODE=$?
            if [ "$EXECUTE_CLI_EXIT_CODE" -ne 0 ]; then
                return $EXECUTE_CLI_EXIT_CODE;
            fi
            CREATOR=${CREATOR,,} # lowercase
            CREATOR=`echo $CREATOR|xargs` # remove double quotes
            echo "collection: $CONTRACT, creator: $CREATOR" >&2
            if [ -z "$OWNER" ] || [ "$CREATOR" = "$OWNER" ]
            then
                printf -v NEW_ARRAY "jq '. + [ {
                    \"id\": \"%s\",
                    \"creator\": \"%s\"
                }]'" $CONTRACT "${CREATOR,,}" # lower case
                OWNED_COLLECTIONS=`echo "$OWNED_COLLECTIONS" | eval "$NEW_ARRAY"`
                # check limit
                LENGTH=`echo "$OWNED_COLLECTIONS" | jq length`
                echo "length $LENGTH" >&2
                if [[ "$LENGTH" -eq "$LIMIT" ]];then
                    break
                fi
            fi
        done
        ALL_COLLECTIONS="$OWNED_COLLECTIONS"
    else
        ALL_COLLECTIONS="[]"
        PAGE=1
        if [[ ${OFFSET+x} ]];then
            PAGE="$OFFSET"
        fi
        QUERY_OUTPUT=
        while [[ $PAGE -gt 0 ]]; do
            # echo "query page $PAGE" >&2
            printf -v QUERY_CMD "$CLI query $ICS721_MODULE denoms"
            if [[ ! -z "$DECODED_NEXT_KEY" ]]; then
                QUERY_CMD="$QUERY_CMD --page-key $DECODED_NEXT_KEY"
            fi
            QUERY_OUTPUT=`execute_cli "$QUERY_CMD"`
            EXECUTE_CLI_EXIT_CODE=$?
            if [[ "$EXECUTE_CLI_EXIT_CODE" -ne 0 ]]; then
                return $EXECUTE_CLI_EXIT_CODE;
            fi
            # map only collection and creator
            if [ "$ICS721_MODULE" = collection ]; then
                COLLECTIONS=`echo $QUERY_OUTPUT | jq -c '.data.denoms' | jq -c 'map({"id": .id, "creator": .creator, "name": .name, "symbol": .symbol })'`
            else
                COLLECTIONS=`echo $QUERY_OUTPUT | jq -c '.data.denoms' | jq -c 'map({"id": .id, "creator": .creator, "name": .name, "symbol": .symbol, "description": .description, "uri": .uri, "uri_hash": .uri_hash, "data": .data })'`
            fi
            # check result is not empty
            LENGTH=`echo $COLLECTIONS | jq length`
            if [[ "$LENGTH" == 0 ]];then
                break
            fi
            # filter by owner
            if [ ! -z $OWNER ]
            then
                printf -v FILTER_CMD "jq -c '[ .[] | select( .creator | ascii_downcase | contains(\"%s\")) ]'" $OWNER
                COLLECTIONS=`echo $COLLECTIONS | eval "$FILTER_CMD"`
            fi
            # add to list
            ALL_COLLECTIONS=`echo "$ALL_COLLECTIONS" | jq ". + $COLLECTIONS"`
            PAGE=`expr $PAGE + 1`
            NEXT_KEY=`echo $QUERY_OUTPUT | jq -r '.data.pagination.next_key'`
            if [[ -z "$NEXT_KEY" ]] || [[ "$NEXT_KEY" = null ]];then
                break
            fi
            DECODED_NEXT_KEY=
            [[ ! -z "$NEXT_KEY" ]] && [[ ! "$NEXT_KEY" = null ]] && DECODED_NEXT_KEY=`echo $NEXT_KEY | base64 -d` # decode next key
        done
    fi

    if [ ! -z "$ALL_COLLECTIONS" ] && [ ! -z "$QUERY_OUTPUT" ]
    then
        echo "{ \"cmd\": \"$QUERY_CMD\", \"data\": $ALL_COLLECTIONS}"
        COUNT=`echo $ALL_COLLECTIONS | jq length`
        echo "$COUNT collections found" >&2
        echo "{ \"cmd\": \"$QUERY_CMD\", \"data\": $ALL_COLLECTIONS }"
        return 0
    else
        echo "no collections found: $QUERY_OUTPUT" >&2
        return 1
    fi
}

export -f query_collections