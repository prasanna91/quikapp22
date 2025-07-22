#!/bin/bash

# Simple IPA Export Script for Modern App Store Connect API
# Purpose: Export IPA using modern code signing without complex framework handling

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    log_info "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    log_error "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    exit 1
fi

log_info "🚀 Simple IPA Export for Modern App Store Connect API"

# Function to create simple export options
create_simple_export_options() {
    local bundle_id="$1"
    local team_id="$2"
    
    log_info "📝 Creating simple export options..."
    log_info "📦 Bundle ID: $bundle_id"
    log_info "👥 Team ID: $team_id"
    
    # Validate inputs
    if [ -z "$bundle_id" ]; then
        log_error "❌ Bundle ID is required"
        return 1
    fi
    
    if [ -z "$team_id" ]; then
        log_error "❌ Team ID is required"
        return 1
    fi
    
    # Ensure ios directory exists
    mkdir -p "ios"
    
    # Create simple export options
    cat > "ios/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${team_id}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>iCloudContainerEnvironment</key>
    <string>Production</string>
    <key>onDemandInstallCapable</key>
    <false/>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>distributionBundleIdentifier</key>
    <string>${bundle_id}</string>
</dict>
</plist>
EOF
    
    log_success "✅ Simple export options created: ios/ExportOptions.plist"
    
    # Verify the file was created
    if [ -f "ios/ExportOptions.plist" ]; then
        log_success "✅ ExportOptions.plist created successfully"
        log_info "📄 File size: $(wc -c < "ios/ExportOptions.plist") bytes"
        return 0
    else
        log_error "❌ Failed to create ExportOptions.plist"
        return 1
    fi
}

# Function to export IPA using simple approach
export_ipa_simple() {
    local archive_path="$1"
    local export_path="$2"
    local bundle_id="$3"
    local team_id="$4"
    
    log_info "🚀 Exporting IPA using simple approach..."
    log_info "📁 Archive: $archive_path"
    log_info "📁 Export Path: $export_path"
    log_info "📦 Bundle ID: $bundle_id"
    log_info "👥 Team ID: $team_id"
    
    # Validate archive exists
    if [ ! -d "$archive_path" ]; then
        log_error "❌ Archive not found: $archive_path"
        return 1
    fi
    
    # Ensure export directory exists
    mkdir -p "$export_path"
    
    # Create export options
    if ! create_simple_export_options "$bundle_id" "$team_id"; then
        log_error "❌ Failed to create export options"
        return 1
    fi
    
    # Export IPA using simple approach
    log_info "📦 Exporting IPA with simple App Store Connect API..."
    
    if xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "ios/ExportOptions.plist" \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration; then
        
        log_success "✅ IPA exported successfully using simple approach"
        
        # Find the exported IPA
        local exported_ipa
        exported_ipa=$(find "$export_path" -name "*.ipa" -type f | head -1)
        
        if [ -n "$exported_ipa" ]; then
            log_success "✅ IPA file created: $exported_ipa"
            log_info "📱 Bundle ID: $bundle_id"
            log_info "🔐 Team ID: $team_id"
            log_info "🔐 Modern code signing: App Store Connect API"
            return 0
        else
            log_error "❌ IPA file not found in export directory"
            return 1
        fi
    else
        log_error "❌ IPA export failed using simple approach"
        return 1
    fi
}

# Main function
main() {
    log_info "🚀 Simple IPA Export Starting..."
    
    # Validate required parameters
    local archive_path="${1:-${OUTPUT_DIR:-output/ios}/Runner.xcarchive}"
    local export_path="${2:-${OUTPUT_DIR:-output/ios}}"
    local bundle_id="${3:-${BUNDLE_ID}}"
    local team_id="${4:-${APPLE_TEAM_ID}}"
    
    # Validate required environment variables
    if [ -z "$bundle_id" ]; then
        log_error "❌ BUNDLE_ID is required"
        log_error "🔧 Please set BUNDLE_ID environment variable"
        return 1
    fi
    
    if [ -z "$team_id" ]; then
        log_error "❌ APPLE_TEAM_ID is required"
        log_error "🔧 Please set APPLE_TEAM_ID environment variable"
        return 1
    fi
    
    # Check if we're using modern code signing (App Store Connect API)
    if [[ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]]; then
        log_info "📱 Modern code signing detected - using App Store Connect API"
        log_info "🔐 Automatic code signing will handle certificates during export"
        log_success "✅ Modern code signing configured"
    else
        log_error "❌ Modern code signing requires App Store Connect API credentials"
        log_error "🔧 Required variables:"
        log_error "   - APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-NOT_SET}"
        log_error "   - APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-NOT_SET}"
        log_error "💡 Please configure App Store Connect API credentials for modern code signing"
        return 1
    fi
    
    # Export IPA using simple approach
    if export_ipa_simple "$archive_path" "$export_path" "$bundle_id" "$team_id"; then
        log_success "🎉 Simple IPA export completed successfully!"
        return 0
    else
        log_error "❌ Simple IPA export failed"
        return 1
    fi
}

# Execute main function
main "$@" 