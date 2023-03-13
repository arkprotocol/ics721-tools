#!/bin/bash
source ./cli.env

source ./cli-cmd.sh
source ./query-tx.sh
source ./create-collection.sh
source ./mint.sh
source ./query-channels.sh
source ./query-channel.sh
source ./query-collections.sh
source ./query-tokens.sh
source ./query-token.sh
source ./collection-by-class-id.sh
source ./transfer.sh

# init history if not set yet
[[ -z ${ARK_HISTORY+x} ]] && export ARK_HISTORY=() && echo init ARK_HISTORY

echo "ark 0.1.0"
[[ -z "$CHAIN" ]] && echo "- please select operating chain: ark select chain [chain: stagagaze|irisnet|juno|uptick|omniflix|osmosis]"
echo "- max calls (like tx queries) until succcesful response set to: MAX_CALL_LIMIT=$MAX_CALL_LIMIT"

function ark() {
    ARGS=$@ # backup args

    if [ $# -lt 2 ];then
        echo "ark-cli.sh [command] [module] [flags]" >&2
        return 1
    fi

    COMMAND="$1"
    MODULE="$2"
    shift
    shift

    # reset due to previous call
    ARK_FUN=
    case $MODULE in
        ics721)
            case $COMMAND in
                transfer)
                    ARK_FUN="transfer_ics721"
                    ;;
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        class-id)
                            ARK_FUN="collection_by_class_id"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND" >&2
                    return 1
                    ;;
            esac
            ;;
        chain)
            case $COMMAND in
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        tx)
                            ARK_FUN="query_tx"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND" >&2
                            return 1
                            ;;
                    esac
                    ;;
                select)
                    CHAIN=${1,,}
                    ENV=${CHAIN}.env
                    echo "reading $ENV" >&2
                    source $ENV
                    EXIT_CODE=$?
                    if [ "$EXIT_CODE" -ne 0 ]; then
                        return $EXIT_CODE;
                    fi

                    ;;
                *)
                    echo "Unknown command: $COMMAND" >&2
                    return 1
                    ;;
            esac
            ;;
        collection)
            case $COMMAND in
                create)
                    ARK_FUN="create_collection"
                    ;;
                mint)
                    ARK_FUN="mint"
                    ;;
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        collections)
                            ARK_FUN="query_collections"
                            ;;
                        tokens)
                            ARK_FUN="query_tokens"
                            ;;
                        token)
                            ARK_FUN="query_token"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND" >&2
                    return 1
                    ;;
            esac
            ;;
        channel)
            case $COMMAND in
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        channels)
                            ARK_FUN="query_channels"
                            ;;
                        channel)
                            ARK_FUN="query_channel"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND" >&2
                    return 1
                    ;;
            esac
            ;;
        history)
            case $COMMAND in
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        list)
                            len=`expr ${#ARK_HISTORY[@]} - 1`
                            HISTORY="[]"
                            for (( i=${len}; i>-1; i-- )); do
                                ENTRY=${ARK_HISTORY[$i]}
                                HISTORY=`echo "$HISTORY" | jq ". + [ $ENTRY ]"`
                            done
                            echo "$HISTORY"
                            # return and do not execute or add to history
                            return 0
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND" >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown module: $MODULE" >&2
            return 1
            ;;
    esac

    if [ ! -z "$ARK_FUN" ];then
        RESULT=`"$ARK_FUN" "$@"`
        EXIT_CODE=$?
        if [ ! $EXIT_CODE != 0 ]; then
            ARK_HISTORY+=("$RESULT")
            echo "$RESULT"
            echo "command and output added to history (${#ARK_HISTORY[@]} entries)" >&2
        fi
        return $EXIT_CODE
    fi
}
