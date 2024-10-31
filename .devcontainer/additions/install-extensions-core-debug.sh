#!/bin/bash
# file: .devcontainer/additions/install-extensions-core-debug.sh

set -e

# Debug function
debug() {
    echo "DEBUG: $*" >&2
}

# Simple logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Process extensions
process_extensions() {
    debug "=== Starting process_extensions ==="
    
    # Get array reference
    declare -n arr=$1
    
    debug "Array contents:"
    debug "Array size: ${#arr[@]}"
    debug "Array keys: '${!arr[@]}'"
    
    # Print each key-value pair
    debug "Detailed array contents:"
    for key in "${!arr[@]}"; do
        debug "  Key: '$key'"
        debug "  Value: '${arr[$key]}'"
    done
    
    # Print header
    log "Processing ${#arr[@]} extensions..."
    echo
    printf "%-25s %-35s %-30s %s\n" "Extension" "Description" "ID" "Status"
    printf "%s\n" "----------------------------------------------------------------------------------------------------"
    
    # Save original IFS
    local SAVE_IFS=$IFS
    debug "Original IFS: '$SAVE_IFS'"
    
    # Process each extension
    for ext_id in ${!arr[@]}; do
        debug "=== Processing extension ==="
        debug "ext_id: '$ext_id'"
        debug "Raw value: '${arr[$ext_id]}'"
        
        # Set IFS to | for splitting
        IFS='|'
        read -r name description _ <<< "${arr[$ext_id]}"
        IFS=$SAVE_IFS
        
        debug "After splitting:"
        debug "  name: '$name'"
        debug "  description: '$description'"
        debug "  ext_id: '$ext_id'"
        
        printf "%-25s %-35s %-30s " "$name" "$description" "$ext_id"
        debug "Checking if extension is installed..."
        
        if code --list-extensions | grep -q "^$ext_id$"; then
            debug "Extension is installed, getting version..."
            version=$(code --list-extensions --show-versions | grep "^${ext_id}@" | cut -d'@' -f2)
            debug "Version: $version"
            printf "v%s\n" "$version"
        else
            debug "Extension is not installed"
            printf "Not installed\n"
        fi
        
        debug "=== Finished processing this extension ==="
    done
    
    debug "=== All extensions processed ==="
    
    echo
    echo "----------------------------------------"
    log "Extension Status Summary"
    echo "Total extensions: ${#arr[@]}"
}