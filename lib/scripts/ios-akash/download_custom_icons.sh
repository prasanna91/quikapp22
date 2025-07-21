#!/bin/bash

# Download Custom Icons Script for QuikApp
# This script downloads custom SVG icons from BOTTOMMENU_ITEMS and saves them to assets/icons/

set -e

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    warning "Environment configuration file not found, using system environment variables"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to download custom icons
download_custom_icons() {
    local bottom_menu_items="$1"
    
    if [ -z "$bottom_menu_items" ]; then
        log "No BOTTOMMENU_ITEMS provided, skipping custom icon download"
        return 0
    fi
    
    log "Processing BOTTOMMENU_ITEMS for custom icons..."
    
    # Create assets/icons directory if it doesn't exist
    mkdir -p assets/icons
    
    # Check if BOTTOMMENU_ITEMS contains custom icons
    if [[ "$bottom_menu_items" == *"custom"* ]] && [[ "$bottom_menu_items" == *"icon_url"* ]]; then
        log "Custom icons detected in BOTTOMMENU_ITEMS"
        
        # Extract icon URLs using grep and sed (simple approach)
        # This is a simplified approach that looks for icon_url patterns
        local icon_urls=$(echo "$bottom_menu_items" | grep -o 'icon_url[^,}]*' | sed 's/icon_url[^"]*"//g' | sed 's/"[^"]*$//g')
        
        if [ -n "$icon_urls" ]; then
            local downloaded_count=0
            
            # Process each icon URL
            while IFS= read -r icon_url; do
                if [ -n "$icon_url" ] && [[ "$icon_url" == http* ]]; then
                    # Extract filename from URL
                    local filename=$(basename "$icon_url")
                    if [ -z "$filename" ] || [ "$filename" = "$icon_url" ]; then
                        filename="custom_icon_$downloaded_count.svg"
                    fi
                    
                    local filepath="assets/icons/$filename"
                    
                    log "Downloading custom icon from $icon_url..."
                    if curl -fsSL -o "$filepath" "$icon_url"; then
                        success "✓ Downloaded $filename"
                        downloaded_count=$((downloaded_count + 1))
                    else
                        warning "Failed to download icon from $icon_url"
                    fi
                fi
            done <<< "$icon_urls"
            
            if [ $downloaded_count -gt 0 ]; then
                success "Downloaded $downloaded_count custom icons"
            else
                warning "No custom icons were downloaded"
            fi
        else
            log "No valid icon URLs found in BOTTOMMENU_ITEMS"
        fi
    else
        log "No custom icons found in BOTTOMMENU_ITEMS, skipping download"
    fi
    
    return 0
}

# Main execution
main() {
    log "Starting custom icons download process..."
    
    # Check if BOTTOMMENU_ITEMS environment variable is set
    if [ -z "$BOTTOMMENU_ITEMS" ]; then
        warning "BOTTOMMENU_ITEMS environment variable not set"
        log "Skipping custom icon download"
        return 0
    fi
    
    # Download custom icons
    if download_custom_icons "$BOTTOMMENU_ITEMS"; then
        success "Custom icons download process completed"
        return 0
    else
        error "Custom icons download failed"
        return 1
    fi
}

# Run main function
main "$@"
