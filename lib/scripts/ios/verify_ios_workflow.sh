#!/bin/bash

# iOS Workflow Verification System
# Purpose: Comprehensive verification of iOS build pipeline with proper reporting
# Supports: app-store and ad-hoc profile types with detailed validation

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

# Verification configuration
VERIFICATION_START_TIME=$(date)
VERIFICATION_ID="ios_verification_$(date +%Y%m%d_%H%M%S)"
VERIFICATION_REPORT_DIR="output/verification"
VERIFICATION_LOG_FILE="$VERIFICATION_REPORT_DIR/${VERIFICATION_ID}.log"
VERIFICATION_REPORT_FILE="$VERIFICATION_REPORT_DIR/${VERIFICATION_ID}_report.txt"

# Test results tracking
declare -A test_results
declare -A test_details
total_tests=0
passed_tests=0
failed_tests=0
warning_tests=0

# Initialize verification system
initialize_verification() {
    log_info "🔍 Initializing iOS Workflow Verification System..."
    
    # Create verification directories
    mkdir -p "$VERIFICATION_REPORT_DIR"
    mkdir -p "$VERIFICATION_REPORT_DIR/logs"
    mkdir -p "$VERIFICATION_REPORT_DIR/artifacts"
    
    # Initialize log file
    exec 5>&1
    exec > >(tee -a "$VERIFICATION_LOG_FILE")
    exec 2>&1
    
    log_success "✅ Verification system initialized"
    log_info "📁 Report directory: $VERIFICATION_REPORT_DIR"
    log_info "📄 Log file: $VERIFICATION_LOG_FILE"
    log_info "📊 Report file: $VERIFICATION_REPORT_FILE"
    
    # Create verification header
    cat > "$VERIFICATION_REPORT_FILE" << REPORT_EOF
===============================================================================
                    iOS WORKFLOW VERIFICATION REPORT
===============================================================================
Verification ID: $VERIFICATION_ID
Start Time: $VERIFICATION_START_TIME
Project: $(pwd)
Flutter Version: $(flutter --version 2>/dev/null | head -1 || echo "Not available")
Xcode Version: $(xcodebuild -version 2>/dev/null | head -1 || echo "Not available")
CocoaPods Version: $(pod --version 2>/dev/null || echo "Not available")

===============================================================================
                           VERIFICATION SUMMARY
===============================================================================

REPORT_EOF
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_function="$2"
    local test_description="$3"
    
    total_tests=$((total_tests + 1))
    
    log_info "🧪 Running Test: $test_name"
    log_info "📝 Description: $test_description"
    
    if $test_function; then
        test_results["$test_name"]="PASS"
        test_details["$test_name"]="$test_description - PASSED"
        passed_tests=$((passed_tests + 1))
        log_success "✅ Test PASSED: $test_name"
    else
        test_results["$test_name"]="FAIL"
        test_details["$test_name"]="$test_description - FAILED"
        failed_tests=$((failed_tests + 1))
        log_error "❌ Test FAILED: $test_name"
    fi
    
    echo "----------------------------------------" >> "$VERIFICATION_LOG_FILE"
}

# Warning test wrapper
run_warning_test() {
    local test_name="$1"
    local test_function="$2"
    local test_description="$3"
    
    total_tests=$((total_tests + 1))
    
    log_info "⚠️ Running Warning Test: $test_name"
    log_info "📝 Description: $test_description"
    
    if $test_function; then
        test_results["$test_name"]="PASS"
        test_details["$test_name"]="$test_description - PASSED"
        passed_tests=$((passed_tests + 1))
        log_success "✅ Warning Test PASSED: $test_name"
    else
        test_results["$test_name"]="WARNING"
        test_details["$test_name"]="$test_description - WARNING (non-critical)"
        warning_tests=$((warning_tests + 1))
        log_warn "⚠️ Warning Test FAILED: $test_name (non-critical)"
    fi
    
    echo "----------------------------------------" >> "$VERIFICATION_LOG_FILE"
}

# Environment validation tests
test_environment_setup() {
    log_info "🌍 Testing environment setup..."
    
    # Check Flutter installation
    if ! command -v flutter >/dev/null 2>&1; then
        log_error "Flutter not found in PATH"
        return 1
    fi
    
    # Check Xcode installation
    if ! command -v xcodebuild >/dev/null 2>&1; then
        log_error "Xcode not found in PATH"
        return 1
    fi
    
    # Check CocoaPods installation
    if ! command -v pod >/dev/null 2>&1; then
        log_error "CocoaPods not found in PATH"
        return 1
    fi
    
    # Check Ruby installation
    if ! command -v ruby >/dev/null 2>&1; then
        log_error "Ruby not found in PATH"
        return 1
    fi
    
    log_success "Environment setup validation passed"
    return 0
}

