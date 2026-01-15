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
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Parse flags
while getopts ":g:e:" opt; do
  case "$opt" in
    g)  flag_g=$OPTARG   ;;
    e)  flag_e=$OPTARG   ;;
    \?) echo "❌ Unknown option: -$OPTARG" >&2; exit 1 ;;
    :)  echo "❌ Option -$OPTARG requires an argument" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))  # Drop the options from $@

# Configuration
GOVERNOR="${flag_a:-<none>}"
EPP="${flag_b:-<none>}"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}
