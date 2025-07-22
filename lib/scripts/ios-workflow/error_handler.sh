#!/bin/bash

# iOS Workflow Error Handler
# Purpose: Catch and fix common iOS workflow issues

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

log_info "🛡️ iOS Workflow Error Handler"

# Function to check and fix common issues
check_and_fix_issues() {
    log_info "🔍 Checking for common iOS workflow issues..."
    
    local issues_found=0
    
    # Check 1: Archive exists
    if [ ! -d "${OUTPUT_DIR:-output/ios}/Runner.xcarchive" ]; then
        log_error "❌ Archive not found: ${OUTPUT_DIR:-output/ios}/Runner.xcarchive"
        issues_found=$((issues_found + 1))
    else
        log_success "✅ Archive found: ${OUTPUT_DIR:-output/ios}/Runner.xcarchive"
    fi
    
    # Check 2: Export directory exists
    if [ ! -d "${OUTPUT_DIR:-output/ios}" ]; then
        log_warn "⚠️ Export directory not found, creating: ${OUTPUT_DIR:-output/ios}"
        mkdir -p "${OUTPUT_DIR:-output/ios}"
    else
        log_success "✅ Export directory exists: ${OUTPUT_DIR:-output/ios}"
    fi
    
    # Check 3: Bundle ID is set
    if [ -z "${BUNDLE_ID:-}" ]; then
        log_error "❌ BUNDLE_ID is not set"
        issues_found=$((issues_found + 1))
    else
        log_success "✅ BUNDLE_ID is set: ${BUNDLE_ID}"
    fi
    
    # Check 4: Team ID is set
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        log_error "❌ APPLE_TEAM_ID is not set"
        issues_found=$((issues_found + 1))
    else
        log_success "✅ APPLE_TEAM_ID is set: ${APPLE_TEAM_ID}"
    fi
    
    # Check 5: App Store Connect API credentials
    if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] || [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        log_warn "⚠️ App Store Connect API credentials not fully set"
        log_info "   - APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-NOT_SET}"
        log_info "   - APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-NOT_SET}"
    else
        log_success "✅ App Store Connect API credentials are set"
    fi
    
    # Check 6: iOS directory exists
    if [ ! -d "ios" ]; then
        log_error "❌ iOS directory not found"
        issues_found=$((issues_found + 1))
    else
        log_success "✅ iOS directory exists"
    fi
    
    # Check 7: ExportOptionsModern.plist exists (if needed)
    if [ -f "ios/ExportOptionsModern.plist" ]; then
        log_success "✅ ExportOptionsModern.plist exists"
    else
        log_warn "⚠️ ExportOptionsModern.plist not found (will be created during export)"
    fi
    
    # Check 8: Xcode project files
    if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_error "❌ Xcode project not found: ios/Runner.xcodeproj/project.pbxproj"
        issues_found=$((issues_found + 1))
    else
        log_success "✅ Xcode project exists"
    fi
    
    # Check 9: Pods project (if using CocoaPods)
    if [ -d "ios/Pods" ] && [ ! -f "ios/Pods/Pods.xcodeproj/project.pbxproj" ]; then
        log_warn "⚠️ Pods project not found but Pods directory exists"
    elif [ -f "ios/Pods/Pods.xcodeproj/project.pbxproj" ]; then
        log_success "✅ Pods project exists"
    fi
    
    # Check 10: Keychain access
    if command -v security >/dev/null 2>&1; then
        local keychain_list
        keychain_list=$(security list-keychains 2>/dev/null | grep "ios-build.keychain" || true)
        if [ -n "$keychain_list" ]; then
            log_success "✅ iOS build keychain found"
        else
            log_warn "⚠️ iOS build keychain not found (may not be needed for modern signing)"
        fi
    else
        log_warn "⚠️ security command not available"
    fi
    
    return $issues_found
}

