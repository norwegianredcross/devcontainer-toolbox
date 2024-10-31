#!/bin/bash
# file: .devcontainer/additions/core-install-extensions.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Simple logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Process extensions
process_extensions() {
    local array_name=$1
    local -n array=$array_name
    local installed=0
    local not_installed=0
    
    log "Processing ${#array[@]} extensions..."
    echo
    printf "%-25s %-35s %-30s %s\n" "Extension" "Description" "ID" "Status"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    
    # Get array keys
    local keys=()
    eval "keys=(\"\${!$array_name[@]}\")"
    
    # Sort keys
    IFS=$'\n' sorted_keys=($(sort <<<"${keys[*]}"))
    unset IFS
    
    # Process each extension
    for key in "${sorted_keys[@]}"; do
        local value="${array[$key]}"
        local name description
        
        IFS='|' read -r name description _ <<< "$value"
        
        printf "%-25s %-35s %-30s " "$name" "$description" "$key"
        
        if code --list-extensions | grep -q "^$key$" 2>/dev/null; then
            local version
            version=$(code --list-extensions --show-versions | grep "^${key}@" | cut -d'@' -f2)
            printf "${YELLOW}v%s${NC}\n" "$version"
            ((installed++))
        else
            printf "${RED}Not installed${NC}\n"
            ((not_installed++))
        fi
    done
    
    echo
    echo "----------------------------------------"
    log "Extension Status Summary"
    echo "Total extensions: ${#array[@]}"
    echo -e "Installed: ${YELLOW}$installed${NC}"
    if [ $not_installed -gt 0 ]; then
        echo -e "Not installed: ${RED}$not_installed${NC}"
    fi
}