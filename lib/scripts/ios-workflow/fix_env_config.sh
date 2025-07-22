#!/bin/bash

# Fix Environment Configuration Script
# Purpose: Remove unused BOTTOMMENU_VISIBLE_ON variable and regenerate config files

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

log_info "🔧 Fixing Environment Configuration..."

# Function to regenerate env_config.dart
regenerate_env_config() {
    log_info "📝 Regenerating env_config.dart..."
    
    if [ -f "${UTILS_DIR}/gen_env_config.sh" ]; then
        chmod +x "${UTILS_DIR}/gen_env_config.sh"
        if "${UTILS_DIR}/gen_env_config.sh"; then
            log_success "✅ env_config.dart regenerated successfully"
            return 0
        else
            log_error "❌ Failed to regenerate env_config.dart"
            return 1
        fi
    else
        log_error "❌ gen_env_config.sh not found"
        return 1
    fi
}

# Function to regenerate env.g.dart
regenerate_env_g() {
    log_info "📝 Regenerating env.g.dart..."
    
    if [ -f "${UTILS_DIR}/gen_env_g.sh" ]; then
        chmod +x "${UTILS_DIR}/gen_env_g.sh"
        if "${UTILS_DIR}/gen_env_g.sh"; then
            log_success "✅ env.g.dart regenerated successfully"
            return 0
        else
            log_error "❌ Failed to regenerate env.g.dart"
            return 1
        fi
    else
        log_warn "⚠️ gen_env_g.sh not found, skipping env.g.dart regeneration"
        return 0
    fi
}

# Function to verify the fix
verify_fix() {
    log_info "🔍 Verifying BOTTOMMENU_VISIBLE_ON removal..."
    
    local env_config_file="lib/config/env_config.dart"
    local env_g_file="lib/config/env.g.dart"
    
    # Check if BOTTOMMENU_VISIBLE_ON is still present
    if grep -q "BOTTOMMENU_VISIBLE_ON" "$env_config_file" 2>/dev/null; then
        log_error "❌ BOTTOMMENU_VISIBLE_ON still found in $env_config_file"
        return 1
    else
        log_success "✅ BOTTOMMENU_VISIBLE_ON removed from $env_config_file"
    fi
    
    if grep -q "BOTTOMMENU_VISIBLE_ON" "$env_g_file" 2>/dev/null; then
        log_error "❌ BOTTOMMENU_VISIBLE_ON still found in $env_g_file"
        return 1
    else
        log_success "✅ BOTTOMMENU_VISIBLE_ON removed from $env_g_file"
    fi
    
    return 0
}

# Main execution function
main() {
    log_info "🚀 Fixing Environment Configuration..."
    
    # Regenerate env_config.dart
    if ! regenerate_env_config; then
        log_error "❌ Failed to regenerate env_config.dart"
        return 1
    fi
    
    # Regenerate env.g.dart
    regenerate_env_g
    
    # Verify the fix
    if ! verify_fix; then
        log_error "❌ Environment configuration fix verification failed"
        return 1
    fi
    
    log_success "🎉 Environment configuration fixed successfully"
    log_info "📋 Summary:"
    log_info "   ✅ Removed BOTTOMMENU_VISIBLE_ON from env_config.dart"
    log_info "   ✅ Removed BOTTOMMENU_VISIBLE_ON from env.g.dart"
    log_info "   ✅ Regenerated configuration files"
    log_info "   ✅ Verified fix applied correctly"
    return 0
}

# Execute main function
main "$@" 