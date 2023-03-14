#!/bin/bash
function query_channel() {
    ARGS=$@
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2^^}"; shift ;; # uppercase
            --channel) CHANNEL="$2"; shift ;;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required"
        return 1
    fi

    if [ -z "$CHANNEL" ]
    then
        echo "--channel is required"
        return 1
    fi

    printf -v CHANNELS "%s" `query_channels --chain "$CHAIN"`
    printf -v FILTER_CHANNEL_CMD "jq -c '[ .data[] | select( .channel_id | contains(\"%s\")) ] | .[0]'" "$CHANNEL"
    echo $CHANNELS | eval $FILTER_CHANNEL_CMD

}
