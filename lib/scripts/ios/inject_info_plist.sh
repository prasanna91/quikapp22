#!/bin/bash

# 📱 iOS Info.plist Dynamic Injection Script
# Injects all values from environment variables into Info.plist

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

# Function to safely get environment variable with default
get_env_var() {
    local var_name="$1"
    local default_value="${2:-}"
    local value="${!var_name:-$default_value}"
    
    if [ -z "$value" ]; then
        echo -e "${RED}❌ Required environment variable $var_name is not set${NC}"
        return 1
    fi
    
    echo "$value"
}

# Function to update Info.plist key
update_info_plist_key() {
    local info_plist="$1"
    local key="$2"
    local value="$3"
    local value_type="${4:-string}"
    
    echo -e "${BLUE}🔧 Updating $key to: $value${NC}"
    
    case "$value_type" in
        "string")
            plutil -replace "$key" -string "$value" "$info_plist"
            ;;
        "bool")
            plutil -replace "$key" -bool "$value" "$info_plist"
            ;;
        "array")
            plutil -replace "$key" -array "$value" "$info_plist"
            ;;
        "dict")
            plutil -replace "$key" -dict "$value" "$info_plist"
            ;;
        *)
            plutil -replace "$key" -string "$value" "$info_plist"
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully updated $key${NC}"
    else
        echo -e "${RED}❌ Failed to update $key${NC}"
        return 1
    fi
}

# Function to add Info.plist key if it doesn't exist
add_info_plist_key() {
    local info_plist="$1"
    local key="$2"
    local value="$3"
    local value_type="${4:-string}"
    
    # Check if key exists
    if plutil -extract "$key" raw "$info_plist" >/dev/null 2>&1; then
        echo -e "${BLUE}🔧 Key $key already exists, updating...${NC}"
        update_info_plist_key "$info_plist" "$key" "$value" "$value_type"
    else
        echo -e "${BLUE}🔧 Adding new key $key with value: $value${NC}"
        case "$value_type" in
            "string")
                plutil -insert "$key" -string "$value" "$info_plist"
                ;;
            "bool")
                plutil -insert "$key" -bool "$value" "$info_plist"
                ;;
            "array")
                plutil -insert "$key" -array "$value" "$info_plist"
                ;;
            "dict")
                plutil -insert "$key" -dict "$value" "$info_plist"
                ;;
            *)
                plutil -insert "$key" -string "$value" "$info_plist"
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Successfully added $key${NC}"
        else
            echo -e "${RED}❌ Failed to add $key${NC}"
            return 1
        fi
    fi
}

