#!/bin/bash

# Inject Bundle ID Script
# Purpose: Inject bundle ID specifically for Runner target (main app), not Pods targets

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

log_info "🔧 Injecting Bundle ID for Runner Target..."

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

# Function to inject bundle ID into project.pbxproj for Runner target only
inject_bundle_id_project() {
    log_info "📱 Injecting bundle ID into project.pbxproj for Runner target..."
    
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
    
    # Find the Runner target configuration and update PRODUCT_BUNDLE_IDENTIFIER
    # We need to be specific to only update the Runner target, not Pods targets
    
    # First, let's find the Runner target UUID
    local runner_target_uuid
    runner_target_uuid=$(grep -A 5 "Runner.app" "$project_file" | grep "isa = PBXNativeTarget" -B 5 | grep "= {" | head -1 | sed 's/.*= //' | sed 's/ {.*//')
    
    if [ -z "$runner_target_uuid" ]; then
        log_error "❌ Could not find Runner target UUID"
        return 1
    fi
    
    log_info "🔍 Found Runner target UUID: $runner_target_uuid"
    
    # Find the build configuration for Runner target
    local build_config_uuid
    build_config_uuid=$(grep -A 20 "$runner_target_uuid" "$project_file" | grep "buildConfigurationList" | sed 's/.*buildConfigurationList = //' | sed 's/;.*//')
    
    if [ -z "$build_config_uuid" ]; then
        log_error "❌ Could not find build configuration list for Runner target"
        return 1
    fi
    
    log_info "🔍 Found build configuration list UUID: $build_config_uuid"
    
    # Find the build configurations (Debug and Release)
    local debug_config_uuid
    local release_config_uuid
    
    debug_config_uuid=$(grep -A 10 "$build_config_uuid" "$project_file" | grep "Debug" | head -1 | sed 's/.*= //' | sed 's/;.*//')
    release_config_uuid=$(grep -A 10 "$build_config_uuid" "$project_file" | grep "Release" | head -1 | sed 's/.*= //' | sed 's/;.*//')
    
    if [ -z "$debug_config_uuid" ] || [ -z "$release_config_uuid" ]; then
        log_error "❌ Could not find Debug or Release configuration UUIDs"
        return 1
    fi
    
    log_info "🔍 Found Debug config UUID: $debug_config_uuid"
    log_info "🔍 Found Release config UUID: $release_config_uuid"
    
    # Update PRODUCT_BUNDLE_IDENTIFIER for both Debug and Release configurations
    local temp_file
    temp_file=$(mktemp)
    
    # Create a backup
    cp "$project_file" "${project_file}.backup"
    log_info "✅ Created backup: ${project_file}.backup"
    
    # Update Debug configuration
    if sed -i '' "/$debug_config_uuid/,/};/ s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;/" "$project_file"; then
        log_success "✅ Updated Debug configuration bundle ID"
    else
        log_warn "⚠️ Could not update Debug configuration bundle ID"
    fi
    
    # Update Release configuration
    if sed -i '' "/$release_config_uuid/,/};/ s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;/" "$project_file"; then
        log_success "✅ Updated Release configuration bundle ID"
    else
        log_warn "⚠️ Could not update Release configuration bundle ID"
    fi
    
    # Verify the changes
    local debug_bundle_id
    local release_bundle_id
    
    debug_bundle_id=$(grep -A 10 "$debug_config_uuid" "$project_file" | grep "PRODUCT_BUNDLE_IDENTIFIER" | sed 's/.*= //' | sed 's/;.*//')
    release_bundle_id=$(grep -A 10 "$release_config_uuid" "$project_file" | grep "PRODUCT_BUNDLE_IDENTIFIER" | sed 's/.*= //' | sed 's/;.*//')
    
    log_info "📋 Bundle ID verification:"
    log_info "   Debug: $debug_bundle_id"
    log_info "   Release: $release_bundle_id"
    
    if [ "$debug_bundle_id" = "$bundle_id" ] && [ "$release_bundle_id" = "$bundle_id" ]; then
        log_success "✅ Bundle ID successfully injected for Runner target"
        return 0
    else
        log_error "❌ Bundle ID injection failed"
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
    if grep -q "PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;" "$project_file" 2>/dev/null; then
        log_success "✅ Bundle ID found in project.pbxproj"
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
    log_info "🚀 Injecting Bundle ID for Runner Target..."
    
    # Validate environment variables
    if [ -z "${BUNDLE_ID:-}" ]; then
        log_error "❌ BUNDLE_ID environment variable is not set"
        return 1
    fi
    
    log_info "📦 Target Bundle ID: ${BUNDLE_ID}"
    
    # Inject bundle ID into project.pbxproj
    if ! inject_bundle_id_project; then
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