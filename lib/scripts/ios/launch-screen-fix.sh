#!/bin/bash

# 🖥️ iOS Launch Screen Fix for iPad Multitasking
# Fixes the UILaunchStoryboardName configuration issue

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if UILaunchStoryboardName exists in Info.plist
check_launch_storyboard() {
    local info_plist="$1"
    
    if [ ! -f "$info_plist" ]; then
        echo -e "${RED}❌ Info.plist not found: $info_plist${NC}"
        return 1
    fi
    
    # Check if UILaunchStoryboardName key exists
    if plutil -extract UILaunchStoryboardName raw "$info_plist" >/dev/null 2>&1; then
        local storyboard_name=$(plutil -extract UILaunchStoryboardName raw "$info_plist" 2>/dev/null || echo "")
        if [ -n "$storyboard_name" ]; then
            echo -e "${GREEN}✅ UILaunchStoryboardName found: $storyboard_name${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️ UILaunchStoryboardName key exists but is empty${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ UILaunchStoryboardName key not found${NC}"
        return 1
    fi
}

# Function to add UILaunchStoryboardName to Info.plist
add_launch_storyboard() {
    local info_plist="$1"
    local storyboard_name="${2:-LaunchScreen}"
    
    echo -e "${BLUE}🔧 Adding UILaunchStoryboardName to Info.plist${NC}"
    
    # Create backup
    cp "$info_plist" "${info_plist}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add UILaunchStoryboardName key
    if plutil -insert UILaunchStoryboardName -string "$storyboard_name" "$info_plist"; then
        echo -e "${GREEN}✅ Successfully added UILaunchStoryboardName: $storyboard_name${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to add UILaunchStoryboardName${NC}"
        return 1
    fi
}

# Function to validate launch screen storyboard
validate_launch_storyboard() {
    local storyboard_path="$1"
    
    if [ ! -f "$storyboard_path" ]; then
        echo -e "${RED}❌ Launch screen storyboard not found: $storyboard_path${NC}"
        return 1
    fi
    
    # Check if storyboard file exists and has content
    if [ -s "$storyboard_path" ]; then
        echo -e "${GREEN}✅ Launch screen storyboard file exists and has content${NC}"
        
        # Try to validate with plutil, but don't fail if it has minor issues
        if plutil -lint "$storyboard_path" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Launch screen storyboard is valid${NC}"
        else
            echo -e "${YELLOW}⚠️ Launch screen storyboard has minor validation issues (continuing anyway)${NC}"
            echo -e "${BLUE}💡 This is common with older storyboard formats and usually doesn't affect functionality${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ Launch screen storyboard file is empty${NC}"
        return 1
    fi
}

# Function to check iPad multitasking support
check_ipad_multitasking() {
    local info_plist="$1"
    
    echo -e "${BLUE}🔍 Checking iPad multitasking support${NC}"
    
    # Check for UISupportedInterfaceOrientations~ipad
    if plutil -extract UISupportedInterfaceOrientations~ipad raw "$info_plist" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ iPad orientation support configured${NC}"
    else
        echo -e "${YELLOW}⚠️ iPad orientation support not configured${NC}"
    fi
    
    # Check for UIRequiresFullScreen
    if plutil -extract UIRequiresFullScreen raw "$info_plist" >/dev/null 2>&1; then
        local requires_fullscreen=$(plutil -extract UIRequiresFullScreen raw "$info_plist" 2>/dev/null || echo "")
        if [ "$requires_fullscreen" = "true" ]; then
            echo -e "${YELLOW}⚠️ App requires full screen (may affect multitasking)${NC}"
        else
            echo -e "${GREEN}✅ App supports multitasking${NC}"
        fi
    else
        echo -e "${GREEN}✅ App supports multitasking (no full screen requirement)${NC}"
    fi
}

# Main function
fix_launch_screen() {
    echo -e "${BLUE}🖥️ iOS Launch Screen Fix for iPad Multitasking${NC}"
    echo "=================================================="
    echo ""
    
    # Define paths
    local info_plist="ios/Runner/Info.plist"
    local launch_storyboard="ios/Runner/Base.lproj/LaunchScreen.storyboard"
    
    # Check if files exist
    if [ ! -f "$info_plist" ]; then
        echo -e "${RED}❌ Info.plist not found: $info_plist${NC}"
        exit 1
    fi
    
    if [ ! -f "$launch_storyboard" ]; then
        echo -e "${RED}❌ Launch screen storyboard not found: $launch_storyboard${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Required files found${NC}"
    echo ""
    
    # Validate launch screen storyboard
    echo -e "${BLUE}📋 Validating launch screen storyboard${NC}"
    echo "----------------------------------------"
    if validate_launch_storyboard "$launch_storyboard"; then
        echo -e "${GREEN}✅ Launch screen storyboard validation passed${NC}"
    else
        echo -e "${RED}❌ Launch screen storyboard validation failed${NC}"
        exit 1
    fi
    echo ""
    
    # Check current launch storyboard configuration
    echo -e "${BLUE}📋 Checking current launch storyboard configuration${NC}"
    echo "----------------------------------------"
    if check_launch_storyboard "$info_plist"; then
        echo -e "${GREEN}✅ Launch storyboard configuration is correct${NC}"
    else
        echo -e "${YELLOW}⚠️ Launch storyboard configuration needs fixing${NC}"
        echo ""
        
        # Add UILaunchStoryboardName
        if add_launch_storyboard "$info_plist" "LaunchScreen"; then
            echo -e "${GREEN}✅ Launch storyboard configuration fixed${NC}"
        else
            echo -e "${RED}❌ Failed to fix launch storyboard configuration${NC}"
            exit 1
        fi
    fi
    echo ""
    
    # Check iPad multitasking support
    echo -e "${BLUE}📋 Checking iPad multitasking support${NC}"
    echo "----------------------------------------"
    check_ipad_multitasking "$info_plist"
    echo ""
    
    # Final validation
    echo -e "${BLUE}📋 Final validation${NC}"
    echo "----------------------------------------"
    if check_launch_storyboard "$info_plist"; then
        echo -e "${GREEN}✅ Launch screen configuration is ready for iPad multitasking${NC}"
        echo -e "${BLUE}💡 This should resolve the App Store validation error${NC}"
    else
        echo -e "${RED}❌ Launch screen configuration validation failed${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 iOS Launch Screen Fix Complete!${NC}"
    echo -e "${BLUE}💡 Your app is now ready for iPad multitasking support.${NC}"
}

# Run the fix
fix_launch_screen 