# Function to inject permissions based on feature flags
inject_permissions() {
    local info_plist="$1"
    
    echo -e "${BLUE}🔐 Injecting permissions based on feature flags${NC}"
    
    # Camera permission
    if [ "${IS_CAMERA:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSCameraUsageDescription" \
            "This app needs access to camera to capture photos and videos."
    fi
    
    # Location permission
    if [ "${IS_LOCATION:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSLocationWhenInUseUsageDescription" \
            "This app needs access to location when in use."
        add_info_plist_key "$info_plist" "NSLocationAlwaysAndWhenInUseUsageDescription" \
            "This app needs access to location always and when in use."
        add_info_plist_key "$info_plist" "NSLocationAlwaysUsageDescription" \
            "This app needs access to location always."
    fi
    
    # Microphone permission
    if [ "${IS_MIC:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSMicrophoneUsageDescription" \
            "This app needs access to microphone to record audio."
    fi
    
    # Contacts permission
    if [ "${IS_CONTACT:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSContactsUsageDescription" \
            "This app needs access to contacts to manage contact information."
    fi
    
    # Biometric permission
    if [ "${IS_BIOMETRIC:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSFaceIDUsageDescription" \
            "This app uses Face ID for secure authentication."
    fi
    
    # Calendar permission
    if [ "${IS_CALENDAR:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSCalendarsUsageDescription" \
            "This app needs access to calendar to manage events."
    fi
    
    # Storage permission
    if [ "${IS_STORAGE:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSPhotoLibraryUsageDescription" \
            "This app needs access to photo library to save and retrieve images."
        add_info_plist_key "$info_plist" "NSPhotoLibraryAddUsageDescription" \
            "This app needs access to save photos to your photo library."
    fi
    
    # Notification permission
    if [ "${IS_NOTIFICATION:-false}" = "true" ]; then
        add_info_plist_key "$info_plist" "NSUserNotificationUsageDescription" \
            "This app needs to send notifications to keep you updated."
    fi
    
    echo -e "${GREEN}✅ Permissions injection completed${NC}"
}

# Main function
inject_info_plist() {
    echo -e "${BLUE}📱 iOS Info.plist Dynamic Injection${NC}"
    echo "=========================================="
    echo ""
    
    # Define Info.plist path
    local info_plist="ios/Runner/Info.plist"
    
    # Check if Info.plist exists
    if [ ! -f "$info_plist" ]; then
        echo -e "${RED}❌ Info.plist not found: $info_plist${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Info.plist found: $info_plist${NC}"
    echo ""
    
    # Create backup
    local backup_file="${info_plist}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$info_plist" "$backup_file"
    echo -e "${BLUE}📋 Created backup: $backup_file${NC}"
    echo ""
    
    # Get environment variables with defaults
    echo -e "${BLUE}📋 Getting environment variables${NC}"
    echo "----------------------------------------"
    
    local app_name=$(get_env_var "APP_NAME" "QuikApp")
    local bundle_id=$(get_env_var "BUNDLE_ID" "com.quikapp.app")
    local version_name=$(get_env_var "VERSION_NAME" "1.0.0")
    local version_code=$(get_env_var "VERSION_CODE" "1")
    local org_name=$(get_env_var "ORG_NAME" "QuikApp")
    
    echo -e "${GREEN}✅ Environment variables loaded:${NC}"
    echo "  - App Name: $app_name"
    echo "  - Bundle ID: $bundle_id"
    echo "  - Version Name: $version_name"
    echo "  - Version Code: $version_code"
    echo "  - Organization: $org_name"
    echo ""
    
    # Inject basic app information
    echo -e "${BLUE}📋 Injecting basic app information${NC}"
    echo "----------------------------------------"
    
    add_info_plist_key "$info_plist" "CFBundleDisplayName" "$app_name"
    add_info_plist_key "$info_plist" "CFBundleName" "$app_name"
    add_info_plist_key "$info_plist" "CFBundleIdentifier" "$bundle_id"
    add_info_plist_key "$info_plist" "CFBundleShortVersionString" "$version_name"
    add_info_plist_key "$info_plist" "CFBundleVersion" "$version_code"
    
    # Ensure CFBundleExecutable is set
    add_info_plist_key "$info_plist" "CFBundleExecutable" "Runner"
    
    # Ensure UILaunchStoryboardName is set
    add_info_plist_key "$info_plist" "UILaunchStoryboardName" "LaunchScreen"
    
    echo ""
    
    # Inject orientation support
    echo -e "${BLUE}📋 Injecting orientation support${NC}"
    echo "----------------------------------------"
    
    # iPhone orientations
    plutil -replace UISupportedInterfaceOrientations -array ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations.0 -string "UIInterfaceOrientationPortrait" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations.1 -string "UIInterfaceOrientationPortraitUpsideDown" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations.2 -string "UIInterfaceOrientationLandscapeLeft" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations.3 -string "UIInterfaceOrientationLandscapeRight" ios/Runner/Info.plist
    
    # iPad orientations
    plutil -replace UISupportedInterfaceOrientations~ipad -array ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations~ipad.0 -string "UIInterfaceOrientationPortrait" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations~ipad.1 -string "UIInterfaceOrientationPortraitUpsideDown" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations~ipad.2 -string "UIInterfaceOrientationLandscapeLeft" ios/Runner/Info.plist
    plutil -insert UISupportedInterfaceOrientations~ipad.3 -string "UIInterfaceOrientationLandscapeRight" ios/Runner/Info.plist
    
    echo -e "${GREEN}✅ Orientation support configured${NC}"
    echo ""
    
    # Inject network security
    echo -e "${BLUE}📋 Injecting network security configuration${NC}"
    echo "----------------------------------------"
    
    # Try robust remove-insert approach first
    if plutil -remove NSAppTransportSecurity ios/Runner/Info.plist >/dev/null 2>&1; then
        echo -e "${BLUE}🔧 Removed existing NSAppTransportSecurity${NC}"
    fi
    
    # Insert the dictionary
    if plutil -insert NSAppTransportSecurity -dict ios/Runner/Info.plist; then
        echo -e "${BLUE}🔧 Inserted NSAppTransportSecurity dictionary${NC}"
        # Insert the boolean value
        if plutil -insert NSAppTransportSecurity.NSAllowsArbitraryLoads -bool false ios/Runner/Info.plist; then
            echo -e "${GREEN}✅ Network security configured via plutil${NC}"
        else
            echo -e "${YELLOW}⚠️ Failed to insert NSAllowsArbitraryLoads via plutil, trying direct injection${NC}"
            # Fallback: direct injection using cat EOF
            cat >> ios/Runner/Info.plist << 'EOF'
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
	</dict>
EOF
            echo -e "${GREEN}✅ Network security configured via direct injection${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Failed to insert NSAppTransportSecurity via plutil, trying direct injection${NC}"
        # Fallback: direct injection using cat EOF
        cat >> ios/Runner/Info.plist << 'EOF'
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<false/>
	</dict>
EOF
        echo -e "${GREEN}✅ Network security configured via direct injection${NC}"
    fi
    
    echo ""
    
    # Inject permissions based on feature flags
    inject_permissions "$info_plist"
    echo ""
    
    # Inject additional required keys for App Store
    echo -e "${BLUE}📋 Injecting App Store required keys${NC}"
    echo "----------------------------------------"
    
    # UIRequiresFullScreen (for multitasking support)
    add_info_plist_key "$info_plist" "UIRequiresFullScreen" "false" "bool"
    
    # UIStatusBarHidden
    add_info_plist_key "$info_plist" "UIStatusBarHidden" "false" "bool"
    
    # UISupportedInterfaceOrientations~ipad (already set above)
    echo -e "${GREEN}✅ App Store required keys configured${NC}"
    echo ""
    
    # Validate the updated Info.plist
    echo -e "${BLUE}📋 Validating updated Info.plist${NC}"
    echo "----------------------------------------"
    
    if plutil -lint "$info_plist" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Info.plist validation passed${NC}"
    else
        echo -e "${RED}❌ Info.plist validation failed${NC}"
        echo -e "${YELLOW}📋 Validation errors:${NC}"
        plutil -lint "$info_plist" 2>&1 || true
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 iOS Info.plist Dynamic Injection Complete!${NC}"
    echo -e "${BLUE}💡 All values have been injected from environment variables.${NC}"
    echo -e "${BLUE}💡 Backup created at: $backup_file${NC}"
    
    # Show final Info.plist summary
    echo ""
    echo -e "${BLUE}📋 Final Info.plist Summary:${NC}"
    echo "----------------------------------------"
    echo "CFBundleDisplayName: $(plutil -extract CFBundleDisplayName raw "$info_plist" 2>/dev/null || echo "Not set")"
    echo "CFBundleIdentifier: $(plutil -extract CFBundleIdentifier raw "$info_plist" 2>/dev/null || echo "Not set")"
    echo "CFBundleShortVersionString: $(plutil -extract CFBundleShortVersionString raw "$info_plist" 2>/dev/null || echo "Not set")"
    echo "CFBundleVersion: $(plutil -extract CFBundleVersion raw "$info_plist" 2>/dev/null || echo "Not set")"
    echo "UILaunchStoryboardName: $(plutil -extract UILaunchStoryboardName raw "$info_plist" 2>/dev/null || echo "Not set")"
}

# Run the injection
inject_info_plist 