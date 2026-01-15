#!/usr/bin/env bash

# AMD P-State EPP Driver Enable Script
# Supports: Ubuntu 20.04+, Debian 11+, Proxmox VE 7+

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Messages
print_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Check for root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# DEFAULTS
governor="performance"
epp="performance"

# Ask the user for scaling governor setting
print_info "Select scaling governor:"
print_info "  1) performance"
print_info "  2) powersave"
printf "Enter choice [1-2] (default 1): "
read -r gov_choice
gov_choice=${gov_choice:-1} # default to 1 if empty

case "$gov_choice" in
    1) governor="performance" ;;
    2) governor="powersave" ;;
    *) print_warn "Unrecognised choice – Defaulting to 'performance'" ;;
esac

# Ask the user for EPP setting
echo
print_info "Select energy performance preference (EPP) hint:"
print_info "  1) performance"
print_info "  2) balance_performance"
print_info "  3) balance_power"
print_info "  4) power"
printf "Enter choice [1-4] (default 1): "
read -r epp_choice
epp_choice=${epp_choice:-1} # default to 1 if empty

case "$epp_choice" in
    1) epp="performance" ;;
    2) epp="balance_performance" ;;
    3) epp="balance_power" ;;
    4) epp="power" ;;
    *) print_warn "Unrecognised choice – Defaulting to 'performance'" ;;
esac

# Show seleted settings
echo
print_info "Chosen settings:"
print_info "  Scaling governor: $governor"
print_info "  EPP hint        : $epp"

# Confirm before continuing
printf "Continue with these settings? (y/N): "
read -r confirm
confirm=${confirm:-N}                    # N if nothing typed
if [[ ${confirm,,} =~ ^y ]]; then        # if starts with y (case‑insensitive)
    print_info "Proceeding..."
else
    print_error "Aborted."
    exit 0
fi
