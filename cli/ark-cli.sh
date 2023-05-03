#!/bin/bash

# init history if not set yet
[[ -z ${ARK_HISTORY+x} ]] && export ARK_HISTORY=() && echo init ARK_HISTORY

if [[ -z "$ARK_HOME_DIR" ]] ; then
    ARK_HOME_DIR="$(dirname -- "${BASH_SOURCE[0]}")"            # relative
    ARK_HOME_DIR="$(cd -- "$MY_PATH" && pwd)"    # absolutized and normalized
fi
echo "ARK_HOME_DIR: $ARK_HOME_DIR"

if [[ -z "$ARK_ENV_DIR" ]] ; then
    ARK_ENV_DIR="$ARK_HOME_DIR"
fi
echo "ARK_ENV_DIR: $ARK_ENV_DIR"


if [[ -z "$ARK_HERMES_DIR" ]] ; then
    ARK_HERMES_DIR="$(cd $ARK_HOME_DIR/.. && pwd)"
fi
echo "ARK_HERMES_DIR: $ARK_HERMES_DIR"

source "$ARK_HOME_DIR"/cli.env

source "$ARK_HOME_DIR"/execute-cli.sh
source "$ARK_HOME_DIR"/query-tx.sh
source "$ARK_HOME_DIR"/create-collection.sh
source "$ARK_HOME_DIR"/query-channels.sh
source "$ARK_HOME_DIR"/query-channel.sh
source "$ARK_HOME_DIR"/query-collections.sh
source "$ARK_HOME_DIR"/query-tokens.sh
source "$ARK_HOME_DIR"/query-token.sh
source "$ARK_HOME_DIR"/collection-by-class-id.sh
source "$ARK_HOME_DIR"/ics721-transfer.sh
source "$ARK_HOME_DIR"/ics721-transfer-chains.sh
source "$ARK_HOME_DIR"/nft-approve.sh
source "$ARK_HOME_DIR"/nft-assert-token-owner.sh
source "$ARK_HOME_DIR"/nft-mint.sh
source "$ARK_HOME_DIR"/nft-query-approvals.sh
source "$ARK_HOME_DIR"/nft-transfer.sh
source "$ARK_HOME_DIR"/chain-query-height.sh
source "$ARK_HOME_DIR"/nft-query-snapshot.sh

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
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        token)
                            ARK_FUN="ics721_transfer"
                            ;;
                        chains)
                            ARK_FUN="ics721_transfer_chains"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        class-id)
                            ARK_FUN="collection_by_class_id"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
                    return 1
                    ;;
            esac
            ;;
        nft)
            case $COMMAND in
                approve)
                    ARK_FUN="nft_approve"
                    ;;
                assert)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        token-owner)
                            ARK_FUN="nft_assert_token_owner"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                mint)
                    ARK_FUN="nft_mint"
                    ;;
                transfer)
                    ARK_FUN="nft_transfer"
                    ;;
                query)
                    SUB_COMMAND="$1"
                    shift
                    case $SUB_COMMAND in
                        snapshot)
                            ARK_FUN="nft_query_snapshot"
                            ;;
                        approvals)
                            ARK_FUN="nft_query_approvals"
                            ;;
                        *)
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
                    return 1
                    ;;
            esac
            ;;
        chain)
            case $COMMAND in
                query)
                    if [[ ${1+x} ]]; then
                        SUB_COMMAND="$1"
                        shift
                        case $SUB_COMMAND in
                            tx)
                                ARK_FUN="query_tx"
                                ;;
                            height)
                                ARK_FUN="chain_query_height"
                                ;;
                            *)
                                echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                                return 1
                                ;;
                        esac
                    else
                        echo "selected chain: $CHAIN" >&2
                    fi
                    ;;
                select)
                    CHAIN=${1,,} # lowercase
                    ARK_ENV_FILE="$ARK_ENV_DIR/"${CHAIN}.env
                    echo "reading $ARK_ENV_FILE" >&2
                    source "$ARK_ENV_FILE"
                    ARK_INTERNAL_SELECT_CHAIN_EXIT_CODE=$?
                    if [ "$ARK_INTERNAL_SELECT_CHAIN_EXIT_CODE" -ne 0 ]; then
                        return $ARK_INTERNAL_SELECT_CHAIN_EXIT_CODE;
                    fi
                    ;;
                reload)
                    echo reloading ark cli and chain config
                    ARK_CLI_FILE="$ARK_HOME_DIR/ark-cli.sh"
                    source "$ARK_CLI_FILE"
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
                    return 1
                    ;;
            esac
            ;;
        config)
            case $COMMAND in
                set)
                    if [[ ${1+x} ]]; then
                        SUB_COMMAND="$1"
                        shift
                        case $SUB_COMMAND in
                            home)
                                ARK_HOME_DIR="$1"
                                ;;
                            env)
                                ARK_ENV_DIR="$1"
                                ;;
                            *)
                                echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                                return 1
                                ;;
                        esac
                    else
                        echo "selected chain: $CHAIN" >&2
                    fi
                    ;;
                show)
                    echo "ARK_HOME_DIR: $ARK_HOME_DIR"
                    echo "ARK_ENV_DIR: $ARK_ENV_DIR"
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
                    return 1
                    ;;
            esac
            ;;
        collection)
            case $COMMAND in
                create)
                    ARK_FUN="create_collection"
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
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
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
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
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
                            echo "Unknown sub command: $SUB_COMMAND, args passed: '$ARGS'" >&2
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    echo "Unknown command: $COMMAND, args passed: '$ARGS'" >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown module: $MODULE, args passed: '$ARGS'" >&2
            return 1
            ;;
    esac

    if [ ! -z "$ARK_FUN" ];then
        RESULT=`"$ARK_FUN" "$@"`
        ARK_INTERNAL_ARK_CLI_EXIT_CODE=$?
        if [ ! $ARK_INTERNAL_ARK_CLI_EXIT_CODE != 0 ]; then
            ARK_HISTORY+=("$RESULT")
            echo "$RESULT"
            # echo "command and output added to history (${#ARK_HISTORY[@]} entries)" >&2
        fi
        return $ARK_INTERNAL_ARK_CLI_EXIT_CODE
    fi
}

echo "ark 0.1.1"
if [[ ${1+x} ]]; then
    ark select chain $1
elif [[ -n "$CHAIN" ]]; then
    echo "reloading $CHAIN"
    ark select chain $CHAIN
else
    echo "- please select operating chain: ark select chain [chain: stargaze|irisnet|juno|uptick|omniflix|osmosis]"
fi

echo "- max calls (like tx queries) until succcesful response set to: MAX_CALL_LIMIT=$MAX_CALL_LIMIT"
