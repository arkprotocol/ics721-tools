#!/bin/bash
# This function lets the user choose the chain net (mainnet/testnet) and export the value CHAIN_NET.
#
# Parameters:
# -
function fn_select_chain_net() {
  echo -e "1) mainnet (default)\n2) testnet"
  while true; do
    read -p "Select 1 (default) or 2: " choice
    if [[ $choice == "1" || $choice == "" ]]; then
      # Continue with your program
      export CHAIN_NET="mainnet"
      break
    elif [[ $choice == "2" ]]; then
      export CHAIN_NET="testnet"
      break
    else
      echo -e "Invalid input. Please enter 1 or 2."
    fi
  done
  echo $CHAIN_NET
}

export -f fn_select_chain_net