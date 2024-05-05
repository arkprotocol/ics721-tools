#!/bin/bash
# ----------------------------------------------------
# - exports CHAIN_NET and CHAIN based on user input  -
# ----------------------------------------------------

function fn_get_all_chains() {
    # Read chains from the file into an array
    local ALL_CHAINS=()
    while IFS= read -r line; do
        ALL_CHAINS+=("$line")
    done < "$ARK_CLI_DIR/chains.txt"
    
    echo "${ALL_CHAINS[@]}"
}

export -f fn_get_all_chains