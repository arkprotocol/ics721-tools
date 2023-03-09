#!/bin/bash

function execute_cli() {
    if [[ "$1" = ark* ]]; then
        # ark calls outputs json already!
        CMD="$1"
    else
        CMD="$1 --output json"
    fi
    echo "$CMD" >&2

    DATA=`eval "$CMD"`
    EXIT_CODE=$?

    if [ $EXIT_CODE != 0 ]
    then
        echo "exit code: $EXIT_CODE, error executing command:" >&2
        echo "$CMD" >&2
        return $EXIT_CODE
    fi

    # evaluate code for success or fail
    CODE=`echo $DATA | jq '.code'`
    if [ -n $CODE ] && [ $CODE != null ] && [ $CODE != 0 ]
    then
        RAW_LOG=`echo $DATA | jq -r '.raw_log'`
        CODE_SPACE=`echo $DATA | jq '.codespace'`
        echo SDK code: $CODE, code space: $CODE_SPACE >&2
        echo "$DATA" | jq >&2
        echo $RAW_LOG >&2
        return 1
    fi

    if [[ "$1" = ark* ]]; then
        # ark call already has propertiers cmd and data in DATA
        echo $DATA
    else
        echo no ark call >&2
        ESCAPED_CMD=`echo $CMD | sed 's/"/\\\\"/g'` # escape double quotes
        echo $DATA | jq "{ cmd: \"$ESCAPED_CMD\", data: .}"
    fi
}