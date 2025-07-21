#!/bin/bash

# IPA Export with Comprehensive Certificate Validation
# Purpose: Integrate certificate validation with IPA export workflow
# Author: AI Assistant
# Version: 1.0

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🚀 Starting IPA Export with Comprehensive Certificate Validation..."

# Function to validate required environment variables
validate_environment() {
    log_info "🔍 Validating environment variables..."
    
    missing_vars=()
    
    # Check for certificate variables
    if [ -z "${CERT_P12_URL:-}" ] && [ -z "${CERT_CER_URL:-}" ] && [ -z "${CERT_KEY_URL:-}" ]; then
        missing_vars+=("CERT_P12_URL or CERT_CER_URL+CERT_KEY_URL")
    fi
    
    # Check for App Store Connect API variables
    if [ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
        missing_vars+=("APP_STORE_CONNECT_API_KEY_PATH")
    fi
    
    if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]; then
        missing_vars+=("APP_STORE_CONNECT_KEY_IDENTIFIER")
    fi
    
    if [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        missing_vars+=("APP_STORE_CONNECT_ISSUER_ID")
    fi
    
    # Check for provisioning profile
    if [ -z "${PROFILE_URL:-}" ]; then
        missing_vars+=("PROFILE_URL")
    fi
    
    # Check for bundle identifier
    if [ -z "${BUNDLE_ID:-}" ]; then
        missing_vars+=("BUNDLE_ID")
    fi
    
    # Check for profile type
    if [ -z "${PROFILE_TYPE:-}" ]; then
        log_warn "⚠️ PROFILE_TYPE not set, defaulting to app-store"
        export PROFILE_TYPE="app-store"
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "❌ Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "   - $var"
        done
        log_error "❌ Please set all required variables before running this script"
        return 1
    fi
    
    log_success "✅ Environment validation passed"
    return 0
}

# Function to run comprehensive certificate validation
run_certificate_validation() {
    log_info "🔒 Running comprehensive certificate validation..."
    
    if ! "${SCRIPT_DIR}/comprehensive_certificate_validation.sh"; then
        log_error "❌ Certificate validation failed"
        return 1
    fi
    
    log_success "✅ Certificate validation completed successfully"
    return 0
}

# Function to create ExportOptions.plist with UUID
create_export_options_with_uuid() {
    profile_uuid="${MOBILEPROVISION_UUID:-}"
    profile_type="${PROFILE_TYPE:-app-store}"
    bundle_id="${BUNDLE_ID:-}"
    
    log_info "📝 Creating ExportOptions.plist with UUID: $profile_uuid"
    
    # Determine export method based on profile type
    case "$profile_type" in
        "app-store")
            export_method="app-store"
            distribution_type="app_store"
            ;;
        "ad-hoc")
            export_method="ad-hoc"
            distribution_type="ad_hoc"
            ;;
        "enterprise")
            export_method="enterprise"
            distribution_type="enterprise"
            ;;
        "development")
            export_method="development"
            distribution_type="development"
            ;;
        *)
            export_method="app-store"
            distribution_type="app_store"
            log_warn "⚠️ Unknown profile type '$profile_type', defaulting to app-store"
            ;;
    esac
    
    # Create export options directory
    mkdir -p ios/export_options
    
    # Create ExportOptions.plist
    cat > ios/export_options/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>$export_method</string>
    <key>teamID</key>
    <string>\${APPLE_TEAM_ID:-AUTOMATIC}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
EOF
    
    # Add provisioning profile if UUID is available
    if [ -n "$profile_uuid" ]; then
        cat >> ios/export_options/ExportOptions.plist << EOF
    <key>provisioningProfiles</key>
    <dict>
        <key>$bundle_id</key>
        <string>$profile_uuid</string>
    </dict>
EOF
    fi
    
    # Close the plist
    cat >> ios/export_options/ExportOptions.plist << EOF
</dict>
</plist>
EOF
    
    log_success "✅ ExportOptions.plist created successfully"
    log_info "📋 Export Configuration:"
    log_info "   - Method: $export_method"
    log_info "   - Profile Type: $profile_type"
    log_info "   - Bundle ID: $bundle_id"
    if [ -n "$profile_uuid" ]; then
        log_info "   - Provisioning Profile UUID: $profile_uuid"
    fi
}

