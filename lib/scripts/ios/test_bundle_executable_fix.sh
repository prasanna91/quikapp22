#!/bin/bash

# 🧪 Test Bundle Executable Fix Script
# Tests the bundle executable fix functionality

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🧪 Testing Bundle Executable Fix Script..."

# Test function to validate bundle executable fix
test_bundle_executable_fix() {
    local test_ipa="$1"
    local bundle_name="${2:-Runner}"
    
    log_info "🧪 Testing bundle executable fix with: $test_ipa"
    
    # Check if test IPA exists
    if [ ! -f "$test_ipa" ]; then
        log_error "❌ Test IPA not found: $test_ipa"
        return 1
    fi
    
    # Create backup
    local backup_ipa="${test_ipa}.test.backup"
    cp "$test_ipa" "$backup_ipa"
    log_info "📋 Created test backup: $backup_ipa"
    
    # Test the fix
    if "${SCRIPT_DIR}/bundle_executable_fix.sh" --handle-app-store-409 "$test_ipa" "$bundle_name"; then
        log_success "✅ Bundle executable fix test PASSED"
        
        # Test validation
        if "${SCRIPT_DIR}/bundle_executable_fix.sh" --validate-only "$bundle_name"; then
            log_success "✅ Bundle executable validation test PASSED"
        else
            log_warn "⚠️ Bundle executable validation test FAILED"
        fi
        
        # Restore backup
        mv "$backup_ipa" "$test_ipa"
        log_info "📋 Restored test IPA from backup"
        
        return 0
    else
        log_error "❌ Bundle executable fix test FAILED"
        
        # Restore backup
        mv "$backup_ipa" "$test_ipa"
        log_info "📋 Restored test IPA from backup"
        
        return 1
    fi
}

# Main test function
main() {
    local test_ipa="${1:-}"
    
    if [ -z "$test_ipa" ]; then
        log_info "🧪 No test IPA provided, looking for IPA files..."
        
        # Find IPA files
        local ipa_files
        ipa_files=$(find . -name "*.ipa" -type f 2>/dev/null | head -1)
        
        if [ -n "$ipa_files" ]; then
            test_ipa="$ipa_files"
            log_info "🧪 Found test IPA: $test_ipa"
        else
            log_error "❌ No IPA files found for testing"
            exit 1
        fi
    fi
    
    # Run the test
    if test_bundle_executable_fix "$test_ipa" "Runner"; then
        log_success "🎉 All bundle executable fix tests PASSED"
        exit 0
    else
        log_error "❌ Bundle executable fix tests FAILED"
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 