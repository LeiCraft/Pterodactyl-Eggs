#!/bin/bash

CYAN="\033[38;2;0;255;255m"
RED="\033[38;2;255;0;0m"
BOLD="\033[1m"
NC='\033[0m'

#############################
# Linux Installation #
#############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR=/home/container

export PATH=$PATH:~/.local/usr/bin

PROOT_VERSION="5.3.0" # Some releases do not have static builds attached.

# Detect the machine architecture.
ARCH=$(uname -m)

function installOS() {

    # Download & decompress the Linux root file system

    printf "\033c"
    printf "${CYAN}╭───────────────────────────────────────────────────────────────────────────╮${NC}\n"
    printf "${CYAN}│                                                                           │${NC}\n"
    printf "${CYAN}│                            LeiCraft_MC Hosting                            │${NC}\n"
    printf "${CYAN}│                                                                           │${NC}\n"
    printf "${CYAN}│                                 ${RED}Debain 11${CYAN}                                 │${NC}\n"
    printf "${CYAN}│                                                                           │${NC}\n"
    printf "${CYAN}╰───────────────────────────────────────────────────────────────────────────╯${NC}\n"
    printf ""
  
    printf "${GREEN}Installing Debian 11...${NC}"
    url="https://fra1lxdmirror01.do.letsbuildthe.cloud/images/debian/bullseye/amd64/default/"

    LATEST_VERSION=$(curl -s $url | grep -oP 'href="\K[^"]+/' | sort -r | head -n 1)

    curl -Ls "${url}${LATEST_VERSION}/rootfs.tar.xz" -o $ROOTFS_DIR/rootfs.tar.xz
    tar -xf $ROOTFS_DIR/rootfs.tar.xz -C "$ROOTFS_DIR"
    mkdir $ROOTFS_DIR/home/container/ -p

}

################################
# Package Installation & Setup #
#################################

function installProot() {
    # Download static proot.
    # Download the packages from their sources
    mkdir -p "$ROOTFS_DIR/usr/local/bin"
    curl -Ls "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static" -o "$ROOTFS_DIR/usr/local/bin/proot"
    # Make PRoot executable.
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
}


function addDNSResolver() {
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
}

function afterInstallationCleanup() {
    # Clean-up after installation complete & finish up.
    # Wipe the files we downloaded into /tmp previously.
    rm -rf $ROOTFS_DIR/rootfs.tar.xz /tmp/sbin
    # Create .installed to later check whether OS is installed.
    touch "$ROOTFS_DIR/.installed"
}

function install() {
    if [ ! -e "$ROOTFS_DIR/.installed" ]; then
        installOS
        installProot
        addDNSResolver
        afterInstallationCleanup
    fi
}

function preStartup() {

    # Download run.sh
    curl -Ls "https://raw.githubusercontent.com/LeiCraft/Pterodactyl-Eggs/main/Debain11/run.sh" -o "$ROOTFS_DIR/home/container/run.sh"
    # Make run.sh executable.
    chmod +x "$ROOTFS_DIR/home/container/run.sh"

    # Download packageSetup.sh
    curl -Ls "https://raw.githubusercontent.com/LeiCraft/Pterodactyl-Eggs/main/Debain11/packageSetup.sh" -o "$ROOTFS_DIR/home/container/packageSetup.sh"
    # Make packageSetup.sh executable.
    chmod +x "$ROOTFS_DIR/home/container/packageSetup.sh"

}

function start() {

    preStartup

    ###########################
    # Start PRoot environment #
    ###########################

    # Get all ports from vps.config
    port_args=""
    while read line; do
        case "$line" in
            internalip=*) ;;
            port[0-9]*=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;
            port=*) port=${line#*=}; if [ -n "$port" ]; then port_args=" -p $port:$port$port_args"; fi;;   
        esac
    done < "$ROOTFS_DIR/vps.config"

    # This command starts PRoot and binds several important directories
    # from the host file system to our special root file system.
    "$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf $port_args --kill-on-exit \
    /bin/bash "$ROOTFS_DIR/run.sh"

}

install
preStartup
start