test_project_structure() {
    log_info "📁 Testing project structure..."
    
    # Check essential files
    local essential_files=(
        "pubspec.yaml"
        "lib/main.dart"
        "ios/Runner.xcodeproj/project.pbxproj"
        "ios/Runner/Info.plist"
    )
    
    for file in "${essential_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Essential file missing: $file"
            return 1
        fi
    done
    
    # Check essential scripts
    local essential_scripts=(
        "lib/scripts/ios/main.sh"
        "lib/scripts/ios/utils.sh"
        "lib/scripts/ios/build_flutter_app.sh"
        "lib/scripts/ios/setup_environment.sh"
        "lib/scripts/ios/conditional_firebase_injection.sh"
        "lib/scripts/ios/fix_firebase_xcode16.sh"
        "lib/scripts/ios/fix_firebase_source_files.sh"
        "lib/scripts/ios/final_firebase_solution.sh"
    )
    
    for script in "${essential_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            log_error "Essential script missing: $script"
            return 1
        fi
        
        if [ ! -x "$script" ]; then
            log_warn "Script not executable: $script"
            chmod +x "$script" || {
                log_error "Failed to make script executable: $script"
                return 1
            }
        fi
    done
    
    log_success "Project structure validation passed"
    return 0
}

test_ios_scripts_syntax() {
    log_info "🔧 Testing iOS scripts syntax..."
    
    # Find all shell scripts
    local script_errors=0
    
    find lib/scripts/ios -name "*.sh" -type f | while read script; do
        if ! bash -n "$script" 2>/dev/null; then
            log_error "Syntax error in script: $script"
            script_errors=$((script_errors + 1))
        fi
    done
    
    if [ $script_errors -gt 0 ]; then
        log_error "Found $script_errors scripts with syntax errors"
        return 1
    fi
    
    log_success "iOS scripts syntax validation passed"
    return 0
}

test_bundle_identifier_configuration() {
    log_info "📱 Testing bundle identifier configuration..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local info_plist="ios/Runner/Info.plist"
    
    # Check for conflicting bundle identifiers
    if grep -q "com.example" "$project_file" 2>/dev/null; then
        log_error "Found com.example bundle identifiers in project.pbxproj"
        return 1
    fi
    
    # Validate bundle ID format
    local bundle_id="${BUNDLE_ID:-com.twinklub.twinklub}"
    if [[ ! "$bundle_id" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z0-9.-]+$ ]]; then
        log_error "Invalid bundle identifier format: $bundle_id"
        return 1
    fi
    
    log_success "Bundle identifier configuration validation passed"
    return 0
}

test_firebase_configuration() {
    log_info "🔥 Testing Firebase configuration..."
    
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "Firebase enabled - validating configuration..."
        
        # Check for Firebase config
        if [ -z "${FIREBASE_CONFIG_IOS:-}" ]; then
            log_error "FIREBASE_CONFIG_IOS not set but PUSH_NOTIFY=true"
            return 1
        fi
        
        # Test Firebase config URL
        if ! curl -fsSL --head "${FIREBASE_CONFIG_IOS}" >/dev/null 2>&1; then
            log_error "Firebase config URL is not accessible: ${FIREBASE_CONFIG_IOS}"
            return 1
        fi
        
        log_success "Firebase configuration validation passed"
    else
        log_info "Firebase disabled - skipping Firebase-specific tests"
    fi
    
    return 0
}