# Function to build and archive the app
build_and_archive() {
    log_info "🔨 Building and archiving the app..."
    
    # Clean previous builds
    log_info "🧹 Cleaning previous builds..."
    flutter clean
    
    # Get dependencies
    log_info "📦 Getting dependencies..."
    flutter pub get
    
    # Build iOS app
    log_info "🏗️ Building iOS app..."
    flutter build ios --release --no-codesign
    
    # Archive the app
    log_info "📦 Archiving the app..."
    
    archive_path="ios/build/archive.xcarchive"
    project_path="ios/Runner.xcworkspace"
    scheme="Runner"
    
    # Remove existing archive
    rm -rf "$archive_path"
    
    # Create archive
    if xcodebuild -workspace "$project_path" \
                  -scheme "$scheme" \
                  -configuration Release \
                  -archivePath "$archive_path" \
                  -destination "generic/platform=iOS" \
                  archive; then
        log_success "✅ App archived successfully: $archive_path"
        return 0
    else
        log_error "❌ Failed to archive the app"
        return 1
    fi
}

# Function to export IPA from archive
export_ipa_from_archive() {
    log_info "📱 Exporting IPA from archive..."
    
    archive_path="ios/build/archive.xcarchive"
    export_path="ios/build/export"
    export_options="ios/export_options/ExportOptions.plist"
    
    # Remove existing export
    rm -rf "$export_path"
    
    # Export IPA
    if xcodebuild -exportArchive \
                  -archivePath "$archive_path" \
                  -exportPath "$export_path" \
                  -exportOptionsPlist "$export_options"; then
        log_success "✅ IPA exported successfully"
        
        # Find the IPA file
        ipa_file=$(find "$export_path" -name "*.ipa" -type f | head -1)
        
        if [ -n "$ipa_file" ]; then
            log_success "✅ IPA file found: $ipa_file"
            
            # Copy to a standard location
            final_ipa="ios/build/app.ipa"
            cp "$ipa_file" "$final_ipa"
            log_success "✅ IPA copied to: $final_ipa"
            
            # Display file info
            file_size=$(du -h "$final_ipa" | cut -f1)
            log_info "📋 IPA File Information:"
            log_info "   - Path: $final_ipa"
            log_info "   - Size: $file_size"
            
            export IPA_FILE_PATH="$final_ipa"
            return 0
        else
            log_error "❌ No IPA file found in export directory"
            return 1
        fi
    else
        log_error "❌ Failed to export IPA from archive"
        return 1
    fi
}

# Function to upload to App Store Connect (optional)
upload_to_app_store_connect() {
    if [ -z "${APP_STORE_CONNECT_API_KEY_DOWNLOADED_PATH:-}" ]; then
        log_warn "⚠️ App Store Connect API key not available, skipping upload"
        return 0
    fi
    
    if [ -z "${IPA_FILE_PATH:-}" ]; then
        log_warn "⚠️ IPA file not available, skipping upload"
        return 0
    fi
    
    log_info "☁️ Uploading to App Store Connect..."
    
    # Use xcrun altool or transporter for upload
    if command -v xcrun >/dev/null 2>&1; then
        if xcrun altool --upload-app \
                       --type ios \
                       --file "$IPA_FILE_PATH" \
                       --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
                       --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
                       --verbose; then
            log_success "✅ App uploaded to App Store Connect successfully"
            return 0
        else
            log_error "❌ Failed to upload to App Store Connect"
            return 1
        fi
    else
        log_warn "⚠️ xcrun not available, skipping upload"
        return 0
    fi
}

# Main workflow
main() {
    log_info "🚀 Starting IPA Export Workflow with Certificate Validation..."
    
    # Step 1: Validate environment
    if ! validate_environment; then
        exit 1
    fi
    
    # Step 2: Run comprehensive certificate validation
    if ! run_certificate_validation; then
        exit 1
    fi
    
    # Step 3: Create ExportOptions.plist with UUID
    create_export_options_with_uuid
    
    # Step 4: Build and archive the app
    if ! build_and_archive; then
        exit 1
    fi
    
    # Step 5: Export IPA from archive
    if ! export_ipa_from_archive; then
        exit 1
    fi
    
    # Step 6: Upload to App Store Connect (optional)
    upload_to_app_store_connect
    
    log_success "🎉 IPA Export Workflow completed successfully!"
    log_info "📋 Final Summary:"
    log_info "   - Certificate: ✅ Validated and installed"
    log_info "   - Code Signing: ✅ Ready for distribution"
    if [ -n "${MOBILEPROVISION_UUID:-}" ]; then
        log_info "   - Provisioning Profile: ✅ UUID: $MOBILEPROVISION_UUID"
    fi
    if [ -n "${IPA_FILE_PATH:-}" ]; then
        log_info "   - IPA File: ✅ $IPA_FILE_PATH"
    fi
    if [ -n "${APP_STORE_CONNECT_API_KEY_DOWNLOADED_PATH:-}" ]; then
        log_info "   - App Store Connect: ✅ Ready for upload"
    fi
    
    return 0
}

# Run main function
main "$@" 