# Function to fix common issues
fix_common_issues() {
    log_info "🔧 Fixing common iOS workflow issues..."
    
    # Fix 1: Create export directory if missing
    if [ ! -d "${OUTPUT_DIR:-output/ios}" ]; then
        log_info "📁 Creating export directory: ${OUTPUT_DIR:-output/ios}"
        mkdir -p "${OUTPUT_DIR:-output/ios}"
    fi
    
    # Fix 2: Create iOS directory if missing
    if [ ! -d "ios" ]; then
        log_info "📁 Creating iOS directory"
        mkdir -p "ios"
    fi
    
    # Fix 3: Validate required environment variables (don't set defaults)
    if [ -z "${BUNDLE_ID:-}" ]; then
        log_error "❌ BUNDLE_ID is required but not set"
        log_error "💡 Please set BUNDLE_ID in your Codemagic environment variables"
        return 1
    fi
    
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        log_error "❌ APPLE_TEAM_ID is required but not set"
        log_error "💡 Please set APPLE_TEAM_ID in your Codemagic environment variables"
        return 1
    fi
    
    # Fix 4: Create basic ExportOptionsModern.plist if missing (using environment variables)
    if [ ! -f "ios/ExportOptionsModern.plist" ]; then
        log_info "📝 Creating basic ExportOptionsModern.plist"
        mkdir -p "ios"
        cat > "ios/ExportOptionsModern.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
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
    <string>${BUNDLE_ID}</string>
</dict>
</plist>
EOF
        log_success "✅ Basic ExportOptionsModern.plist created using environment variables"
    fi
    
    log_success "✅ Common issues fixed"
}

# Function to provide debugging information
provide_debug_info() {
    log_info "📋 Debug Information:"
    echo "========================================"
    echo "Environment Variables:"
    echo "  - BUNDLE_ID: ${BUNDLE_ID:-NOT_SET}"
    echo "  - APPLE_TEAM_ID: ${APPLE_TEAM_ID:-NOT_SET}"
    echo "  - OUTPUT_DIR: ${OUTPUT_DIR:-output/ios}"
    echo "  - APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-NOT_SET}"
    echo "  - APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-NOT_SET}"
    echo ""
    echo "File System:"
    echo "  - Archive: ${OUTPUT_DIR:-output/ios}/Runner.xcarchive ($([ -d "${OUTPUT_DIR:-output/ios}/Runner.xcarchive" ] && echo "EXISTS" || echo "MISSING"))"
    echo "  - Export Dir: ${OUTPUT_DIR:-output/ios} ($([ -d "${OUTPUT_DIR:-output/ios}" ] && echo "EXISTS" || echo "MISSING"))"
    echo "  - iOS Dir: ios ($([ -d "ios" ] && echo "EXISTS" || echo "MISSING"))"
    echo "  - ExportOptionsModern.plist: ios/ExportOptionsModern.plist ($([ -f "ios/ExportOptionsModern.plist" ] && echo "EXISTS" || echo "MISSING"))"
    echo "  - Xcode Project: ios/Runner.xcodeproj/project.pbxproj ($([ -f "ios/Runner.xcodeproj/project.pbxproj" ] && echo "EXISTS" || echo "MISSING"))"
    echo ""
    echo "System:"
    echo "  - Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo "NOT_AVAILABLE")"
    echo "  - Security: $(command -v security >/dev/null 2>&1 && echo "AVAILABLE" || echo "NOT_AVAILABLE")"
    echo "  - plutil: $(command -v plutil >/dev/null 2>&1 && echo "AVAILABLE" || echo "NOT_AVAILABLE")"
    echo "========================================"
}

# Main execution
main() {
    log_info "🚀 iOS Workflow Error Handler Starting..."
    
    # Check for issues
    if check_and_fix_issues; then
        log_success "✅ No critical issues found"
    else
        log_warn "⚠️ Issues found, attempting to fix..."
        fix_common_issues
    fi
    
    # Provide debug information
    provide_debug_info
    
    log_success "✅ Error handler completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 