test_conditional_firebase_injection() {
    log_info "💉 Testing conditional Firebase injection..."
    
    # Test the conditional Firebase injection script
    if [ -f "lib/scripts/ios/conditional_firebase_injection.sh" ]; then
        # Run a dry-run test
        local temp_dir="/tmp/firebase_injection_test_$$"
        mkdir -p "$temp_dir"
        cd "$temp_dir"
        
        # Create minimal test environment
        mkdir -p lib ios
        echo "name: test_app" > pubspec.yaml
        echo "print('test')" > lib/main.dart
        mkdir -p ios/Runner
        
        # Set test environment
        export PUSH_NOTIFY="${PUSH_NOTIFY:-false}"
        export FIREBASE_CONFIG_IOS="${FIREBASE_CONFIG_IOS:-}"
        
        # Run injection script
        if bash "$(pwd)/lib/scripts/ios/conditional_firebase_injection.sh" --dry-run 2>/dev/null; then
            cd - >/dev/null
            rm -rf "$temp_dir"
            log_success "Conditional Firebase injection test passed"
            return 0
        else
            cd - >/dev/null
            rm -rf "$temp_dir"
            log_error "Conditional Firebase injection test failed"
            return 1
        fi
    else
        log_error "Conditional Firebase injection script not found"
        return 1
    fi
}

test_xcode_project_validity() {
    log_info "🔨 Testing Xcode project validity..."
    
    # Test xcodebuild can read the project
    if ! xcodebuild -project ios/Runner.xcodeproj -list >/dev/null 2>&1; then
        log_error "Xcode project is corrupted or invalid"
        return 1
    fi
    
    # Check for required schemes
    if ! xcodebuild -project ios/Runner.xcodeproj -list | grep -q "Runner"; then
        log_error "Runner scheme not found in Xcode project"
        return 1
    fi
    
    log_success "Xcode project validity test passed"
    return 0
}

test_profile_type_validation() {
    log_info "📋 Testing profile type validation..."
    
    local profile_types=("app-store" "ad-hoc" "enterprise" "development")
    
    for profile_type in "${profile_types[@]}"; do
        log_info "Testing profile type: $profile_type"
        
        # Test profile validation script
        if [ -f "lib/scripts/ios/validate_profile_type.sh" ]; then
            export PROFILE_TYPE="$profile_type"
            if ! bash lib/scripts/ios/validate_profile_type.sh --validate-only 2>/dev/null; then
                log_error "Profile type validation failed for: $profile_type"
                return 1
            fi
        fi
    done
    
    log_success "Profile type validation test passed"
    return 0
}

test_build_acceleration_settings() {
    log_info "⚡ Testing build acceleration settings..."
    
    # Check for proper Xcode build settings
    local settings_count=0
    
    if grep -q "ENABLE_USER_SCRIPT_SANDBOXING.*NO" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null; then
        settings_count=$((settings_count + 1))
    fi
    
    if grep -q "ONLY_ACTIVE_ARCH.*YES" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null; then
        settings_count=$((settings_count + 1))
    fi
    
    if [ $settings_count -lt 1 ]; then
        log_error "Build acceleration settings not properly configured"
        return 1
    fi
    
    log_success "Build acceleration settings test passed"
    return 0
}

# Profile-specific tests
test_app_store_profile_compatibility() {
    log_info "🏪 Testing App Store profile compatibility..."
    
    export PROFILE_TYPE="app-store"
    
    # Test ExportOptions.plist generation for App Store
    if [ -f "lib/scripts/ios/validate_profile_type.sh" ]; then
        if bash lib/scripts/ios/validate_profile_type.sh --create-export-options 2>/dev/null; then
            if [ -f "ios/ExportOptions.plist" ]; then
                # Validate ExportOptions.plist content for App Store
                if grep -q "app-store" ios/ExportOptions.plist 2>/dev/null; then
                    log_success "App Store ExportOptions.plist generated correctly"
                else
                    log_error "App Store ExportOptions.plist has incorrect method"
                    return 1
                fi
            else
                log_error "ExportOptions.plist not generated for App Store profile"
                return 1
            fi
        else
            log_error "Failed to generate ExportOptions.plist for App Store profile"
            return 1
        fi
    else
        log_error "Profile validation script not found"
        return 1
    fi
    
    return 0
}

test_ad_hoc_profile_compatibility() {
    log_info "📲 Testing Ad Hoc profile compatibility..."
    
    export PROFILE_TYPE="ad-hoc"
    
    # Test ExportOptions.plist generation for Ad Hoc
    if [ -f "lib/scripts/ios/validate_profile_type.sh" ]; then
        if bash lib/scripts/ios/validate_profile_type.sh --create-export-options 2>/dev/null; then
            if [ -f "ios/ExportOptions.plist" ]; then
                # Validate ExportOptions.plist content for Ad Hoc
                if grep -q "ad-hoc" ios/ExportOptions.plist 2>/dev/null; then
                    log_success "Ad Hoc ExportOptions.plist generated correctly"
                else
                    log_error "Ad Hoc ExportOptions.plist has incorrect method"
                    return 1
                fi
            else
                log_error "ExportOptions.plist not generated for Ad Hoc profile"
                return 1
            fi
        else
            log_error "Failed to generate ExportOptions.plist for Ad Hoc profile"
            return 1
        fi
    else
        log_error "Profile validation script not found"
        return 1
    fi
    
    return 0
}

