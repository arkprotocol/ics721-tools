#!/bin/bash
# calls until no messages in stderr is shown
function call_until_success() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --cmd) CMD="$2"; shift ;;
            --max-call-limit) MAX_CALL_LIMIT="$2"; shift ;;
            --sleep) SLEEP="$2"; shift ;;
            *) echo "Unknown parameter: $1" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CMD" ]
    then
        echo "--cmd is required" >&2
        return 1
    fi

    if [ -z "$MAX_CALL_LIMIT" ]
    then
        MAX_CALL_LIMIT=30
        echo "--max-call-limit not defined, set max call to $MAX_CALL_LIMIT" >&2
    fi

    CALL_COUNT="$MAX_CALL_LIMIT"

    printf "\nWaiting for cmd to finish" >&2
    until ERROR=$($CMD 2>&1 >/dev/null)
    do
        CALL_COUNT=$(($CALL_COUNT - 1))
        if [[ ${SLEEP+x} ]];then
            sleep "$SLEEP"
        fi
        printf "." >&2 # progress bar
        if [ $CALL_COUNT -lt 1 ]
        then
            echo "Max call limit reached" >&2
            echo $ERROR >&2
            return 1
        fi
    done
    printf "\n" >&2

    # add functions if not yet defined
    [[ ! $(type -t execute_cli) == function ]] && source ./cli-cmd.sh

    QUERY_OUTPUT=`execute_cli "$CMD"`
    EXIT_CODE=$?
    if [ $EXIT_CODE != 0 ]
    then
        echo "$QUERY_OUTPUT" >&2
        return $EXIT_CODE
    fi
    echo $QUERY_OUTPUT
}