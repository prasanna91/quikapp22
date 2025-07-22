#!/bin/bash

# Simple Bundle ID Injection Script
# Purpose: Inject bundle ID specifically for Runner target using simple sed approach

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

log_info "🔧 Simple Bundle ID Injection for Runner Target..."

# Function to validate bundle ID
validate_bundle_id() {
    local bundle_id="$1"
    
    if [ -z "$bundle_id" ]; then
        log_error "❌ Bundle ID is empty"
        return 1
    fi
    
    # Check if bundle ID follows Apple's format
    if [[ "$bundle_id" =~ ^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*$ ]]; then
        log_success "✅ Bundle ID format is valid: $bundle_id"
        return 0
    else
        log_error "❌ Bundle ID format is invalid: $bundle_id"
        log_error "   Expected format: com.company.appname"
        return 1
    fi
}

# Function to inject bundle ID using simple approach
inject_bundle_id_simple() {
    log_info "📱 Injecting bundle ID using simple approach..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local bundle_id="${BUNDLE_ID}"
    
    if [ ! -f "$project_file" ]; then
        log_error "❌ Project file not found: $project_file"
        return 1
    fi
    
    if ! validate_bundle_id "$bundle_id"; then
        return 1
    fi
    
    log_info "📦 Bundle ID to inject: $bundle_id"
    
    # Create a backup
    cp "$project_file" "${project_file}.backup"
    log_info "✅ Created backup: ${project_file}.backup"
    
    # Simple approach: Update all PRODUCT_BUNDLE_IDENTIFIER entries
    # This will update both Debug and Release configurations
    local updated_count=0
    
    # Update PRODUCT_BUNDLE_IDENTIFIER entries
    if sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;/g" "$project_file"; then
        updated_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;" "$project_file" || echo "0")
        log_success "✅ Updated PRODUCT_BUNDLE_IDENTIFIER entries"
    else
        log_error "❌ Failed to update PRODUCT_BUNDLE_IDENTIFIER"
        return 1
    fi
    
    log_info "📋 Updated $updated_count PRODUCT_BUNDLE_IDENTIFIER entries"
    
    # Verify the changes
    local verification_count
    verification_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;" "$project_file" || echo "0")
    
    if [ "$verification_count" -gt 0 ]; then
        log_success "✅ Bundle ID successfully injected: $verification_count entries found"
        return 0
    else
        log_error "❌ Bundle ID injection failed: no entries found"
        return 1
    fi
}

# Function to update Info.plist bundle identifier
update_info_plist_bundle_id() {
    log_info "📱 Updating Info.plist bundle identifier..."
    
    local info_plist="ios/Runner/Info.plist"
    local bundle_id="${BUNDLE_ID}"
    
    if [ ! -f "$info_plist" ]; then
        log_warn "⚠️ Info.plist not found: $info_plist"
        return 0
    fi
    
    if ! validate_bundle_id "$bundle_id"; then
        return 1
    fi
    
    # Update CFBundleIdentifier in Info.plist
    if plutil -replace CFBundleIdentifier -string "$bundle_id" "$info_plist" 2>/dev/null; then
        log_success "✅ Updated CFBundleIdentifier in Info.plist"
        return 0
    else
        log_warn "⚠️ Could not update CFBundleIdentifier in Info.plist"
        return 0
    fi
}

# Function to verify bundle ID injection
verify_bundle_id() {
    log_info "🔍 Verifying bundle ID injection..."
    
    local bundle_id="${BUNDLE_ID}"
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local info_plist="ios/Runner/Info.plist"
    
    log_info "📋 Bundle ID verification summary:"
    
    # Check project.pbxproj
    local project_count
    project_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;" "$project_file" 2>/dev/null || echo "0")
    
    if [ "$project_count" -gt 0 ]; then
        log_success "✅ Bundle ID found in project.pbxproj: $project_count entries"
    else
        log_error "❌ Bundle ID not found in project.pbxproj"
        return 1
    fi
    
    # Check Info.plist
    if [ -f "$info_plist" ]; then
        local plist_bundle_id
        plist_bundle_id=$(plutil -extract CFBundleIdentifier raw "$info_plist" 2>/dev/null || echo "NOT_FOUND")
        
        if [ "$plist_bundle_id" = "$bundle_id" ]; then
            log_success "✅ Bundle ID matches in Info.plist"
        else
            log_warn "⚠️ Bundle ID mismatch in Info.plist: expected $bundle_id, got $plist_bundle_id"
        fi
    fi
    
    return 0
}

# Main execution function
main() {
    log_info "🚀 Simple Bundle ID Injection for Runner Target..."
    
    # Validate environment variables
    if [ -z "${BUNDLE_ID:-}" ]; then
        log_error "❌ BUNDLE_ID environment variable is not set"
        return 1
    fi
    
    log_info "📦 Target Bundle ID: ${BUNDLE_ID}"
    
    # Inject bundle ID into project.pbxproj
    if ! inject_bundle_id_simple; then
        log_error "❌ Failed to inject bundle ID into project.pbxproj"
        return 1
    fi
    
    # Update Info.plist bundle identifier
    update_info_plist_bundle_id
    
    # Verify the injection
    if ! verify_bundle_id; then
        log_error "❌ Bundle ID injection verification failed"
        return 1
    fi
    
    log_success "🎉 Bundle ID successfully injected for Runner target"
    log_info "📋 Summary:"
    log_info "   ✅ Updated project.pbxproj for Runner target only"
    log_info "   ✅ Updated Info.plist CFBundleIdentifier"
    log_info "   ✅ Verified bundle ID injection"
    log_info "   📦 Bundle ID: ${BUNDLE_ID}"
    return 0
}

# Execute main function
main "$@" 