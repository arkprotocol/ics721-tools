#!/bin/bash
set -o pipefail

function get_contract_addr_by_tx() {

    if ! type ark &>/dev/null; then
        echo "ark CLI not available. Please start \`source ./scripts/ark-cli-start.sh\` first" >&2
    fi

    ADDR=$(ark query chain tx --max-call-limit 200 --tx $TXHASH | jq '.data.logs[0].events[] | select(.type == "wasm") | .attributes[] | select(.key =="_contract_address")' | jq -r '.value')
    OUTPUT=$(ark query chain tx --max-call-limit 400 --tx $TXHASH)
    ERROR_CODE=${PIPESTATUS[0]}
    if [ $ERROR_CODE -ne 0 ]; then
        echo "ERROR $ERROR_CODE: cannot find $CHAIN_NET contract address" >&2
        return $ERROR_CODE
    fi
    ADDR=$(echo $OUTPUT | jq '.data.logs[0].events[] | select(.type == "wasm") | .attributes[] | select(.key =="_contract_address")' | jq -r '.value')
    ERROR_CODE=${PIPESTATUS[0]}
    # if ADDR is empty, try to get it from .data.event
    if [ -z "$ADDR" ]; then
        ADDR=$(echo $OUTPUT | jq '.data.events[] | select(.type == "wasm") | .attributes[] | select(.key == "_contract_address")' | jq -r '.value')
        ERROR_CODE=${PIPESTATUS[0]}
    fi
    if [ $ERROR_CODE -ne 0 ]; then
        echo "ERROR $ERROR_CODE: jq error. Output:" >&2
        echo "$OUTPUT" >&2
        return $ERROR_CODE
    fi
    if [ -z "$ADDR" ]; then
        echo "ERROR cannot find $CHAIN_NET contract address" >&2
        echo $OUTPUT | jq >&2
        return 1
    fi
    echo $ADDR
}

export -f get_contract_addr_by_tx
