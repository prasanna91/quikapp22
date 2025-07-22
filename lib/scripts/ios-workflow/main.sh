#!/bin/bash

# iOS Workflow Main Script (Centralized)
# Purpose: Orchestrate the entire iOS build workflow using centralized approach
# Utility files remain in lib/scripts/utils/ for shared use

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

log_info "🚀 Starting iOS Build Workflow (Centralized)..."

# Function to clean BOM characters from script files
clean_bom_characters() {
    log_info "🧹 Cleaning BOM characters from script files..."
    
    # List of critical script files to check (using centralized paths)
    local script_files=(
        "lib/scripts/ios-workflow/main.sh"
        "lib/scripts/ios-workflow/pre_build_validation.sh"
        "lib/scripts/ios-workflow/export_ipa_framework_fix.sh"
        "lib/scripts/ios-workflow/email_notifications.sh"
        "lib/scripts/ios-workflow/setup_environment.sh"
        "lib/scripts/utils/download_custom_icons.sh"
        "lib/scripts/utils/send_email.py"
    )
    
    for script_file in "${script_files[@]}"; do
        if [ -f "$script_file" ]; then
            log_info "🔍 Checking $script_file for BOM characters..."
            
            # Method 1: Check if file has BOM using file command
            if command -v file >/dev/null 2>&1; then
                if file "$script_file" 2>/dev/null | grep -q "UTF-8 Unicode (with BOM)"; then
                    log_warn "⚠️ BOM detected in $script_file, removing..."
                    # Create a temporary file without BOM
                    if tail -c +4 "$script_file" > "${script_file}.tmp" 2>/dev/null; then
                        mv "${script_file}.tmp" "$script_file"
                        chmod +x "$script_file"
                        log_success "✅ BOM removed from $script_file"
                    else
                        log_error "❌ Failed to remove BOM from $script_file"
                        rm -f "${script_file}.tmp" 2>/dev/null
                    fi
                fi
            fi
            
            # Method 2: Check first line for invalid shebang
            if [ -f "$script_file" ]; then
                local first_line
                first_line=$(head -1 "$script_file" 2>/dev/null | tr -d '\r')
                
                # Check if first line doesn't start with proper shebang
                if [[ "$first_line" != "#!/bin/bash"* ]] && [[ "$first_line" != "#!/bin/sh"* ]] && [[ "$first_line" != "#!/usr/bin/env bash"* ]]; then
                    log_warn "⚠️ Invalid shebang detected in $script_file, attempting to fix..."
                    
                    # Try to find the actual shebang line
                    local shebang_line
                    shebang_line=$(grep -m 1 "^#!" "$script_file" 2>/dev/null)
                    
                    if [ -n "$shebang_line" ]; then
                        # Create a new file starting from the shebang
                        local temp_file="${script_file}.tmp"
                        if grep -A 1000 "^#!" "$script_file" > "$temp_file" 2>/dev/null; then
                            if [ -s "$temp_file" ]; then
                                mv "$temp_file" "$script_file"
                                chmod +x "$script_file"
                                log_success "✅ Fixed shebang in $script_file"
                            else
                                rm -f "$temp_file"
                                log_error "❌ Failed to fix shebang in $script_file - empty result"
                            fi
                        else
                            rm -f "$temp_file"
                            log_error "❌ Failed to extract content from $script_file"
                        fi
                    else
                        log_error "❌ No valid shebang found in $script_file"
                        
                        # Try to create a new file with proper shebang
                        if [ -s "$script_file" ]; then
                            local temp_file="${script_file}.tmp"
                            echo "#!/bin/bash" > "$temp_file"
                            echo "" >> "$temp_file"
                            cat "$script_file" >> "$temp_file" 2>/dev/null
                            if [ -s "$temp_file" ]; then
                                mv "$temp_file" "$script_file"
                                chmod +x "$script_file"
                                log_success "✅ Created new file with proper shebang for $script_file"
                            else
                                rm -f "$temp_file"
                                log_error "❌ Failed to create new file for $script_file"
                            fi
                        fi
                    fi
                else
                    log_success "✅ $script_file has valid shebang"
                fi
            fi
        else
            log_warn "⚠️ Script file not found: $script_file"
        fi
    done
    
    log_success "✅ BOM cleanup completed"
}

# Function to send email notifications using centralized utility
send_email() {
    local email_type="$1"
    local platform="$2"
    local build_id="$3"
    local error_message="$4"
    
    if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
        log_info "📧 Sending $email_type email for $platform build $build_id"
        if [ -f "${UTILS_DIR}/send_email.py" ]; then
            python3 "${UTILS_DIR}/send_email.py" "$email_type" "$platform" "$build_id" "$error_message" || log_warn "⚠️ Failed to send email notification"
        else
            log_warn "⚠️ Email utility not found at ${UTILS_DIR}/send_email.py"
        fi
    fi
}

# Function to load environment variables
load_environment_variables() {
    log_info "📋 Loading environment variables..."
    
    # Validate essential variables
    if [ -z "${BUNDLE_ID:-}" ]; then
        log_error "❌ BUNDLE_ID is not set. Exiting."
        return 1
    fi
    
    # Set default values
    export OUTPUT_DIR="${OUTPUT_DIR:-output/ios}"
    export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
    export CM_BUILD_DIR="${CM_BUILD_DIR:-$(pwd)}"
    export PROFILE_TYPE="${PROFILE_TYPE:-app-store}"
    
    log_success "✅ Environment variables loaded successfully"
    log_info "📱 Bundle ID: ${BUNDLE_ID}"
    log_info "📁 Output Directory: ${OUTPUT_DIR}"
    log_info "🔐 Profile Type: ${PROFILE_TYPE}"
    
    return 0
}

# Function to run pre-build validation
run_pre_build_validation() {
    log_info "🔍 Running pre-build validation..."
    
    if [ -f "${SCRIPT_DIR}/pre_build_validation.sh" ]; then
        chmod +x "${SCRIPT_DIR}/pre_build_validation.sh"
        if "${SCRIPT_DIR}/pre_build_validation.sh"; then
            log_success "✅ Pre-build validation completed successfully"
            return 0
        else
            log_error "❌ Pre-build validation failed"
            return 1
        fi
    else
        log_error "❌ Pre-build validation script not found"
        return 1
    fi
}

# Function to setup environment
setup_environment() {
    log_info "🔧 Setting up build environment..."
    
    if [ -f "${SCRIPT_DIR}/setup_environment.sh" ]; then
        chmod +x "${SCRIPT_DIR}/setup_environment.sh"
        if "${SCRIPT_DIR}/setup_environment.sh"; then
            log_success "✅ Environment setup completed successfully"
            return 0
        else
            log_error "❌ Environment setup failed"
            return 1
        fi
    else
        log_warn "⚠️ Setup environment script not found, using default setup"
        # Create basic directories
        mkdir -p "${OUTPUT_DIR}"
        return 0
    fi
}

# Function to build Flutter app
build_flutter_app() {
    log_info "🏗️ Building Flutter app..."
    
    if [ -f "${SCRIPT_DIR}/build_flutter_app.sh" ]; then
        chmod +x "${SCRIPT_DIR}/build_flutter_app.sh"
        if "${SCRIPT_DIR}/build_flutter_app.sh"; then
            log_success "✅ Flutter app build completed successfully"
            return 0
        else
            log_error "❌ Flutter app build failed"
            return 1
        fi
    else
        log_warn "⚠️ Flutter build script not found, using default build"
        # Default Flutter build
        flutter build ios --release --no-codesign
        return $?
    fi
}

