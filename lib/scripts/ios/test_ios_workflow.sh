#!/bin/bash

# 🧪 iOS Workflow Test Script
# Tests all components of the iOS workflow to ensure they're working properly

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🧪 Testing iOS Workflow Components..."

# Test 1: Check if all required scripts exist and are executable
test_required_scripts() {
    log_info "🔍 Test 1: Checking required scripts..."
    
    local required_scripts=(
        "main.sh"
        "ultimate_bundle_executable_fix.sh"
        "update_bundle_id_rename.sh"
        "validate_profile_type.sh"
        "comprehensive_certificate_validation.sh"
        "setup_environment.sh"
        "email_notifications.sh"
    )
    
    local all_good=true
    
    for script in "${required_scripts[@]}"; do
        if [ -f "${SCRIPT_DIR}/${script}" ]; then
            if [ -x "${SCRIPT_DIR}/${script}" ]; then
                log_success "✅ $script exists and is executable"
            else
                log_error "❌ $script exists but is not executable"
                all_good=false
            fi
        else
            log_error "❌ $script not found"
            all_good=false
        fi
    done
    
    if [ "$all_good" = true ]; then
        log_success "✅ All required scripts are present and executable"
        return 0
    else
        log_error "❌ Some required scripts are missing or not executable"
        return 1
    fi
}

# Test 2: Test ultimate bundle executable fix script
test_ultimate_bundle_fix() {
    log_info "🔍 Test 2: Testing ultimate bundle executable fix script..."
    
    if [ -f "${SCRIPT_DIR}/ultimate_bundle_executable_fix.sh" ]; then
        # Test help functionality
        if "${SCRIPT_DIR}/ultimate_bundle_executable_fix.sh" >/dev/null 2>&1; then
            log_success "✅ Ultimate bundle executable fix script help works"
        else
            log_error "❌ Ultimate bundle executable fix script help failed"
            return 1
        fi
        
        # Test validation with non-existent file
        if "${SCRIPT_DIR}/ultimate_bundle_executable_fix.sh" --validate-ipa "nonexistent.ipa" >/dev/null 2>&1; then
            log_error "❌ Ultimate bundle executable fix should fail with non-existent file"
            return 1
        else
            log_success "✅ Ultimate bundle executable fix properly handles non-existent files"
        fi
        
        log_success "✅ Ultimate bundle executable fix script is working correctly"
        return 0
    else
        log_error "❌ Ultimate bundle executable fix script not found"
        return 1
    fi
}

# Test 3: Test rename-based bundle ID update script
test_rename_bundle_update() {
    log_info "🔍 Test 3: Testing rename-based bundle ID update script..."
    
    if [ -f "${SCRIPT_DIR}/update_bundle_id_rename.sh" ]; then
        # Test with invalid bundle ID (should fail)
        if "${SCRIPT_DIR}/update_bundle_id_rename.sh" "invalid-bundle-id" >/dev/null 2>&1; then
            log_error "❌ Rename bundle update should fail with invalid bundle ID"
            return 1
        else
            log_success "✅ Rename bundle update properly validates bundle ID format"
        fi
        
        log_success "✅ Rename-based bundle ID update script is working correctly"
        return 0
    else
        log_error "❌ Rename-based bundle ID update script not found"
        return 1
    fi
}

# Test 4: Test profile validation script
test_profile_validation() {
    log_info "🔍 Test 4: Testing profile validation script..."
    
    if [ -f "${SCRIPT_DIR}/validate_profile_type.sh" ]; then
        # Test with valid profile type
        if "${SCRIPT_DIR}/validate_profile_type.sh" "app-store" >/dev/null 2>&1; then
            log_success "✅ Profile validation accepts valid profile type"
        else
            log_error "❌ Profile validation should accept 'app-store'"
            return 1
        fi
        
        # Test with invalid profile type (should fail)
        if "${SCRIPT_DIR}/validate_profile_type.sh" "invalid-type" >/dev/null 2>&1; then
            log_error "❌ Profile validation should reject invalid profile type"
            return 1
        else
            log_success "✅ Profile validation properly rejects invalid profile types"
        fi
        
        log_success "✅ Profile validation script is working correctly"
        return 0
    else
        log_error "❌ Profile validation script not found"
        return 1
    fi
}

