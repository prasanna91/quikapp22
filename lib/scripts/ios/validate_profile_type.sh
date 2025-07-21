#!/bin/bash

# Profile Type Validation Script
# Validates and configures PROFILE_TYPE for iOS builds

set -e

# Function to log messages
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1"
}

# Main profile type validation function
validate_profile_type() {
    log_info "🔍 Validating profile type configuration..."
    
    # Set default if not provided
    PROFILE_TYPE=${PROFILE_TYPE:-"ad-hoc"}
    log_info "📋 Current Profile Type: $PROFILE_TYPE"
    
    # Validate profile type
    case "$PROFILE_TYPE" in
        "app-store"|"ad-hoc")
            log_success "✅ Valid profile type: $PROFILE_TYPE"
            ;;
        *)
            log_warn "⚠️ Invalid profile type '$PROFILE_TYPE', defaulting to 'ad-hoc'"
            PROFILE_TYPE="ad-hoc"
            ;;
    esac
    
    # Export validated profile type
    export PROFILE_TYPE="$PROFILE_TYPE"
    log_info "🎯 Final Profile Type: $PROFILE_TYPE"
    
    # Display configuration summary
    display_build_configuration
    
    return 0
}

# Function to display build configuration summary
display_build_configuration() {
    log_info "📊 Build Configuration Summary:"
    echo "  - Bundle ID: ${BUNDLE_ID:-'Not set'}"
    echo "  - Profile Type: $PROFILE_TYPE"
    echo "  - App Name: ${APP_NAME:-'Not set'}"
    echo "  - Version: ${VERSION_NAME:-'Not set'} (${VERSION_CODE:-'Not set'})"
    echo "  - Team ID: ${APPLE_TEAM_ID:-'Not set'}"
    
    # Profile-specific information
    case "$PROFILE_TYPE" in
        "app-store")
            log_info "🏪 App Store build configuration:"
            echo "  - Distribution method: App Store Connect"
            echo "  - Symbols upload: Enabled"
            echo "  - Bitcode: Disabled (iOS 14+)"
            echo "  - Target: TestFlight/App Store"
            ;;
        "ad-hoc")
            log_info "📱 Ad Hoc build configuration:"
            echo "  - Distribution method: Ad Hoc"
            echo "  - Symbols upload: Disabled"
            echo "  - Target: Direct device installation"
            ;;
    esac
}

# Function to create ExportOptions.plist based on profile type
create_export_options() {
    local export_path="${1:-ios/ExportOptions.plist}"
    
    log_info "📝 Creating ExportOptions.plist for profile type: $PROFILE_TYPE"
    
    case "$PROFILE_TYPE" in
        "app-store")
            create_app_store_export_options "$export_path"
            ;;
        "ad-hoc")
            create_ad_hoc_export_options "$export_path"
            ;;
        *)
            log_error "❌ Unsupported profile type: $PROFILE_TYPE"
            return 1
            ;;
    esac
    
    # Replace environment variables
    if [ -f "$export_path" ]; then
        sed -i.tmp "s/\$APPLE_TEAM_ID/${APPLE_TEAM_ID}/g" "$export_path"
        sed -i.tmp "s/\$BUNDLE_ID/${BUNDLE_ID}/g" "$export_path"
        rm -f "$export_path.tmp"
        
        log_info "📋 ExportOptions.plist created successfully"
        log_info "Contents:"
        cat "$export_path"
    fi
}

# App Store ExportOptions.plist
create_app_store_export_options() {
    cat > "$1" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>thinning</key>
  <string>&lt;none&gt;</string>
  <key>distributionBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>generateAppStoreInformation</key>
  <false/>
  <key>manageVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
EOF
}

# Fallback Development ExportOptions.plist (when App Store export fails)
create_fallback_development_export_options() {
    cat > "$1" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>development</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>thinning</key>
  <string>&lt;none&gt;</string>
  <key>distributionBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>iCloudContainerEnvironment</key>
  <string>Development</string>
</dict>
</plist>
EOF
}

# Ad Hoc ExportOptions.plist
create_ad_hoc_export_options() {
    cat > "$1" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>ad-hoc</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>thinning</key>
  <string>&lt;none&gt;</string>
  <key>distributionBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
</dict>
</plist>
EOF
}



# Main execution
main() {
    log_info "🚀 Starting Profile Type Validation..."
    
    validate_profile_type
    
    # Create ExportOptions.plist if requested
    if [ "${1:-}" = "--create-export-options" ]; then
        create_export_options "${2:-ios/ExportOptions.plist}"
    fi
    
    log_success "✅ Profile type validation completed"
    
    return 0
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi 