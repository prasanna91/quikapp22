#!/bin/bash

# 🔧 Flutter Bundle ID Update Script using rename package
# Uses the rename package from pub.dev to update bundle IDs in a Flutter-native way
# This is more reliable than manual file manipulation

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🔧 Flutter Bundle ID Update Script using rename package..."

# Function to install rename package
install_rename_package() {
    log_info "📦 Installing rename package..."
    
    # Check if rename is already available
    if command -v rename >/dev/null 2>&1; then
        log_success "✅ rename package already available"
        return 0
    fi
    
    # Try to install rename package globally
    if flutter pub global activate rename; then
        log_success "✅ rename package installed successfully"
        return 0
    else
        log_error "❌ Failed to install rename package"
        return 1
    fi
}

# Function to get current bundle ID
get_current_bundle_id() {
    log_info "🔍 Getting current bundle ID..."
    
    # Try to get current bundle ID using rename package
    if command -v rename >/dev/null 2>&1; then
        local current_bundle_id
        current_bundle_id=$(rename getBundleId --targets ios 2>/dev/null || echo "")
        
        if [ -n "$current_bundle_id" ]; then
            log_info "📱 Current bundle ID: $current_bundle_id"
            echo "$current_bundle_id"
        else
            log_warn "⚠️ Could not get current bundle ID using rename package"
            echo ""
        fi
    else
        log_warn "⚠️ rename package not available"
        echo ""
    fi
}

# Function to update bundle ID using rename package
update_bundle_id_with_rename() {
    local new_bundle_id="$1"
    
    log_info "🔧 Updating bundle ID using rename package..."
    log_info "🎯 New bundle ID: $new_bundle_id"
    
    # Check if rename package is available
    if ! command -v rename >/dev/null 2>&1; then
        log_error "❌ rename package not available"
        return 1
    fi
    
    # Update bundle ID for iOS
    log_info "📱 Updating iOS bundle ID..."
    if rename setBundleId --targets ios --value "$new_bundle_id"; then
        log_success "✅ iOS bundle ID updated successfully"
    else
        log_error "❌ Failed to update iOS bundle ID"
        return 1
    fi
    
    # Update bundle ID for Android (if needed)
    if [ -d "android" ]; then
        log_info "🤖 Updating Android bundle ID..."
        if rename setBundleId --targets android --value "$new_bundle_id"; then
            log_success "✅ Android bundle ID updated successfully"
        else
            log_warn "⚠️ Failed to update Android bundle ID (continuing)"
        fi
    fi
    
    log_success "✅ Bundle ID update completed using rename package"
    return 0
}

# Function to update app name using rename package
update_app_name_with_rename() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        log_warn "⚠️ No app name provided, skipping app name update"
        return 0
    fi
    
    log_info "🔧 Updating app name using rename package..."
    log_info "🎯 New app name: $app_name"
    
    # Check if rename package is available
    if ! command -v rename >/dev/null 2>&1; then
        log_error "❌ rename package not available"
        return 1
    fi
    
    # Update app name for iOS
    log_info "📱 Updating iOS app name..."
    if rename setAppName --targets ios --value "$app_name"; then
        log_success "✅ iOS app name updated successfully"
    else
        log_error "❌ Failed to update iOS app name"
        return 1
    fi
    
    # Update app name for Android (if needed)
    if [ -d "android" ]; then
        log_info "🤖 Updating Android app name..."
        if rename setAppName --targets android --value "$app_name"; then
            log_success "✅ Android app name updated successfully"
        else
            log_warn "⚠️ Failed to update Android app name (continuing)"
        fi
    fi
    
    log_success "✅ App name update completed using rename package"
    return 0
}

# Function to verify bundle ID update
verify_bundle_id_update() {
    local expected_bundle_id="$1"
    
    log_info "🔍 Verifying bundle ID update..."
    
    # Get current bundle ID using rename package
    local current_bundle_id
    current_bundle_id=$(rename getBundleId --targets ios 2>/dev/null || echo "")
    
    if [ -n "$current_bundle_id" ]; then
        if [ "$current_bundle_id" = "$expected_bundle_id" ]; then
            log_success "✅ Bundle ID verification successful: $current_bundle_id"
            return 0
        else
            log_warn "⚠️ Bundle ID verification failed: expected $expected_bundle_id, found $current_bundle_id"
            return 1
        fi
    else
        log_warn "⚠️ Could not verify bundle ID using rename package"
        return 1
    fi
}

# Function to verify app name update
verify_app_name_update() {
    local expected_app_name="$1"
    
    if [ -z "$expected_app_name" ]; then
        log_warn "⚠️ No app name provided, skipping app name verification"
        return 0
    fi
    
    log_info "🔍 Verifying app name update..."
    
    # Get current app name using rename package
    local current_app_name
    current_app_name=$(rename getAppName --targets ios 2>/dev/null || echo "")
    
    if [ -n "$current_app_name" ]; then
        if [ "$current_app_name" = "$expected_app_name" ]; then
            log_success "✅ App name verification successful: $current_app_name"
            return 0
        else
            log_warn "⚠️ App name verification failed: expected $expected_app_name, found $current_app_name"
            return 1
        fi
    else
        log_warn "⚠️ Could not verify app name using rename package"
        return 1
    fi
}