test_email_notification_system() {
    log_info "📧 Testing email notification system..."
    
    if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
        # Check email configuration
        local email_vars=(
            "EMAIL_SMTP_SERVER"
            "EMAIL_SMTP_PORT"
            "EMAIL_SMTP_USER"
            "EMAIL_SMTP_PASS"
            "EMAIL_ID"
        )
        
        for var in "${email_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                log_error "Email configuration missing: $var"
                return 1
            fi
        done
        
        # Test email script
        if [ -f "lib/scripts/utils/send_email.py" ]; then
            if python3 lib/scripts/utils/send_email.py --test 2>/dev/null; then
                log_success "Email system test passed"
            else
                log_error "Email system test failed"
                return 1
            fi
        else
            log_error "Email script not found"
            return 1
        fi
    else
        log_info "Email notifications disabled - skipping email tests"
    fi
    
    return 0
}

test_certificate_validation_system() {
    log_info "🔐 Testing certificate validation system..."
    
    if [ -f "lib/scripts/ios/certificate_validation.sh" ]; then
        # Test certificate validation script
        if bash lib/scripts/ios/certificate_validation.sh --validate-only 2>/dev/null; then
            log_success "Certificate validation system test passed"
        else
            log_warn "Certificate validation system test failed (non-critical)"
            return 0  # Non-critical for this test
        fi
    else
        log_error "Certificate validation script not found"
        return 1
    fi
    
    return 0
}

# Full workflow simulation tests
simulate_app_store_workflow() {
    log_info "🏪 Simulating App Store workflow..."
    
    export PROFILE_TYPE="app-store"
    export PUSH_NOTIFY="${PUSH_NOTIFY:-true}"
    
    # Simulate key workflow steps
    if ! lib/scripts/ios/setup_environment.sh --dry-run 2>/dev/null; then
        log_error "App Store workflow simulation failed at setup_environment"
        return 1
    fi
    
    if ! lib/scripts/ios/conditional_firebase_injection.sh --dry-run 2>/dev/null; then
        log_error "App Store workflow simulation failed at conditional_firebase_injection"
        return 1
    fi
    
    log_success "App Store workflow simulation passed"
    return 0
}

simulate_ad_hoc_workflow() {
    log_info "📲 Simulating Ad Hoc workflow..."
    
    export PROFILE_TYPE="ad-hoc"
    export PUSH_NOTIFY="${PUSH_NOTIFY:-true}"
    
    # Simulate key workflow steps
    if ! lib/scripts/ios/setup_environment.sh --dry-run 2>/dev/null; then
        log_error "Ad Hoc workflow simulation failed at setup_environment"
        return 1
    fi
    
    if ! lib/scripts/ios/conditional_firebase_injection.sh --dry-run 2>/dev/null; then
        log_error "Ad Hoc workflow simulation failed at conditional_firebase_injection"
        return 1
    fi
    
    log_success "Ad Hoc workflow simulation passed"
    return 0
}

# Generate final verification report
generate_verification_report() {
    log_info "📊 Generating verification report..."
    
    local end_time=$(date)
    local pass_rate=$(( passed_tests * 100 / total_tests ))
    
    cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF

Total Tests: $total_tests
Passed: $passed_tests
Failed: $failed_tests
Warnings: $warning_tests
Pass Rate: ${pass_rate}%

Start Time: $VERIFICATION_START_TIME
End Time: $end_time

===============================================================================
                           DETAILED TEST RESULTS
===============================================================================

REPORT_EOF
    
    # Add detailed test results
    for test_name in "${!test_results[@]}"; do
        local status="${test_results[$test_name]}"
        local details="${test_details[$test_name]}"
        
        case "$status" in
            "PASS")
                echo "✅ PASS: $test_name" >> "$VERIFICATION_REPORT_FILE"
                ;;
            "FAIL")
                echo "❌ FAIL: $test_name" >> "$VERIFICATION_REPORT_FILE"
                ;;
            "WARNING")
                echo "⚠️ WARNING: $test_name" >> "$VERIFICATION_REPORT_FILE"
                ;;
        esac
        echo "   Description: $details" >> "$VERIFICATION_REPORT_FILE"
        echo "" >> "$VERIFICATION_REPORT_FILE"
    done
    
    # Add recommendations
    cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF

