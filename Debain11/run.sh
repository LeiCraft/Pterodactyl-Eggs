#!/bin/bash

CYAN="\033[38;2;0;255;255m"
RED="\033[38;2;255;0;0m"
NC='\033[0m'

printf "\033c"
printf "${CYAN}╭───────────────────────────────────────────────────────────────────────────╮${NC}\n"
printf "${CYAN}│                                                                           │${NC}\n"
printf "${CYAN}│                            LeiCraft_MC Hosting                            │${NC}\n"
printf "${CYAN}│                                                                           │${NC}\n"
printf "${CYAN}│                                 ${RED}Debain 11${CYAN}                                 │${NC}\n"
printf "${CYAN}│                                                                           │${NC}\n"
printf "${CYAN}╰───────────────────────────────────────────────────────────────────────────╯${NC}\n"
printf ""

function startup() {

    sleep 2

    bash /home/container/postInstallation.sh

    service dropbear restart
    echo "Started SSH Server"

}

# Define functions for each command
function cmd_shutdown() {
    exit
}

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

function main() {

    echo -e "";
    echo -e "\nServer Started. Use shutdown to stop."
    echo -e "Run Commands below:"

    # Associative array to map commands to functions
    declare -A -g command_functions=(
        ["stop"]=cmd_shutdown
        ["shutdown"]=cmd_shutdown
    )


    # Main loop to continuously ask for commands
    while true; do
        read -p "> " input
        # Trim leading and trailing whitespace
        input=$(echo "$input" | xargs)
        # Execute the command
        execute_command "$input"
    done

}

startup
main
