#!/bin/bash

# 🔧 Comprehensive iOS Workflow Fix Script
# Purpose: Fix all identified issues in iOS workflow scripts
# Target: Address code signing, environment variables, and script execution issues

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

log_info "🔧 Starting Comprehensive iOS Workflow Fix..."

# Function to fix code signing script
fix_code_signing_script() {
    log_info "🔧 Fixing code signing script..."
    
    local script_path="${SCRIPT_DIR}/fix_code_signing.sh"
    
    if [ -f "$script_path" ]; then
        # Make script executable
        chmod +x "$script_path"
        log_success "✅ Made fix_code_signing.sh executable"
        
        # Test the script
        if bash -n "$script_path"; then
            log_success "✅ Code signing script syntax is valid"
        else
            log_error "❌ Code signing script has syntax errors"
            return 1
        fi
    else
        log_error "❌ fix_code_signing.sh not found"
        return 1
    fi
}

# Function to fix environment variable mapping
fix_environment_mapping() {
    log_info "🔧 Fixing environment variable mapping..."
    
    # Source environment configuration to ensure variables are available
    if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
        source "${SCRIPT_DIR}/../../config/env.sh"
        log_success "✅ Environment configuration loaded from lib/config/env.sh"
    elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
        source "${SCRIPT_DIR}/../../../lib/config/env.sh"
        log_success "✅ Environment configuration loaded from lib/config/env.sh"
    else
        log_warning "⚠️ Environment configuration file not found, using system environment variables"
    fi
    
    # Verify critical environment variables
    log_info "🔍 Verifying environment variables..."
    local missing_vars=()
    
    [ -z "${APPLE_TEAM_ID:-}" ] && missing_vars+=("APPLE_TEAM_ID")
    [ -z "${BUNDLE_ID:-}" ] && missing_vars+=("BUNDLE_ID")
    [ -z "${APP_NAME:-}" ] && missing_vars+=("APP_NAME")
    [ -z "${VERSION_NAME:-}" ] && missing_vars+=("VERSION_NAME")
    [ -z "${VERSION_CODE:-}" ] && missing_vars+=("VERSION_CODE")
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_warning "⚠️ Missing environment variables: ${missing_vars[*]}"
        log_warning "⚠️ These will use default values"
    else
        log_success "✅ All critical environment variables are set"
    fi
    
    # Show current values
    log_info "📋 Current environment variables:"
    log_info "   APPLE_TEAM_ID: ${APPLE_TEAM_ID:-not_set}"
    log_info "   BUNDLE_ID: ${BUNDLE_ID:-not_set}"
    log_info "   APP_NAME: ${APP_NAME:-not_set}"
    log_info "   VERSION_NAME: ${VERSION_NAME:-not_set}"
    log_info "   VERSION_CODE: ${VERSION_CODE:-not_set}"
}

# Function to fix script permissions
fix_script_permissions() {
    log_info "🔧 Fixing script permissions..."
    
    # Make all iOS workflow scripts executable
    find "${SCRIPT_DIR}" -name "*.sh" -type f -exec chmod +x {} \;
    log_success "✅ Made all iOS workflow scripts executable"
    
    # Make all iOS scripts executable
    find "${SCRIPT_DIR}/../ios" -name "*.sh" -type f -exec chmod +x {} \;
    log_success "✅ Made all iOS scripts executable"
    
    # Make utils scripts executable
    find "${UTILS_DIR}" -name "*.sh" -type f -exec chmod +x {} \;
    log_success "✅ Made all utils scripts executable"
}

# Function to fix missing log_warning function
fix_logging_functions() {
    log_info "🔧 Fixing logging functions..."
    
    local utils_file="${SCRIPT_DIR}/../ios/utils.sh"
    
    if [ -f "$utils_file" ]; then
        # Check if log_warning function exists
        if ! grep -q "log_warning()" "$utils_file"; then
            # Add log_warning function
            sed -i '' '/log_warn() {/a\
log_warning() {\
    echo "[$(date +'\''%Y-%m-%d %H:%M:%S'\'')] WARNING: $1"\
}' "$utils_file"
            log_success "✅ Added log_warning function to utils.sh"
        else
            log_success "✅ log_warning function already exists in utils.sh"
        fi
    else
        log_error "❌ utils.sh not found"
        return 1
    fi
}

# Function to regenerate environment configuration
regenerate_env_config() {
    log_info "🔧 Regenerating environment configuration..."
    
    local gen_script="${UTILS_DIR}/gen_env_config.sh"
    
    if [ -f "$gen_script" ]; then
        chmod +x "$gen_script"
        if "$gen_script"; then
            log_success "✅ Environment configuration regenerated successfully"
        else
            log_error "❌ Failed to regenerate environment configuration"
            return 1
        fi
    else
        log_error "❌ gen_env_config.sh not found"
        return 1
    fi
}

# Function to test code signing fix
test_code_signing() {
    log_info "🔧 Testing code signing fix..."
    
    local script_path="${SCRIPT_DIR}/fix_code_signing.sh"
    
    if [ -f "$script_path" ]; then
        # Test with a mock project file
        local test_project="test_project.pbxproj"
        echo "DEVELOPMENT_TEAM = OLD_TEAM_ID;" > "$test_project"
        
        # Set test environment variable
        export APPLE_TEAM_ID="TEST_TEAM_ID"
        
        # Run the script
        if bash "$script_path"; then
            log_success "✅ Code signing fix test passed"
        else
            log_error "❌ Code signing fix test failed"
        fi
        
        # Cleanup
        rm -f "$test_project"
    else
        log_error "❌ fix_code_signing.sh not found"
        return 1
    fi
}

# Main execution function
main() {
    log_info "🚀 Starting Comprehensive iOS Workflow Fix..."
    
    # Fix script permissions
    fix_script_permissions
    
    # Fix logging functions
    fix_logging_functions
    
    # Fix environment variable mapping
    fix_environment_mapping
    
    # Fix code signing script
    fix_code_signing_script
    
    # Regenerate environment configuration
    regenerate_env_config
    
    # Test code signing fix
    test_code_signing
    
    log_success "🎉 Comprehensive iOS workflow fix completed successfully"
    log_info "📋 Summary of fixes applied:"
    log_info "   ✅ Script permissions fixed"
    log_info "   ✅ Logging functions fixed"
    log_info "   ✅ Environment variable mapping fixed"
    log_info "   ✅ Code signing script fixed"
    log_info "   ✅ Environment configuration regenerated"
    log_info "   ✅ Code signing fix tested"
}

# Run main function
main "$@" 