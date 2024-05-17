#!/bin/bash

function setupRootPW() {
    while true; do
        echo "Enter the new root password (at least 8 characters):"
        read -s new_password  # Read input silently (without displaying characters)

        if [ ${#new_password} -lt 8 ]; then
            echo "Password must be at least 8 characters long. Please try again."
            continue
        fi

        echo "Confirm the new root password:"
        read -s confirm_password

        if [ -z "$new_password" ] || [ "$new_password" != "$confirm_password" ]; then
            echo "Passwords do not match or are empty. Please try again."
            continue
        fi

        # Use `sudo` to change the root password
        echo -e "$new_password\n$new_password" | sudo passwd root

        if [ $? -eq 0 ]; then
            echo "Root password successfully changed."
            break
        else
            echo "Failed to change root password."
            return 1  # Return an error status
        fi
    done
}


function setupHostname() {
    uuid_prefix=$(echo "$P_SERVER_UUID" | cut -c 1-8)

    # Set the hostname using hostnamectl
    new_hostname="leicraftmc-${uuid_prefix}"
    hostnamectl set-hostname "$new_hostname"

    sed -i '$a127.0.0.1 '"$new_hostname"'' /etc/hosts
    echo -e "LHOSTNAME=$new_hostname\nHOSTNAME=$new_hostname" > /etc/environment
    echo "
#!/bin/bash

export LHOSTNAME=$new_hostname
export HOSTNAME=$new_hostname

function setupUserHostname() {

    # Loop through each user's home directory
    for user_home in /home/*; do
        if [ -d \"\$user_home\" ]; then
            bashrc_file=\"\$user_home/.bashrc\"
            
            # Check if .bashrc exists for the user
            if [ -f "$bashrc_file" ]; then
                # Replace \h with new_hostname in the .bashrc file
                sed -i 's/\\\\h/\${LHOSTNAME}/g' \"\$bashrc_file\"
            fi
        fi
    done

    # Also update .bashrc for the root user if exists
    root_bashrc=\"/root/.bashrc\"
    if [ -f \"\$root_bashrc\" ]; then
        sed -i 's/\\\\h/\${LHOSTNAME}/g' \"\$root_bashrc\"
    fi

}

setupUserHostname


" > /etc/profile.d/hostname.sh
    sed -i 's/\\h/${LHOSTNAME}/g' /etc/bash.bashrc
}

function setupBasicPackages() {

    apt install nano -y
    apt install curl -y

}


function setupSSH() {

    apt install dropbear -y

    local dropbear_file="/etc/default/dropbear"

    # Check if the file exists
    if [ ! -f "$dropbear_file" ]; then
        echo "Error: $dropbear_file not found."
        return 1
    fi

    # Check if the line exists in the file
    if grep -q '^DROPBEAR_PORT=' "$dropbear_file"; then
        # Replace the line in the file
        sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=${SERVER_PORT}/" "$dropbear_file"
        echo "DROPBEAR_PORT in $dropbear_file replaced with $SERVER_PORT."
    else
        echo "Error: DROPBEAR_PORT not found in $dropbear_file."
        return 1
    fi

}


setupRootPW
setupHostname
setupBasicPackages
setupSSH

touch "/.postInstallationMade"

