#!/bin/bash

# Comprehensive iOS Build Script
# Purpose: Build, archive, export IPA, and upload to TestFlight in one workflow

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    echo "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    echo "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    echo "⚠️ Using fallback logging functions"
    
    # Define fallback logging functions
    log_info() { echo "INFO: $*"; }
    log_error() { echo "ERROR: $*"; }
    log_success() { echo "SUCCESS: $*"; }
    log_warn() { echo "WARN: $*"; }
    log_warning() { echo "WARN: $*"; }
fi

# Source environment configuration
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
else
    log_warning "⚠️ Environment configuration file not found, using system environment variables"
fi

log_info "🚀 Starting Comprehensive iOS Build Workflow..."

# Function to validate environment variables
validate_environment() {
    log_info "🔍 Validating environment variables..."
    
    local required_vars=(
        "BUNDLE_ID"
        "APPLE_TEAM_ID"
        "APP_STORE_CONNECT_KEY_IDENTIFIER"
        "APP_STORE_CONNECT_ISSUER_ID"
        "APP_STORE_CONNECT_API_KEY_URL"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "❌ Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "   - $var"
        done
        return 1
    fi
    
    log_success "✅ All required environment variables are set"
    return 0
}

# Function to fix Swift optimization warnings
fix_swift_optimization() {
    log_info "🔧 Fixing Swift optimization warnings..."
    
    if [ -f "${SCRIPT_DIR}/fix_swift_optimization.sh" ]; then
        chmod +x "${SCRIPT_DIR}/fix_swift_optimization.sh"
        if "${SCRIPT_DIR}/fix_swift_optimization.sh"; then
            log_success "✅ Swift optimization warnings fixed"
            return 0
        else
            log_warn "⚠️ Swift optimization fix failed (continuing...)"
            return 0
        fi
    else
        log_warn "⚠️ Swift optimization fix script not found (continuing...)"
        return 0
    fi
}

# Function to fix iOS deployment target
fix_deployment_target() {
    log_info "🔧 Fixing iOS deployment target..."
    
    if [ -f "${SCRIPT_DIR}/simple_deployment_target_fix.sh" ]; then
        chmod +x "${SCRIPT_DIR}/simple_deployment_target_fix.sh"
        if "${SCRIPT_DIR}/simple_deployment_target_fix.sh"; then
            log_success "✅ iOS deployment target fixed to 13.0"
            return 0
        else
            log_error "❌ iOS deployment target fix failed"
            return 1
        fi
    else
        log_error "❌ iOS deployment target fix script not found"
        return 1
    fi
}

# Function to inject bundle ID for Runner target
inject_bundle_id() {
    log_info "🔧 Injecting bundle ID for Runner target..."
    
    if [ -f "${SCRIPT_DIR}/simple_bundle_id_inject.sh" ]; then
        chmod +x "${SCRIPT_DIR}/simple_bundle_id_inject.sh"
        if "${SCRIPT_DIR}/simple_bundle_id_inject.sh"; then
            log_success "✅ Bundle ID injected for Runner target"
            return 0
        else
            log_error "❌ Bundle ID injection failed"
            return 1
        fi
    else
        log_error "❌ Bundle ID injection script not found"
        return 1
    fi
}

# Function to build and archive in one step
build_and_archive() {
    log_info "🏗️ Building and archiving iOS app..."
    
    # Check if Flutter is available
    if ! command -v flutter >/dev/null 2>&1; then
        log_error "❌ Flutter is not available"
        return 1
    fi
    
    # Check if Xcode is available
    if ! command -v xcodebuild >/dev/null 2>&1; then
        log_error "❌ Xcode is not available"
        return 1
    fi
    
    # Check if workspace exists
    if [ ! -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
        log_error "❌ iOS workspace not found: ios/Runner.xcworkspace"
        return 1
    fi
    
    local output_dir="${OUTPUT_DIR:-output/ios}"
    mkdir -p "$output_dir"
    
    log_info "📦 Building Flutter app for iOS..."
    log_info "📁 Output directory: $output_dir"
    log_info "📦 Version: ${VERSION_NAME:-1.0.0} (${VERSION_CODE:-1})"
    log_info "📦 Bundle ID: ${BUNDLE_ID}"
    log_info "👥 Team ID: ${APPLE_TEAM_ID}"
    
    # Step 1: Build Flutter app
    log_info "📦 Step 1: Building Flutter app..."
    if flutter build ios \
        --release \
        --no-codesign \
        --build-number="${VERSION_CODE:-1}" \
        --build-name="${VERSION_NAME:-1.0.0}"; then
        
        log_success "✅ Flutter app built successfully"
    else
        log_error "❌ Flutter app build failed"
        return 1
    fi
    
    # Step 2: Create archive
    log_info "📦 Step 2: Creating Xcode archive..."
    log_info "📁 Archive path: ${output_dir}/Runner.xcarchive"
    log_info "📁 Workspace: ios/Runner.xcworkspace"
    log_info "📦 Scheme: Runner"
    log_info "🔧 Configuration: Release"
    
    if xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -configuration Release \
        -archivePath "${output_dir}/Runner.xcarchive" \
        -destination generic/platform=iOS \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration \
        archive; then
        
        log_success "✅ Xcode archive created successfully: ${output_dir}/Runner.xcarchive"
        return 0
    else
        log_error "❌ Xcode archive creation failed"
        return 1
    fi
}

# Function to export IPA
export_ipa() {
    log_info "📦 Exporting IPA..."
    
    local output_dir="${OUTPUT_DIR:-output/ios}"
    local archive_path="${output_dir}/Runner.xcarchive"
    local export_path="$output_dir"
    
    # Debug information
    log_info "🔧 Debug information for IPA export:"
    log_info "📁 Archive path: $archive_path"
    log_info "📁 Export path: $export_path"
    log_info "📦 Bundle ID: ${BUNDLE_ID}"
    log_info "👥 Team ID: ${APPLE_TEAM_ID}"
    log_info "📁 Archive exists: $([ -d "$archive_path" ] && echo "YES" || echo "NO")"
    
    # Validate archive exists
    if [ ! -d "$archive_path" ]; then
        log_error "❌ Archive not found: $archive_path"
        return 1
    fi
    
    # Create export options
    log_info "📝 Creating export options..."
    mkdir -p "ios"
    
    cat > "ios/ExportOptions.plist" << EOF
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
    
    log_success "✅ Export options created: ios/ExportOptions.plist"
    
    # Export IPA
    log_info "📦 Exporting IPA with App Store Connect API..."
    
    if xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "ios/ExportOptions.plist" \
        -allowProvisioningUpdates \
        -allowProvisioningDeviceRegistration; then
        
        log_success "✅ IPA exported successfully"
        
        # Find the exported IPA
        local exported_ipa
        exported_ipa=$(find "$export_path" -name "*.ipa" -type f | head -1)
        
        if [ -n "$exported_ipa" ]; then
            log_success "✅ IPA file created: $exported_ipa"
            local ipa_size
            ipa_size=$(stat -f%z "$exported_ipa" 2>/dev/null || stat -c%s "$exported_ipa" 2>/dev/null || echo "0")
            log_info "📦 IPA size: $ipa_size bytes"
            return 0
        else
            log_error "❌ IPA file not found in export directory"
            return 1
        fi
    else
        log_error "❌ IPA export failed"
        return 1
    fi
}

# Function to upload to TestFlight
upload_to_testflight() {
    log_info "🚀 Uploading to TestFlight..."
    
    # Check if TestFlight upload is enabled and credentials are available
    if [ "${IS_TESTFLIGHT:-true}" = "true" ] && [ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] && [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ] && [ -n "${APP_STORE_CONNECT_API_KEY_URL:-}" ]; then
        log_info "📤 Uploading to TestFlight..."
        
        # Download API key
        local api_key_path="/tmp/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
        log_info "📥 Downloading API key from: ${APP_STORE_CONNECT_API_KEY_URL}"
        
        if curl -L -o "$api_key_path" "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
            chmod 600 "$api_key_path"
            log_success "✅ API key downloaded"
            
            # Find IPA file
            local output_dir="${OUTPUT_DIR:-output/ios}"
            local ipa_files
            ipa_files=$(find "$output_dir" -name "*.ipa" -type f 2>/dev/null || true)
            
            if [ -n "$ipa_files" ]; then
                local ipa_path
                ipa_path=$(echo "$ipa_files" | head -1)
                log_info "📦 Uploading IPA: $ipa_path"
                
                # Use xcrun altool for upload (modern approach)
                if xcrun altool --upload-app --type ios --file "$ipa_path" --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" --apiKeyPath "$api_key_path"; then
                    log_success "✅ TestFlight upload completed successfully"
                    return 0
                else
                    log_error "❌ TestFlight upload failed"
                    return 1
                fi
            else
                log_error "❌ No IPA files found for upload"
                return 1
            fi
        else
            log_error "❌ Failed to download API key"
            return 1
        fi
    else
        log_warn "⚠️ TestFlight upload skipped (credentials not available or disabled)"
        log_info "📋 TestFlight settings:"
        log_info "   - IS_TESTFLIGHT: ${IS_TESTFLIGHT:-true}"
        log_info "   - APP_STORE_CONNECT_KEY_IDENTIFIER: ${APP_STORE_CONNECT_KEY_IDENTIFIER:-NOT_SET}"
        log_info "   - APP_STORE_CONNECT_ISSUER_ID: ${APP_STORE_CONNECT_ISSUER_ID:-NOT_SET}"
        log_info "   - APP_STORE_CONNECT_API_KEY_URL: ${APP_STORE_CONNECT_API_KEY_URL:-NOT_SET}"
        return 0
    fi
}

# Function to send email notification
send_email() {
    local type="$1"
    local platform="$2"
    local build_id="$3"
    local message="$4"
    
    if [ -f "${UTILS_DIR}/send_email.py" ]; then
        chmod +x "${UTILS_DIR}/send_email.py"
        python3 "${UTILS_DIR}/send_email.py" "$type" "$platform" "$build_id" "$message" || true
    else
        log_warn "⚠️ Email notification script not found"
    fi
}

# Main execution function
main() {
    log_info "🚀 Comprehensive iOS Build Workflow Starting..."
    
    # Validate environment variables
    if ! validate_environment; then
        log_error "❌ Environment validation failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Environment validation failed."
        return 1
    fi
    
    # Fix Swift optimization warnings
    fix_swift_optimization
    
    # Run flutter pub get first to generate required files
    log_info "📦 Running flutter pub get to generate required files..."
    if flutter pub get; then
        log_success "✅ Flutter pub get completed successfully"
    else
        log_error "❌ Flutter pub get failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Flutter pub get failed."
        return 1
    fi
    
    # Fix iOS deployment target
    if ! fix_deployment_target; then
        log_error "❌ iOS deployment target fix failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "iOS deployment target fix failed."
        return 1
    fi
    
    # Inject bundle ID for Runner target
    if ! inject_bundle_id; then
        log_error "❌ Bundle ID injection failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Bundle ID injection failed."
        return 1
    fi
    
    # Build and archive
    if ! build_and_archive; then
        log_error "❌ Build and archive failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Build and archive failed."
        return 1
    fi
    
    # Export IPA
    if ! export_ipa; then
        log_error "❌ IPA export failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "IPA export failed."
        return 1
    fi
    
    # Upload to TestFlight
    if ! upload_to_testflight; then
        log_error "❌ TestFlight upload failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "TestFlight upload failed."
        return 1
    fi
    
    log_success "🎉 Comprehensive iOS Build Workflow completed successfully!"
    send_email "build_success" "iOS" "${CM_BUILD_ID:-unknown}" "Build completed successfully."
    return 0
}

# Execute main function
main "$@" 