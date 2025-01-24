#!/bin/bash

# Determines the chain id from a given address.
#
# Parameters:
# $1 = address, e.g. terra1234567890
# Returns chain from given address, e.g. phoenix-1
function fn_get_chain_id_from_address() {
  local chain
  chain=$(get_chain_from_address "$1")
  # shellcheck source=/dev/null
  echo "$(
    source "$ARK_ENV_DIR/$chain.env"
    echo "$CHAIN_ID"
  )"
}

# Check if a string starts with the given prefix
#
# Parameters:
# $1 = prefix
# $2 = the string to check against
# Returns 0 - true or 1- false
function fn_starts_with_prefix() {
  local prefix="$1"
  local string="$2"

  if [[ "$string" =~ ^$prefix ]]; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Determines the chain from a given address.
#
# Parameters:
# $1 = address, e.g. terra1234567890
# Returns chain from given address, e.g. terra2
function fn_get_chain_from_address() {
  if fn_starts_with_prefix "aura" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/aura.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "cosmos" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/cosmoshub.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "inj" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/injective.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "juno" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/juno.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "migaloo" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/migaloo.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "neutron" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/neutron.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "osmo" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/osmosis.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "stars" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/stargaze.env"
      echo "$CHAIN"
    )"
  elif fn_starts_with_prefix "terra" "$1"; then
    echo "$(
      # shellcheck source=/dev/null
      source "$ARK_ENV_DIR/terra2.env"
      echo "$CHAIN"
    )"
  else
    echo "'$1' does not start with any of the specified prefixes please enhance this function '${FUNCNAME[0]}'"
    exit 1
  fi
}

export -f fn_get_chain_from_address
export -f fn_get_chain_id_from_address
export -f fn_starts_with_prefix