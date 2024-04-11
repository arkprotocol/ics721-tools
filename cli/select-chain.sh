#!/bin/bash
# ----------------------------------------------------
# - exports CHAIN_NET and CHAIN based on user input  -
# ----------------------------------------------------

function select_chain() {
    unset SELECTED_CHAIN_NET
    unset SELECTED_CHAIN
    unset SKIP_CHAIN_NET
    unset SKIP_CHAIN
    # Read chains from the file into an array
    CHAIN_CHOICES=()
    while IFS= read -r line; do
        CHAIN_CHOICES+=("$line")
    done < "$ARK_CLI_DIR/chains.txt"
    echo "Available chains: ${CHAIN_CHOICES[*]}" >&2

    for arg in "$@"; do
        if [[ "$arg" == "mainnet" || "$arg" == "testnet" ]]; then
            SELECTED_CHAIN_NET="$arg"
        elif [[ " ${CHAIN_CHOICES[*]} " =~ " ${arg} " ]]; then
            SELECTED_CHAIN="$arg"
        elif [[ "$arg" == "--skip-chain-net" ]]; then
            SELECTED_CHAIN_NET="$CHAIN_NET"
            SKIP_CHAIN_NET=true
        elif [[ "$arg" == "--skip-chain" ]]; then
            SELECTED_CHAIN="$CHAIN"
            SKIP_CHAIN=true
        else
            echo "Unknown parameter: $arg" >&2
            return 1
        fi
    done

    if [[ -z "$SELECTED_CHAIN_NET" && "$SKIP_CHAIN_NET" != "true" ]]; then
        echo "Please select the chain's mainnet|testnet:" >&2
        select SELECTED_CHAIN_NET in "testnet" "mainnet" "Exit"; do
            case $SELECTED_CHAIN_NET in
                testnet|mainnet) echo "Selected chain net: $SELECTED_CHAIN_NET" >&2; break ;;
                Exit) echo "Exiting..." >&2; return 0 ;;
                *) echo "Invalid choice. Please try again." >&2 ;;
            esac
        done
    fi
    export CHAIN_NET="$SELECTED_CHAIN_NET"

    if [[ -z "$SELECTED_CHAIN" && "$SKIP_CHAIN" != "true" ]]; then
        echo "Please select the chain:" >&2
        select SELECTED_CHAIN in "${CHAIN_CHOICES[@]}" "Exit"; do
            case $SELECTED_CHAIN in
                "Exit") echo "Exiting..." >&2; return 0 ;;
                *) if [[ " ${CHAIN_CHOICES[*]} " =~ " ${SELECTED_CHAIN} " ]]; then
                        echo "Selected chain: $SELECTED_CHAIN" >&2
                        export CHAIN="$SELECTED_CHAIN"
                        break
                else
                        echo "Invalid choice. Please try again." >&2
                fi ;;
            esac
        done
    else
        echo "Selected chain: $SELECTED_CHAIN" >&2
    fi
    export CHAIN="$SELECTED_CHAIN"
    echo $CHAIN
    unset SELECTED_CHAIN_NET
    unset SELECTED_CHAIN
    unset SKIP_CHAIN_NET
    unset SKIP_CHAIN
}

export -f select_chain