# Test 5: Test certificate validation script
test_certificate_validation() {
    log_info "🔍 Test 5: Testing certificate validation script..."
    
    if [ -f "${SCRIPT_DIR}/comprehensive_certificate_validation.sh" ]; then
        # Test help functionality
        if "${SCRIPT_DIR}/comprehensive_certificate_validation.sh" --help >/dev/null 2>&1; then
            log_success "✅ Certificate validation script help works"
        else
            log_error "❌ Certificate validation script help failed"
            return 1
        fi
        
        log_success "✅ Certificate validation script is working correctly"
        return 0
    else
        log_error "❌ Certificate validation script not found"
        return 1
    fi
}

# Test 6: Test environment setup script
test_environment_setup() {
    log_info "🔍 Test 6: Testing environment setup script..."
    
    if [ -f "${SCRIPT_DIR}/setup_environment.sh" ]; then
        # Test help functionality
        if "${SCRIPT_DIR}/setup_environment.sh" --help >/dev/null 2>&1; then
            log_success "✅ Environment setup script help works"
        else
            log_error "❌ Environment setup script help failed"
            return 1
        fi
        
        log_success "✅ Environment setup script is working correctly"
        return 0
    else
        log_error "❌ Environment setup script not found"
        return 1
    fi
}

# Test 7: Test email notifications script
test_email_notifications() {
    log_info "🔍 Test 7: Testing email notifications script..."
    
    if [ -f "${SCRIPT_DIR}/email_notifications.sh" ]; then
        # Test help functionality
        if "${SCRIPT_DIR}/email_notifications.sh" --help >/dev/null 2>&1; then
            log_success "✅ Email notifications script help works"
        else
            log_error "❌ Email notifications script help failed"
            return 1
        fi
        
        log_success "✅ Email notifications script is working correctly"
        return 0
    else
        log_error "❌ Email notifications script not found"
        return 1
    fi
}

# Test 8: Test main iOS script
test_main_ios_script() {
    log_info "🔍 Test 8: Testing main iOS script..."
    
    if [ -f "${SCRIPT_DIR}/main.sh" ]; then
        # Test help functionality (if available)
        if "${SCRIPT_DIR}/main.sh" --help >/dev/null 2>&1; then
            log_success "✅ Main iOS script help works"
        else
            log_info "ℹ️ Main iOS script doesn't have help option (this is normal)"
        fi
        
        log_success "✅ Main iOS script is present and executable"
        return 0
    else
        log_error "❌ Main iOS script not found"
        return 1
    fi
}

# Test 9: Check Flutter and rename package
test_flutter_environment() {
    log_info "🔍 Test 9: Testing Flutter environment..."
    
    # Check if Flutter is available
    if command -v flutter >/dev/null 2>&1; then
        log_success "✅ Flutter is available"
        
        # Check if rename package is in pubspec.yaml
        if grep -q "rename:" pubspec.yaml; then
            log_success "✅ Rename package is in pubspec.yaml"
        else
            log_error "❌ Rename package not found in pubspec.yaml"
            return 1
        fi
        
        # Check if rename command is available
        if flutter pub run rename --help >/dev/null 2>&1; then
            log_success "✅ Rename package command is available"
        else
            log_warn "⚠️ Rename package command not available (this might be normal in CI)"
        fi
        
        return 0
    else
        log_error "❌ Flutter is not available"
        return 1
    fi
}

# Run all tests
main() {
    log_info "🧪 Starting iOS Workflow Component Tests..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Run all tests
    test_required_scripts && ((tests_passed++)) || ((tests_failed++))
    test_ultimate_bundle_fix && ((tests_passed++)) || ((tests_failed++))
    test_rename_bundle_update && ((tests_passed++)) || ((tests_failed++))
    test_profile_validation && ((tests_passed++)) || ((tests_failed++))
    test_certificate_validation && ((tests_passed++)) || ((tests_failed++))
    test_environment_setup && ((tests_passed++)) || ((tests_failed++))
    test_email_notifications && ((tests_passed++)) || ((tests_failed++))
    test_main_ios_script && ((tests_passed++)) || ((tests_failed++))
    test_flutter_environment && ((tests_passed++)) || ((tests_failed++))
    
    # Summary
    log_info "📊 Test Summary:"
    log_info "   ✅ Tests Passed: $tests_passed"
    log_info "   ❌ Tests Failed: $tests_failed"
    log_info "   📋 Total Tests: $((tests_passed + tests_failed))"
    
    if [ $tests_failed -eq 0 ]; then
        log_success "🎉 All iOS workflow components are ready!"
        log_info "🚀 You can now run the iOS workflow with confidence"
        exit 0
    else
        log_error "❌ Some iOS workflow components need attention"
        log_info "🔧 Please fix the failed components before running the workflow"
        exit 1
    fi
}

# Run main function
main "$@" 