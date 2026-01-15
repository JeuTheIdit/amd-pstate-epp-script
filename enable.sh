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
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

# Check for root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# DEFAULTS
GOVERNOR="performance"
EPP="performance"
SCALING_DRIVER_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_driver"
KERNEL_PARAM="amd_pstate=active"

# Ask the user for scaling governor setting
echo -e "Select scaling governor:"
echo -e "  1) performance"
echo -e "  2) powersave"
read -p "Enter choice [1-2] (default 1): " -r GOV_CHOICE
GOV_CHOICE=${GOV_CHOICE:-1} # default to 1 if empty

case "$GOV_CHOICE" in
    1) GOVERNOR="performance" ;;
    2) GOVERNOR="powersave" ;;
    *) print_warn "Unrecognised choice – Defaulting to '$GOVERNOR'" ;;
esac

# Ask the user for EPP setting
echo
echo -e "Select energy performance preference (EPP) hint:"
echo -e "  1) performance"
echo -e "  2) balance_performance"
echo -e "  3) balance_power"
echo -e "  4) power"
read -p "Enter choice [1-4] (default 1): " -r EPP_CHOICE
EPP_CHOICE=${EPP_CHOICE:-1} # default to 1 if empty

case "$EPP_CHOICE" in
    1) EPP="performance" ;;
    2) EPP="balance_performance" ;;
    3) EPP="balance_power" ;;
    4) EPP="power" ;;
    *) print_warn "Unrecognised choice – Defaulting to '$EPP'" ;;
esac

# Show seleted settings
echo
echo -e "Chosen settings:"
echo -e "  Scaling governor: $GOVERNOR"
echo -e "  EPP hint        : $EPP"

# Confirm before continuing
read -p "Continue with these settings? (y/N): " -r CONFIRM
CONFIRM=${CONFIRM:-N}
if [[ ${CONFIRM,,} =~ ^y ]]; then
    print_info "Proceeding..."
else
    print_error "Exiting"
    exit 1
fi

# Check bootloader
if bootctl is-installed >/dev/null 2>&1; then
    BOOTLOADER="systemd-boot"
    print_info "Detected bootloader: $BOOTLOADER"
elif [[ -d /boot/grub || -d /boot/grub2 ]]; then
    BOOTLOADER="GRUB"
    print_info "Detected bootloader: $BOOTLOADER"
else
    print_error "No supported bootloader detected - Exiting"
    exit 1
fi

# Check if amd-pstate-epp is already enabled and enable if not
if [[ -f "$SCALING_DRIVER_FILE" ]]; then
    SCALING_DRIVER=$(<"$SCALING_DRIVER_FILE")
    if [[ "$SCALING_DRIVER" == "amd-pstate-epp" ]]; then
        print_warn "Current scaling driver is already $SCALING_DRIVER - Skipping adding kernel parameter $KERNEL_PARAM"
    else
        print_info "Current scaling driver is '$SCALING_DRIVER' - Adding kernel parameter $KERNEL_PARAM"
        if [[ "$BOOTLOADER" == "systemd-boot" ]]; then
            if grep -R "$KERNEL_PARAM" /boot/loader/entries/*.conf >/dev/null 2>&1; then
                print_error "$KERNEL_PARAM already set but current driver is $SCALING_DRIVER - Check that CPPC is enabled in BIOS"
                exit 1
            else
                for entry in /boot/loader/entries/*.conf; do
                    sed -i "/^options / s/$/ $KERNEL_PARAM/" "$entry"
                done
                print_info "$KERNEL_PARAM added to $BOOTLOADER entries"
            fi
        else
            if grep -q "$KERNEL_PARAM" /etc/default/grub; then
                print_error "$KERNEL_PARAM already set but current driver is $SCALING_DRIVER - Check that CPPC is enabled in BIOS"
                exit 1
            else
                sed -i \
                    "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 $KERNEL_PARAM\"/" \
                    /etc/default/grub
                update-grub
                print_info "$KERNEL_PARAM added and $BOOTLOADER updated"
            fi
        fi
    fi
else
    print_error "Scaling driver file not found — CPU frequency scaling may not be enabled"
    exit 1
fi