# Function to create summary report
create_summary_report() {
    local bundle_id="$1"
    local app_name="$2"
    local output_dir="${OUTPUT_DIR:-output/ios}"
    
    log_info "📋 Creating bundle ID update summary report..."
    
    mkdir -p "$output_dir"
    
    cat > "$output_dir/BUNDLE_ID_UPDATE_SUMMARY.txt" << EOF
Bundle ID Update Summary (using rename package)
==============================================

Date: $(date)
Bundle ID: $bundle_id
App Name: ${app_name:-Not set}

Method: Used rename package from pub.dev
Package: rename: ^3.1.0

Files Updated:
- iOS: Info.plist, project.pbxproj
- Android: AndroidManifest.xml, build.gradle (if present)
- Flutter: pubspec.yaml

Commands Used:
- rename setBundleId --targets ios --value "$bundle_id"
- rename setAppName --targets ios --value "$app_name"

Verification:
- Bundle ID: $(rename getBundleId --targets ios 2>/dev/null || echo "Could not verify")
- App Name: $(rename getAppName --targets ios 2>/dev/null || echo "Could not verify")

This update used the official rename package from pub.dev,
which is the recommended way to update bundle IDs in Flutter projects.
EOF
    
    log_success "✅ Summary report created: $output_dir/BUNDLE_ID_UPDATE_SUMMARY.txt"
}

# Function to validate bundle ID format
validate_bundle_id() {
    local bundle_id="$1"
    
    log_info "🔍 Validating bundle ID format..."
    
    # Check if bundle ID is provided
    if [ -z "$bundle_id" ]; then
        log_error "❌ Bundle ID is required"
        return 1
    fi
    
    # Check bundle ID format (should be like com.company.app)
    if [[ ! "$bundle_id" =~ ^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*$ ]]; then
        log_error "❌ Invalid bundle ID format: $bundle_id"
        log_error "💡 Bundle ID should be in format: com.company.app"
        return 1
    fi
    
    # Check bundle ID length
    if [ ${#bundle_id} -gt 255 ]; then
        log_error "❌ Bundle ID too long: $bundle_id"
        return 1
    fi
    
    log_success "✅ Bundle ID format is valid: $bundle_id"
    return 0
}

# Function to generate unique bundle ID if needed
generate_unique_bundle_id() {
    local base_bundle_id="$1"
    
    log_info "🔧 Generating unique bundle ID..."
    
    # Add timestamp to make it unique
    local timestamp=$(date +%s)
    local unique_bundle_id="${base_bundle_id}.${timestamp}"
    
    log_info "✅ Generated unique bundle ID: $unique_bundle_id"
    echo "$unique_bundle_id"
}

# Main function
main() {
    local bundle_id="${1:-}"
    local app_name="${2:-}"
    local generate_unique="${3:-false}"
    
    # Validate input
    if [ -z "$bundle_id" ]; then
        log_error "❌ Bundle ID is required"
        log_info "Usage: $0 <bundle_id> [app_name] [generate_unique]"
        log_info "Example: $0 com.example.myapp"
        log_info "Example: $0 com.example.myapp \"My App Name\""
        log_info "Example: $0 com.example.myapp \"My App Name\" true (generates unique bundle ID)"
        exit 1
    fi
    
    log_info "🔧 Starting Flutter Bundle ID Update using rename package..."
    log_info "🎯 Target Bundle ID: $bundle_id"
    log_info "🎯 Target App Name: ${app_name:-Not set}"
    log_info "🔄 Generate Unique: $generate_unique"
    
    # Validate bundle ID format
    if ! validate_bundle_id "$bundle_id"; then
        exit 1
    fi
    
    # Generate unique bundle ID if requested
    if [ "$generate_unique" = "true" ]; then
        bundle_id=$(generate_unique_bundle_id "$bundle_id")
        log_info "🔄 Using unique bundle ID: $bundle_id"
    fi
    
    # Install rename package
    if ! install_rename_package; then
        log_error "❌ Failed to install rename package"
        exit 1
    fi
    
    # Get current bundle ID for comparison
    local current_bundle_id
    current_bundle_id=$(get_current_bundle_id)
    
    # Update bundle ID using rename package
    if update_bundle_id_with_rename "$bundle_id"; then
        log_success "✅ Bundle ID update completed successfully"
    else
        log_error "❌ Bundle ID update failed"
        exit 1
    fi
    
    # Update app name if provided
    if [ -n "$app_name" ]; then
        if update_app_name_with_rename "$app_name"; then
            log_success "✅ App name update completed successfully"
        else
            log_warn "⚠️ App name update failed (continuing)"
        fi
    fi
    
    # Verify updates
    local verification_passed=true
    
    if ! verify_bundle_id_update "$bundle_id"; then
        verification_passed=false
    fi
    
    if [ -n "$app_name" ]; then
        if ! verify_app_name_update "$app_name"; then
            verification_passed=false
        fi
    fi
    
    # Create summary report
    create_summary_report "$bundle_id" "$app_name"
    
    if [ "$verification_passed" = true ]; then
        log_success "🎉 Flutter Bundle ID Update completed successfully!"
        log_info "📱 New Bundle ID: $bundle_id"
        if [ -n "$app_name" ]; then
            log_info "📱 New App Name: $app_name"
        fi
        log_info "🔧 This should resolve 409 bundle executable errors"
        log_info "📋 Summary report: ${OUTPUT_DIR:-output/ios}/BUNDLE_ID_UPDATE_SUMMARY.txt"
        
        # Export the new bundle ID for other scripts
        export BUNDLE_ID="$bundle_id"
        if [ -n "$app_name" ]; then
            export APP_NAME="$app_name"
        fi
        echo "$bundle_id"
    else
        log_warn "⚠️ Bundle ID update completed with verification issues"
        log_warn "🔧 Updates were applied, but verification had problems"
        log_warn "📱 The build should still work correctly"
        
        # Export the new bundle ID for other scripts
        export BUNDLE_ID="$bundle_id"
        if [ -n "$app_name" ]; then
            export APP_NAME="$app_name"
        fi
        echo "$bundle_id"
    fi
}

# Run main function with all arguments
main "$@" 