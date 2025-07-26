#!/bin/bash

# Quick Fix for Hive Metastore Schema Issue
# Simple wrapper around the comprehensive fix script
# Optimized for Windows/WSL users

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/fix_hive_metastore.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 UNSW-NB15 Hive Metastore Quick Fix${NC}"
echo -e "${BLUE}====================================${NC}"
echo

# Check if main script exists
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo -e "${RED}Error: Main fix script not found at $MAIN_SCRIPT${NC}"
    exit 1
fi

# Make sure it's executable
chmod +x "$MAIN_SCRIPT"

# Detect Windows/WSL environment
if [[ $(uname -r) == *microsoft* ]] || [[ $(uname -r) == *WSL* ]]; then
    echo -e "${YELLOW}Windows/WSL environment detected${NC}"
    export DOCKER_BUILDKIT=0
    export COMPOSE_DOCKER_CLI_BUILD=0
fi

# Run the main fix
echo -e "${GREEN}Running comprehensive Hive metastore fix...${NC}"
echo

"$MAIN_SCRIPT" "$@"

# Additional Windows-specific instructions
if [[ $(uname -r) == *microsoft* ]] || [[ $(uname -r) == *WSL* ]]; then
    echo
    echo -e "${YELLOW}Windows/WSL Specific Notes:${NC}"
    echo -e "• If ports are blocked, check Windows Firewall settings"
    echo -e "• Access web interfaces from Windows browser at localhost"
    echo -e "• Use WSL terminal for best command-line experience"
    echo -e "• File paths should use forward slashes in WSL"
    echo
fi

echo -e "${GREEN}Quick fix completed! 🎉${NC}"