#!/bin/bash
clear
source ./nodes.env
COLLECTION_ID="arkprotocol002"
NAME="Ark Protocol - building multichain utilities"
SYMBOL="arkprotocol_symbol"
URI="https://arkprotocol.io"
LABEL="gon_test_ark"
DESCRIPTION="Ark Protocol's mission: build multi-chain NFT utilities, allowing NFTs to move between chains & enabling utilities across multiple chains."
DATA='{"github_username": "taitruong", "discord_handle": "mr_t|Ark Protocol#2337", "team_name": "Ark Protocol", "community": "All Cosmos chains ;)"}'

# Stargaze
CW721_CONTRACT=`"$ARK_HOME_DIR"/create-collection.sh --chain stars --name "$NAME" --symbol "$SYMBOL" --label "$LABEL" | tail -n 1 2>&1 | tee -a logs/collections.log`
REPLACE_PATTERN="s/GON_STARGAZE_CONTRACT_CW721=\".*\"/GON_STARGAZE_CONTRACT_CW721=\"$CW721_CONTRACT\"/"
sed -i "$REPLACE_PATTERN" ./nodes.env

# Juno
CW721_CONTRACT=`"$ARK_HOME_DIR"/create-collection.sh --chain juno --name "$NAME" --symbol "$SYMBOL" --label "$LABEL" | tail -n 1 2>&1 | tee -a logs/collections.log`
REPLACE_PATTERN="s/GON_JUNO_CONTRACT_CW721=\".*\"/GON_JUNO_CONTRACT_CW721=\"$CW721_CONTRACT\"/"
sed -i "$REPLACE_PATTERN" ./nodes.env

# Osmosis
CW721_CONTRACT=`"$ARK_HOME_DIR"/create-collection.sh --chain osmo --name "$NAME" --symbol "$SYMBOL" --label "$LABEL" | tail -n 1 2>&1 | tee -a logs/collections.log`
REPLACE_PATTERN="s/GON_OSMOSIS_CONTRACT_CW721=\".*\"/GON_OSMOSIS_CONTRACT_CW721=\"$CW721_CONTRACT\"/"
sed -i "$REPLACE_PATTERN" ./nodes.env

# IRISnet
"$ARK_HOME_DIR"/create-collection.sh --chain iris \
    --collection "$COLLECTION_ID" \
    --data "$DATA" \
    --uri "$URI" \
    --name "$NAME" \
    --symbol "$SYMBOL" \
    --description "$DESCRIPTION" | tail -n 10000 2>&1 | tee -a logs/collections.log
printf -v ESCAPED_COLLECTION_ID '%s' $(echo $COLLECTION_ID | sed 's/\//\\\//') # escape '/'
REPLACE_PATTERN="s/GON_IRISNET_DENOM_ID=\".*\"/GON_IRISNET_DENOM_ID=\"$ESCAPED_COLLECTION_ID\"/"
echo pattern: $REPLACE_PATTERN
sed -i "$REPLACE_PATTERN" ./nodes.env

# Uptick
"$ARK_HOME_DIR"/create-collection.sh --chain upt \
    --collection "$COLLECTION_ID" \
    --uri "$URI" \
    --name "$NAME" \
    --symbol "$SYMBOL" \
    --description "$DESCRIPTION" | tail -n 10000 2>&1 | tee -a logs/collections.log
printf -v ESCAPED_COLLECTION_ID '%s' $(echo $COLLECTION_ID | sed 's/\//\\\//') # escape '/'
REPLACE_PATTERN="s/GON_UPTICK_DENOM_ID=\".*\"/GON_UPTICK_DENOM_ID=\"$ESCAPED_COLLECTION_ID\"/"
echo pattern: $REPLACE_PATTERN
sed -i "$REPLACE_PATTERN" ./nodes.env

# OmniFlix
"$ARK_HOME_DIR"/create-collection.sh --chain omni \
    --collection "$COLLECTION_ID" \
    --uri "$URI" \
    --name "$NAME" \
    --symbol "$SYMBOL" \
    --description "$DESCRIPTION" | tail -n 10000 2>&1 | tee -a logs/collections.log
printf -v ESCAPED_COLLECTION_ID '%s' $(echo $COLLECTION_ID | sed 's/\//\\\//') # escape '/'
REPLACE_PATTERN="s/GON_OMNIFLIX_DENOM_ID=\".*\"/GON_OMNIFLIX_DENOM_ID=\"$ESCAPED_COLLECTION_ID\"/"
echo pattern: $REPLACE_PATTERN
sed -i "$REPLACE_PATTERN" ./nodes.env
