#!/bin/bash
# This function lets let user choose specific chain or all chains.
#
# Parameters:
# -
# let user choose specific chain or all chains
function fn_select_chains() {
  declare -a all_chains=($(fn_get_all_chains))
  all_options=("ALL")
  all_options+=($(fn_get_all_chains))

  # Display the menu
  echo "Please choose a chain by entering its number:" >&2
  for i in "${!all_options[@]}"; do
    echo "$i) ${all_options[$i]}" >&2
  done


  # Validate input
  while true; do
    # Read user input
    read -p "Enter your choice: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -ge ${#all_options[@]} ]; then
      echo "Invalid input. Please enter a number between 0 and $((${#all_options[@]} - 1))." >&2
    else
      break
    fi
  done
  # Process the choice
  if [ "$choice" -eq 0 ]; then
    echo "You selected ALL." >&2
    for ((i = 1; i < ${#all_options[@]}; i++)); do
      echo "${all_options[$i]}" >&2
      selected_chains+=(${all_options[$i]})
    done
  else
    echo "You selected: ${all_options[$choice]}" >&2
    selected_chains=${all_options[$choice]}
  fi

  echo "${selected_chains[@]}"
}

export -f fn_select_chains