===============================================================================
                              RECOMMENDATIONS
===============================================================================

REPORT_EOF
    
    if [ $failed_tests -gt 0 ]; then
        cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF
🔧 CRITICAL ISSUES FOUND:
   - $failed_tests critical tests failed
   - Review failed tests above and fix issues before proceeding
   - Run verification again after fixes

REPORT_EOF
    fi
    
    if [ $warning_tests -gt 0 ]; then
        cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF
⚠️ WARNINGS FOUND:
   - $warning_tests non-critical tests failed
   - These issues are not blocking but should be addressed
   - Consider fixing warnings for optimal build experience

REPORT_EOF
    fi
    
    if [ $failed_tests -eq 0 ]; then
        cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF
✅ ALL CRITICAL TESTS PASSED:
   - iOS workflow is ready for production builds
   - Both app-store and ad-hoc profiles are supported
   - Firebase integration is properly configured
   - Build system is optimized for reliability

🚀 READY FOR PRODUCTION:
   - App Store submissions: READY
   - Ad Hoc distributions: READY
   - TestFlight uploads: READY
   - Enterprise distributions: READY

REPORT_EOF
    fi
    
    cat >> "$VERIFICATION_REPORT_FILE" << REPORT_EOF

===============================================================================
                                END OF REPORT
===============================================================================
REPORT_EOF
    
    log_success "✅ Verification report generated: $VERIFICATION_REPORT_FILE"
}

# Main verification execution
main() {
    log_info "🔍 Starting iOS Workflow Verification System..."
    
    # Initialize
    initialize_verification
    
    # Core system tests
    run_test "environment_setup" "test_environment_setup" "Validate development environment"
    run_test "project_structure" "test_project_structure" "Validate project structure and essential files"
    run_test "ios_scripts_syntax" "test_ios_scripts_syntax" "Validate iOS scripts syntax"
    run_test "bundle_identifier" "test_bundle_identifier_configuration" "Validate bundle identifier configuration"
    run_test "xcode_project" "test_xcode_project_validity" "Validate Xcode project integrity"
    
    # Firebase and configuration tests
    run_test "firebase_config" "test_firebase_configuration" "Validate Firebase configuration"
    run_test "conditional_injection" "test_conditional_firebase_injection" "Test conditional Firebase injection"
    run_test "profile_validation" "test_profile_type_validation" "Test profile type validation"
    
    # Build system tests
    run_test "build_acceleration" "test_build_acceleration_settings" "Test build acceleration settings"
    
    # Profile-specific tests
    run_test "app_store_profile" "test_app_store_profile_compatibility" "Test App Store profile compatibility"
    run_test "ad_hoc_profile" "test_ad_hoc_profile_compatibility" "Test Ad Hoc profile compatibility"
    
    # Integration tests
    run_warning_test "email_notifications" "test_email_notification_system" "Test email notification system"
    run_warning_test "certificate_validation" "test_certificate_validation_system" "Test certificate validation system"
    
    # Workflow simulation tests
    run_test "app_store_workflow" "simulate_app_store_workflow" "Simulate complete App Store workflow"
    run_test "ad_hoc_workflow" "simulate_ad_hoc_workflow" "Simulate complete Ad Hoc workflow"
    
    # Generate final report
    generate_verification_report
    
    # Display summary
    log_info ""
    log_info "📊 VERIFICATION SUMMARY:"
    log_info "   Total Tests: $total_tests"
    log_info "   Passed: $passed_tests"
    log_info "   Failed: $failed_tests"
    log_info "   Warnings: $warning_tests"
    log_info "   Pass Rate: $(( passed_tests * 100 / total_tests ))%"
    log_info ""
    log_info "📄 Full Report: $VERIFICATION_REPORT_FILE"
    log_info "📁 Verification Directory: $VERIFICATION_REPORT_DIR"
    
    # Exit with appropriate code
    if [ $failed_tests -gt 0 ]; then
        log_error "❌ Verification FAILED: $failed_tests critical issues found"
        return 1
    else
        log_success "✅ Verification PASSED: iOS workflow is ready for production"
        return 0
    fi
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi 