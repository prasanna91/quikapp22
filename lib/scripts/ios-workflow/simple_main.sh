#!/bin/bash

# Simple iOS Workflow Main Script
# Purpose: Simplified iOS build workflow using only essential, working scripts

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

log_info "🚀 Starting Simple iOS Build Workflow..."

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

# Function to build Flutter app
build_flutter_app() {
    log_info "🏗️ Building Flutter app..."
    
    # Set output directory
    local output_dir="${OUTPUT_DIR:-output/ios}"
    mkdir -p "$output_dir"
    
    # Build Flutter app for iOS
    if flutter build ios \
        --release \
        --no-codesign \
        --build-number="${VERSION_CODE:-1}" \
        --build-name="${VERSION_NAME:-1.0.0}"; then
        
        log_success "✅ Flutter app built successfully"
        return 0
    else
        log_error "❌ Flutter app build failed"
        return 1
    fi
}

# Function to create archive
create_archive() {
    log_info "📦 Creating Xcode archive..."
    
    local output_dir="${OUTPUT_DIR:-output/ios}"
    mkdir -p "$output_dir"
    
    # Create archive using xcodebuild
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

# Function to export IPA using simple approach
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
    
    if [ -f "${SCRIPT_DIR}/simple_export.sh" ]; then
        chmod +x "${SCRIPT_DIR}/simple_export.sh"
        
        if "${SCRIPT_DIR}/simple_export.sh" \
            "$archive_path" \
            "$export_path" \
            "${BUNDLE_ID}" \
            "${APPLE_TEAM_ID}"; then
            
            log_success "✅ IPA export completed successfully"
            return 0
        else
            log_error "❌ IPA export failed"
            return 1
        fi
    else
        log_error "❌ Simple export script not found"
        return 1
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
    log_info "🚀 Simple iOS Build Workflow Starting..."
    
    # Validate environment variables
    if ! validate_environment; then
        log_error "❌ Environment validation failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Environment validation failed."
        return 1
    fi
    
    # Fix Swift optimization warnings
    fix_swift_optimization
    
    # Build Flutter app
    if ! build_flutter_app; then
        log_error "❌ Flutter app build failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Flutter app build failed."
        return 1
    fi
    
    # Create archive
    if ! create_archive; then
        log_error "❌ Archive creation failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Archive creation failed."
        return 1
    fi
    
    # Export IPA
    if ! export_ipa; then
        log_error "❌ IPA export failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "IPA export failed."
        return 1
    fi
    
    log_success "🎉 Simple iOS Build Workflow completed successfully!"
    send_email "build_success" "iOS" "${CM_BUILD_ID:-unknown}" "Build completed successfully."
    return 0
}

# Execute main function
main "$@" 