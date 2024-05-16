#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

printf "\033c"
printf "${GREEN}╭────────────────────────────────────────────────────────────────────────────────╮${NC}\n"
printf "${GREEN}│                                                                                │${NC}\n"
printf "${GREEN}│                             Pterodactyl VPS EGG                                │${NC}\n"
printf "${GREEN}│                                                                                │${NC}\n"
printf "${GREEN}│                           ${RED}© 2021 - 2024 ysdragon${GREEN}                               │${NC}\n"
printf "${GREEN}│                                                                                │${NC}\n"
printf "${GREEN}╰────────────────────────────────────────────────────────────────────────────────╯${NC}\n"
printf "                                                                                               \n"
printf "root@MyVPS:${DIR}#                                                                             \n"

service dropbear restart

# Define functions for each command
function shutdown() {
    exit
}


# Associative array to map commands to functions
declare -A command_functions=(
    ["stop"]=shutdown
    ["shutdown"]=shutdown
)

# Function to execute the command
function execute_command() {
    local command="$1"
    # Check if the command exists in the array
    if [[ -n "${command_functions[$command]}" ]]; then
        # Execute the function associated with the command
        ${command_functions[$command]}
    else
        echo "Command not found: $command"
    fi
}

# Main loop to continuously ask for commands
while true; do
    read -p "> " input
    # Trim leading and trailing whitespace
    input=$(echo "$input" | xargs)
    # Execute the command
    execute_command "$input"
done
