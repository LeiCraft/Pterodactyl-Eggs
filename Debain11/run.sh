#!/bin/bash

CYAN="\033[38;2;0;255;255m"
RED="\033[38;2;255;0;0m"
NC='\033[0m'

printf "\033c"
printf "${CYAN}╭───────────────────────────────────────────────────────────────────────────────╮${NC}\n"
printf "${CYAN}│                                                                               │${NC}\n"
printf "${CYAN}│                              LeiCraft_MC Hosting                              │${NC}\n"
printf "${CYAN}│                                                                               │${NC}\n"
printf "${CYAN}│                                   ${RED}Debain 11${CYAN}                                   │${NC}\n"
printf "${CYAN}│                                                                               │${NC}\n"
printf "${CYAN}╰───────────────────────────────────────────────────────────────────────────────╯${NC}\n"
printf "\n"

function setupHostname() {

    # Loop through each user's home directory
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            bashrc_file="$user_home/.bashrc"
            
            # Check if .bashrc exists for the user
            if [ -f "$bashrc_file" ]; then
                # Replace \h with new_hostname in the .bashrc file
                sed -i 's/\\h/${LHOSTNAME}/g' "$bashrc_file"
            fi
        fi
    done

    # Also update .bashrc for the root user if exists
    root_bashrc="/root/.bashrc"
    if [ -f "$root_bashrc" ]; then
        sed -i 's/\\h/${LHOSTNAME}/g' "$root_bashrc"
    fi

}

function startup() {

    sleep 2

    setupHostname

    if [ ! -e "/.postInstallationMade" ]; then
        bash /home/container/postInstallation.sh
    fi
    
    service dropbear restart
    echo "Started SSH Server under Port ${SERVER_PORT}"

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
