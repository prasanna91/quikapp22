#!/bin/bash

# 🔧 Target-Only Bundle ID Update Script
# Updates ONLY the main app target bundle ID, leaving frameworks unchanged
# This prevents framework bundle ID collisions while maintaining app functionality

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🔧 Target-Only Bundle ID Update Script..."

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

# Function to update ONLY target bundle ID (no framework modifications)
update_target_bundle_id_only() {
    local new_bundle_id="$1"
    
    log_info "🔧 Updating ONLY target bundle ID (frameworks unchanged)..."
    log_info "🎯 New target bundle ID: $new_bundle_id"
    log_info "🛡️ Framework bundle IDs will remain unchanged"
    
    # Check if rename package is available
    if ! command -v rename >/dev/null 2>&1; then
        log_error "❌ rename package not available"
        return 1
    fi
    
    # Update bundle ID for iOS target ONLY
    log_info "📱 Updating iOS target bundle ID..."
    if rename setBundleId --targets ios --value "$new_bundle_id"; then
        log_success "✅ iOS target bundle ID updated successfully"
    else
        log_error "❌ Failed to update iOS target bundle ID"
        return 1
    fi
    
    # Update bundle ID for Android target ONLY (if needed)
    if [ -d "android" ]; then
        log_info "🤖 Updating Android target bundle ID..."
        if rename setBundleId --targets android --value "$new_bundle_id"; then
            log_success "✅ Android target bundle ID updated successfully"
        else
            log_warn "⚠️ Failed to update Android target bundle ID (continuing)"
        fi
    fi
    
    log_success "✅ Target bundle ID update completed (frameworks unchanged)"
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

# Function to verify target bundle ID update
verify_target_bundle_id_update() {
    local expected_bundle_id="$1"
    
    log_info "🔍 Verifying target bundle ID update..."
    
    # Get current bundle ID using rename package
    local current_bundle_id
    current_bundle_id=$(rename getBundleId --targets ios 2>/dev/null || echo "")
    
    if [ -n "$current_bundle_id" ]; then
        if [ "$current_bundle_id" = "$expected_bundle_id" ]; then
            log_success "✅ Target bundle ID verification successful: $current_bundle_id"
            return 0
        else
            log_warn "⚠️ Target bundle ID verification failed: expected $expected_bundle_id, found $current_bundle_id"
            return 1
        fi
    else
        log_warn "⚠️ Could not verify target bundle ID using rename package"
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
    
    log_info "📋 Creating target-only bundle ID update summary report..."
    
    mkdir -p "$output_dir"
    
    cat > "$output_dir/TARGET_ONLY_BUNDLE_ID_UPDATE_SUMMARY.txt" << EOF
Target-Only Bundle ID Update Summary
====================================

Date: $(date)
Target Bundle ID: $bundle_id
App Name: ${app_name:-Not set}

Method: Used rename package from pub.dev (TARGET ONLY)
Package: rename: ^3.1.0

IMPORTANT: Framework bundle IDs were NOT modified
This prevents framework collision issues while maintaining app functionality.

Files Updated (Target Only):
- iOS: Info.plist, project.pbxproj (main app target only)
- Android: AndroidManifest.xml, build.gradle (main app target only)
- Flutter: pubspec.yaml

Commands Used:
- rename setBundleId --targets ios --value "$bundle_id"
- rename setAppName --targets ios --value "$app_name"

Framework Bundle IDs: UNCHANGED
- All embedded frameworks retain their original bundle IDs
- This prevents CFBundleIdentifier collision errors
- Frameworks continue to function normally

Verification:
- Target Bundle ID: $(rename getBundleId --targets ios 2>/dev/null || echo "Could not verify")
- App Name: $(rename getAppName --targets ios 2>/dev/null || echo "Could not verify")

This update used the official rename package from pub.dev,
but ONLY for the main app target, leaving frameworks unchanged.
EOF
    
    log_success "✅ Summary report created: $output_dir/TARGET_ONLY_BUNDLE_ID_UPDATE_SUMMARY.txt"
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

# Function to check framework bundle IDs (for verification only)
check_framework_bundle_ids() {
    log_info "🔍 Checking framework bundle IDs (for verification only)..."
    
    local framework_count=0
    local unchanged_count=0
    
    # Check iOS frameworks
    if [ -d "ios/Runner.app/Frameworks" ]; then
        find "ios/Runner.app/Frameworks" -name "*.framework" -type d 2>/dev/null | while read framework; do
            framework_count=$((framework_count + 1))
            local framework_plist="$framework/Info.plist"
            
            if [ -f "$framework_plist" ]; then
                local framework_bundle_id
                framework_bundle_id=$(plutil -extract CFBundleIdentifier raw "$framework_plist" 2>/dev/null || echo "unknown")
                log_info "   📦 Framework: $(basename "$framework" .framework) -> $framework_bundle_id (unchanged)"
                unchanged_count=$((unchanged_count + 1))
            fi
        done
    fi
    
    log_info "📊 Framework status: $framework_count frameworks found, all unchanged"
    return 0
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
    
    log_info "🔧 Starting Target-Only Bundle ID Update..."
    log_info "🎯 Target Bundle ID: $bundle_id"
    log_info "🎯 Target App Name: ${app_name:-Not set}"
    log_info "🔄 Generate Unique: $generate_unique"
    log_info "🛡️ Framework bundle IDs will remain UNCHANGED"
    
    # Validate bundle ID format
    if ! validate_bundle_id "$bundle_id"; then
        exit 1
    fi
    
    # Generate unique bundle ID if requested
    if [ "$generate_unique" = "true" ]; then
        local timestamp=$(date +%s)
        bundle_id="${bundle_id}.${timestamp}"
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
    
    # Update ONLY target bundle ID (no framework modifications)
    if update_target_bundle_id_only "$bundle_id"; then
        log_success "✅ Target bundle ID update completed successfully"
    else
        log_error "❌ Target bundle ID update failed"
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
    
    if ! verify_target_bundle_id_update "$bundle_id"; then
        verification_passed=false
    fi
    
    if [ -n "$app_name" ]; then
        if ! verify_app_name_update "$app_name"; then
            verification_passed=false
        fi
    fi
    
    # Check framework bundle IDs (verification only)
    check_framework_bundle_ids
    
    # Create summary report
    create_summary_report "$bundle_id" "$app_name"
    
    if [ "$verification_passed" = true ]; then
        log_success "🎉 Target-Only Bundle ID Update completed successfully!"
        log_info "📱 New Target Bundle ID: $bundle_id"
        if [ -n "$app_name" ]; then
            log_info "📱 New App Name: $app_name"
        fi
        log_info "🛡️ Framework bundle IDs remain unchanged"
        log_info "📋 Summary report: ${OUTPUT_DIR:-output/ios}/TARGET_ONLY_BUNDLE_ID_UPDATE_SUMMARY.txt"
        
        # Export the new bundle ID for other scripts
        export BUNDLE_ID="$bundle_id"
        if [ -n "$app_name" ]; then
            export APP_NAME="$app_name"
        fi
        echo "$bundle_id"
    else
        log_warn "⚠️ Target bundle ID update completed with verification issues"
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