# Function to export IPA
export_ipa() {
    log_info "📦 Exporting IPA..."
    
    # Debug information
    log_info "🔧 Debug information for IPA export:"
    log_info "📁 Archive path: ${OUTPUT_DIR}/Runner.xcarchive"
    log_info "📁 Export path: ${OUTPUT_DIR}"
    log_info "📦 Bundle ID: ${BUNDLE_ID}"
    log_info "👥 Team ID: ${APPLE_TEAM_ID}"
    log_info "📁 Archive exists: $([ -d "${OUTPUT_DIR}/Runner.xcarchive" ] && echo "YES" || echo "NO")"
    log_info "📁 Export dir exists: $([ -d "${OUTPUT_DIR}" ] && echo "YES" || echo "NO")"
    
    if [ -f "${SCRIPT_DIR}/export_ipa_framework_fix.sh" ]; then
        chmod +x "${SCRIPT_DIR}/export_ipa_framework_fix.sh"
        
        # Run export with detailed error handling
        if "${SCRIPT_DIR}/export_ipa_framework_fix.sh" \
            "${OUTPUT_DIR}/Runner.xcarchive" \
            "${OUTPUT_DIR}" \
            "modern-signing-no-cert-required" \
            "00000000-0000-0000-0000-000000000000" \
            "${BUNDLE_ID}" \
            "${APPLE_TEAM_ID}" \
            ""; then
            log_success "✅ IPA export completed successfully"
            return 0
        else
            log_error "❌ IPA export failed"
            log_error "🔧 Export script exit code: $?"
            log_error "🔧 Checking for export artifacts..."
            
            # Check if any IPA files were created
            local ipa_files
            ipa_files=$(find "${OUTPUT_DIR}" -name "*.ipa" -type f 2>/dev/null || true)
            if [ -n "$ipa_files" ]; then
                log_info "📦 Found IPA files: $ipa_files"
            else
                log_error "❌ No IPA files found in ${OUTPUT_DIR}"
            fi
            
            # Check if ExportOptionsModern.plist was created
            if [ -f "ios/ExportOptionsModern.plist" ]; then
                log_info "✅ ExportOptionsModern.plist exists"
            else
                log_error "❌ ExportOptionsModern.plist not found"
            fi
            
            return 1
        fi
    else
        log_error "❌ IPA export script not found at ${SCRIPT_DIR}/export_ipa_framework_fix.sh"
        return 1
    fi
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

# Function to handle errors and provide debugging
handle_errors() {
    log_info "🛡️ Running error handler..."
    
    if [ -f "${SCRIPT_DIR}/error_handler.sh" ]; then
        chmod +x "${SCRIPT_DIR}/error_handler.sh"
        if "${SCRIPT_DIR}/error_handler.sh"; then
            log_success "✅ Error handler completed successfully"
            return 0
        else
            log_warn "⚠️ Error handler failed (continuing...)"
            return 0
        fi
    else
        log_warn "⚠️ Error handler script not found (continuing...)"
        return 0
    fi
}

# Function to process artifacts
process_artifacts() {
    log_info "📋 Processing build artifacts..."
    
    if [ -f "${UTILS_DIR}/process_artifacts.sh" ]; then
        chmod +x "${UTILS_DIR}/process_artifacts.sh"
        if "${UTILS_DIR}/process_artifacts.sh"; then
            log_success "✅ Artifact processing completed successfully"
            return 0
        else
            log_warn "⚠️ Artifact processing failed"
            return 1
        fi
    else
        log_warn "⚠️ Artifact processing script not found"
        return 0
    fi
}

# Main execution function
main() {
    log_info "🚀 iOS Build Workflow Starting (Centralized)..."
    
    # Clean BOM characters before proceeding
    log_info "🧹 Starting BOM cleanup process..."
    if clean_bom_characters; then
        log_success "✅ BOM cleanup completed successfully"
    else
        log_warn "⚠️ BOM cleanup encountered issues, continuing anyway..."
    fi
    
    # Load environment variables
    if ! load_environment_variables; then
        log_error "❌ Environment variable loading failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Environment variable loading failed."
        return 1
    fi
    
    # Run pre-build validation
    if ! run_pre_build_validation; then
        log_error "❌ Pre-build validation failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Pre-build validation failed."
        return 1
    fi
    
    # Setup environment
    if ! setup_environment; then
        log_error "❌ Environment setup failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Environment setup failed."
        return 1
    fi
    
    # Build Flutter app
    if ! build_flutter_app; then
        log_error "❌ Flutter app build failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Flutter app build failed."
        return 1
    fi
    
    # Fix Swift optimization warnings
    fix_swift_optimization
    
    # Handle errors and provide debugging
    handle_errors
    
    # Export IPA
    if ! export_ipa; then
        log_error "❌ IPA export failed"
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "IPA export failed."
        return 1
    fi
    
    # Process artifacts
    if ! process_artifacts; then
        log_warn "⚠️ Artifact processing failed, but build completed"
    fi
    
    log_success "🎉 iOS Build Workflow completed successfully!"
    send_email "build_success" "iOS" "${CM_BUILD_ID:-unknown}" "Build completed successfully."
    return 0
}

# Execute main function
main "$@" 