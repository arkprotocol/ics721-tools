#!/bin/bash

# get function in case not yet initialised
source "$ARK_CLI_DIR"/call-until-success.sh
function ics721_transfer_chains() {
    ARGS=$@ # backup args
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --chain) CHAIN="${2,,}"; shift ;; # lowercase
            --collection) COLLECTION="$2"; shift ;; # NFT module
            --token) TOKEN="$2"; shift ;;
            --from) FROM="$2"; shift ;;
            --recipients) RECIPIENTS="$2"; shift ;;
            --target-chains) TARGET_CHAINS="${2,,}"; shift ;; # lowercase
            --source-channels) SOURCE_CHANNELS="${2}"; shift ;;
            --max-height) MAX_HEIGHT="${2}"; shift ;;
            --relay) RELAY="true";;
            *) echo "Unknown parameter: $1, args passed: '$ARGS'" >&2; return 1 ;;
        esac
        shift
    done

    if [ -z "$CHAIN" ]
    then
        echo "--chain is required" >&2
        return 1
    fi

    if [ -z "$COLLECTION" ]
    then
        echo "--collection is required" >&2
        return 1
    fi

    if [ -z "$TOKEN" ]
    then
        echo "--token is required" >&2
        return 1
    fi

    if [ -z "$RECIPIENTS" ]
    then
        echo "--recipients is required, args passed: '$ARGS'" >&2
        return 1
    fi

    if [ -z "$TARGET_CHAINS" ]
    then
        echo "--target-chains is required" >&2
        return 1
    fi

    if [ -z "$SOURCE_CHANNELS" ]
    then
        echo "--source-channels is required" >&2
        return 1
    fi

    if [ -z $FROM ]
    then
        echo "--from is required" >&2
        return 1
    fi

    TMP_ONLY_SLASHES="${RECIPIENTS//[^\/]}" # remove all except '/', source: https://stackoverflow.com/a/16679640
    RECIPIENTS_COUNT=`expr "${#TMP_ONLY_SLASHES}" + 1`
    TMP_ONLY_SLASHES="${TARGET_CHAINS//[^\/]}"
    TARGET_CHAINS_COUNT=`expr "${#TMP_ONLY_SLASHES}" + 1`
    TMP_ONLY_SLASHES="${SOURCE_CHANNELS//[^\/]}"
    SOURCE_CHANNELS_COUNT=`expr "${#TMP_ONLY_SLASHES}" + 1`

    if [[ ! "$RECIPIENTS_COUNT" -eq "$TARGET_CHAINS_COUNT" ]]; then
        echo "Recipients: $RECIPIENTS" >&2
        echo "Target chains: $TARGET_CHAINS" >&2
        echo "Amount of recipients and target chains must be the same!" >&2
        return 1
    fi
    if [[ ! "$RECIPIENTS_COUNT" -eq "$SOURCE_CHANNELS_COUNT" ]]; then
        echo "Recipients: $RECIPIENTS" >&2
        echo "Source channels: $SOURCE_CHANNELS" >&2
        echo "Amount of recipients and source channels must be the same!" >&2
        return 1
    fi

    # backup initial chain
    INITIAL_CHAIN="$CHAIN"
    SOURCE_CHAIN="$CHAIN"

    INITIAL_HEIGHT=
    ALL_TRANSFERS="[]"
    while [[ -n "$RECIPIENTS" ]]; do
        ark select chain $SOURCE_CHAIN
        # - return in case of error
        ARK_SELECT_CHAIN_EXIT_CODE=$?
        if [ $ARK_SELECT_CHAIN_EXIT_CODE != 0 ]; then
            return $ARK_SELECT_CHAIN_EXIT_CODE
        fi
        SOURCE_CHANNEL=`echo "$SOURCE_CHANNELS" | cut -d'/' -f 1`
        SOURCE_CHANNELS=`echo ${SOURCE_CHANNELS#"${SOURCE_CHANNEL}"} | cut -d'/' -f'2-'`
        echo "SOURCE_CHANNEL: $SOURCE_CHANNEL, SOURCE_CHANNELS: $SOURCE_CHANNELS" >&2

        TARGET_CHAIN=`echo "$TARGET_CHAINS" | cut -d'/' -f 1`
        TARGET_CHAINS=`echo ${TARGET_CHAINS#"${TARGET_CHAIN}"} | cut -d'/' -f'2-'`
        echo "TARGET_CHAIN: $TARGET_CHAIN, TARGET_CHAINS: $TARGET_CHAINS" >&2

        # switch to next chain and retrieve recipient
        ark select chain $TARGET_CHAIN
        # - return in case of error
        ARK_SELECT_CHAIN_EXIT_CODE=$?
        if [ $ARK_SELECT_CHAIN_EXIT_CODE != 0 ]; then
            # switch back to initial chain
            ark select chain $INITIAL_CHAIN
            return $ARK_SELECT_CHAIN_EXIT_CODE
        fi
        # recipient on target chain!
        RECIPIENT=`echo "$RECIPIENTS" | cut -d'/' -f 1`
        RECIPIENTS=`echo ${RECIPIENTS#"${RECIPIENT}"} | cut -d'/' -f'2-'`
        echo "RECIPIENT: $RECIPIENT, RECIPIENTS: $RECIPIENTS" >&2

        # switch back to source chain for transfer
        ark select chain $SOURCE_CHAIN
        # - return in case of error
        ARK_SELECT_CHAIN_EXIT_CODE=$?
        if [ $ARK_SELECT_CHAIN_EXIT_CODE != 0 ]; then
            # switch back to initial chain
            ark select chain $INITIAL_CHAIN
            return $ARK_SELECT_CHAIN_EXIT_CODE
        fi
        printf "\n\n\n" >&2
        echo "=======================================================" >&2
        echo "= transfer $TOKEN from $SOURCE_CHAIN to $TARGET_CHAIN" >&2
        echo "=======================================================" >&2
        printf -v ICS721_TRANSFER_CMD "ark transfer ics721 token \
--from $FROM \
--collection $COLLECTION \
--token $TOKEN \
--recipient $RECIPIENT \
--target-chain $TARGET_CHAIN \
--source-channel $SOURCE_CHANNEL"
        echo "$ICS721_TRANSFER_CMD" >&2
        ICS721_TRANSFER_CMD_OUTPUT=$($ICS721_TRANSFER_CMD)
        ICS721_TRANSFER_EXIT_CODE=$?
        # - return in case of error
        if [ $ICS721_TRANSFER_EXIT_CODE != 0 ]; then
            # switch back to initial chain
            ark select chain $INITIAL_CHAIN
            echo "$ICS721_TRANSFER_CMD_OUTPUT" >&2
            echo "REVERT_BACK_CMD: $REVERT_BACK_CMD" >&2
            return $ICS721_TRANSFER_EXIT_CODE
        fi
        TX=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.tx'`
        HEIGHT=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.height'`
        SOURCE_CHAIN_ID=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.source.chain_id'`
        SOURCE_PORT=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.source.port'`
        SOURCE_COLLECTION=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.source.collection'`
        SOURCE_CLASS_ID=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.source.class_id'`
        SOURCE_OWNER=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.source.owner'`
        TARGET_CHANNEL=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.channel'`
        ALL_TRANSFERS=`echo "$ALL_TRANSFERS" | jq ". + [{\
cmd: \"$ICS721_TRANSFER_CMD\", \
tx: \"$TX\", \
height: \"$HEIGHT\", \
chain: \"$SOURCE_CHAIN\", \
chain_id: \"$SOURCE_CHAIN_ID\", \
port: \"$SOURCE_PORT\", \
channel: \"$SOURCE_CHANNEL\", \
target_channel: \"$TARGET_CHANNEL\", \
collection: \"$SOURCE_COLLECTION\", \
class_id: \"$SOURCE_CLASS_ID\", \
owner: \"$SOURCE_OWNER\" \
}]"`

        TARGET_COLLECTION=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.collection'`
        TARGET_OWNER=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.owner'`
        # init
        if [[ -z "$INITIAL_HEIGHT" ]]; then
            INITIAL_HEIGHT="$HEIGHT"
            REVERT_SOURCE_CHANNELS="$TARGET_CHANNEL"
            REVERT_RECIPIENTS="$FROM"
            REVERT_CHAINS="$SOURCE_CHAIN"
        fi

        echo "INITIAL_HEIGHT: $INITIAL_HEIGHT, CLI: $CLI" >&2
        if [[ ! "$INITIAL_CHAIN" = "$SOURCE_CHAIN" ]];then
            REVERT_SOURCE_CHANNELS="$TARGET_CHANNEL/${REVERT_SOURCE_CHANNELS}"
            REVERT_RECIPIENTS="$FROM/${REVERT_RECIPIENTS}"
            REVERT_CHAINS="$SOURCE_CHAIN/${REVERT_CHAINS}"
            # calculate total duration in height based on initial chain
            NEXT_HEIGHT=`ark query chain height --chain $INITIAL_CHAIN| jq '.height'`
            echo "NEXT_HEIGHT: $NEXT_HEIGHT" >&2
            DURATION_HEIGHT=`expr $NEXT_HEIGHT - $INITIAL_HEIGHT`
            echo "DURATION_HEIGHT: $DURATION_HEIGHT" >&2

            printf -v REVERT_BACK_CMD "ark transfer ics721 chains \
--chain $TARGET_CHAIN \
--collection $TARGET_COLLECTION \
--token $TOKEN \
--from $TARGET_OWNER \
--recipients $REVERT_RECIPIENTS \
--target-chains $REVERT_CHAINS \
--source-channels $REVERT_SOURCE_CHANNELS"
            if [[ -n "$MAX_HEIGHT" ]] && [[ "$DURATION_HEIGHT" -gt "$MAX_HEIGHT" ]]; then
                echo "$ALL_TRANSFERS" >&2
                echo "$TOKEN is in collection $TARGET_COLLECTION on chain $TARGET_CHAIN" >&2
                echo "ERROR: transfer stopped! Duration $DURATION_HEIGHT is longer than $MAX_HEIGHT" >&2
                printf "\n\n\n" >&2
                echo "=======================================================" >&2
                echo "= reverting $TOKEN back from $TARGET_CHAIN to $INITIAL_CHAIN" >&2
                echo "=======================================================" >&2
                # reset max height for reverting
                MAX_HEIGHT=
                echo "$REVERT_BACK_CMD" >&2
                REVERT_BACK_CMD_OUTPUT=`$REVERT_BACK_CMD`
                # switch back to initial chain
                ark select chain $INITIAL_CHAIN
                echo "$TOKEN reverted back to $TARGET_COLLECTION on chain $INITIAL_CHAIN" >&2
                echo "REVERT_BACK_CMD_OUTPUT: $REVERT_BACK_CMD_OUTPUT" >&2
                return 1
            fi
        fi

        FROM="$RECIPIENT"
        SOURCE_CHAIN="$TARGET_CHAIN"
        echo "$ICS721_TRANSFER_CMD_OUTPUT" >&2
        COLLECTION="$TARGET_COLLECTION"
    done

    # compute result output
    TARGET_CHAIN_ID=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.chain_id'`
    TARGET_PORT=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.port'`
    TARGET_CLASS_ID=`echo "$ICS721_TRANSFER_CMD_OUTPUT" | jq -r '.target.class_id'`
    RESULT=`echo "$ALL_TRANSFERS"| jq "{\
transfers: ., \
chain: \"$TARGET_CHAIN\", \
chain_id: \"$TARGET_CHAIN_ID\", \
port: \"$TARGET_PORT\", \
channel: \"$TARGET_CHANNEL\", \
collection: \"$TARGET_COLLECTION\", \
class_id: \"$TARGET_CLASS_ID\", \
owner: \"$TARGET_OWNER\", \
total_duration_height: \"$DURATION_HEIGHT\", \
}"`

    # switch back to initial chain
    ark select chain $INITIAL_CHAIN
    echo "Successful transfer through all chains!" >&2
    echo "Skip revert: $REVERT_BACK_CMD" >&2
    echo "$RESULT"
}

export -f ics721_transfer_chains