#!/bin/bash

# 🔍 Environment Variable Injection Verification Script
# Purpose: Verify that environment variables passed by Codemagic are properly used
# Target: Ensure no variable injection issues

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

log_info "🔍 Starting Environment Variable Injection Verification..."

# Function to check environment variables
check_environment_variables() {
    log_info "🔍 Checking environment variables..."
    
    # Critical variables that should be passed by Codemagic
    local critical_vars=(
        "APP_NAME"
        "VERSION_NAME" 
        "VERSION_CODE"
        "BUNDLE_ID"
        "APPLE_TEAM_ID"
        "WORKFLOW_ID"
    )
    
    local missing_vars=()
    local correct_vars=()
    
    for var in "${critical_vars[@]}"; do
        local value="${!var:-}"
        if [ -z "$value" ]; then
            missing_vars+=("$var")
        else
            correct_vars+=("$var=$value")
        fi
    done
    
    # Report results
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_warning "⚠️ Missing environment variables: ${missing_vars[*]}"
    else
        log_success "✅ All critical environment variables are set"
    fi
    
    log_info "📋 Environment variables found:"
    for var in "${correct_vars[@]}"; do
        log_info "   $var"
    done
}

# Function to test gen_env_config.sh
test_env_config_generation() {
    log_info "🔧 Testing environment configuration generation..."
    
    local gen_script="${UTILS_DIR}/gen_env_config.sh"
    
    if [ -f "$gen_script" ]; then
        chmod +x "$gen_script"
        
        # Run the script and capture output
        local output
        output=$("$gen_script" 2>&1)
        
        # Check if the generated file has the correct values
        if [ -f "lib/config/env_config.dart" ]; then
            log_success "✅ env_config.dart generated successfully"
            
            # Check specific values
            if grep -q "static const String appName = \"${APP_NAME:-}\"" "lib/config/env_config.dart"; then
                log_success "✅ APP_NAME correctly injected: ${APP_NAME:-}"
            else
                log_warning "⚠️ APP_NAME not correctly injected"
            fi
            
            if grep -q "static const String versionName = \"${VERSION_NAME:-}\"" "lib/config/env_config.dart"; then
                log_success "✅ VERSION_NAME correctly injected: ${VERSION_NAME:-}"
            else
                log_warning "⚠️ VERSION_NAME not correctly injected"
            fi
            
            if grep -q "static const String bundleId = \"${BUNDLE_ID:-}\"" "lib/config/env_config.dart"; then
                log_success "✅ BUNDLE_ID correctly injected: ${BUNDLE_ID:-}"
            else
                log_warning "⚠️ BUNDLE_ID not correctly injected"
            fi
        else
            log_error "❌ env_config.dart not generated"
            return 1
        fi
    else
        log_error "❌ gen_env_config.sh not found"
        return 1
    fi
}

# Function to compare expected vs actual values
compare_values() {
    log_info "🔍 Comparing expected vs actual values..."
    
    # Expected values from Codemagic
    local expected_app_name="${APP_NAME:-}"
    local expected_version_name="${VERSION_NAME:-}"
    local expected_version_code="${VERSION_CODE:-}"
    local expected_bundle_id="${BUNDLE_ID:-}"
    
    # Read actual values from generated file
    local actual_app_name
    local actual_version_name
    local actual_version_code
    local actual_bundle_id
    
    if [ -f "lib/config/env_config.dart" ]; then
        # Extract clean values without log messages
        actual_app_name=$(grep "static const String appName = " "lib/config/env_config.dart" | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        actual_version_name=$(grep "static const String versionName = " "lib/config/env_config.dart" | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        actual_version_code=$(grep "static const int versionCode = " "lib/config/env_config.dart" | sed 's/.*= \([0-9]*\).*/\1/' | head -1)
        actual_bundle_id=$(grep "static const String bundleId = " "lib/config/env_config.dart" | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        
        # Clean up any remaining log messages
        actual_app_name=$(echo "$actual_app_name" | sed 's/\[.*\] //g' | sed 's/✅ Found API variable APP_NAME: //g')
        actual_version_name=$(echo "$actual_version_name" | sed 's/\[.*\] //g' | sed 's/✅ Found API variable VERSION_NAME: //g')
        actual_version_code=$(echo "$actual_version_code" | sed 's/\[.*\] //g' | sed 's/✅ Found API variable VERSION_CODE: //g')
        actual_bundle_id=$(echo "$actual_bundle_id" | sed 's/\[.*\] //g' | sed 's/✅ Found API variable BUNDLE_ID: //g')
        
        # Compare values
        log_info "📋 Value Comparison:"
        log_info "   APP_NAME: Expected='$expected_app_name', Actual='$actual_app_name'"
        log_info "   VERSION_NAME: Expected='$expected_version_name', Actual='$actual_version_name'"
        log_info "   VERSION_CODE: Expected='$expected_version_code', Actual='$actual_version_code'"
        log_info "   BUNDLE_ID: Expected='$expected_bundle_id', Actual='$actual_bundle_id'"
        
        # Check for mismatches
        local mismatches=0
        if [ "$expected_app_name" != "$actual_app_name" ]; then
            log_warning "⚠️ APP_NAME mismatch"
            mismatches=$((mismatches + 1))
        fi
        
        if [ "$expected_version_name" != "$actual_version_name" ]; then
            log_warning "⚠️ VERSION_NAME mismatch"
            mismatches=$((mismatches + 1))
        fi
        
        if [ "$expected_version_code" != "$actual_version_code" ]; then
            log_warning "⚠️ VERSION_CODE mismatch"
            mismatches=$((mismatches + 1))
        fi
        
        if [ "$expected_bundle_id" != "$actual_bundle_id" ]; then
            log_warning "⚠️ BUNDLE_ID mismatch"
            mismatches=$((mismatches + 1))
        fi
        
        if [ $mismatches -eq 0 ]; then
            log_success "✅ All values match correctly"
        else
            log_error "❌ Found $mismatches mismatches"
            return 1
        fi
    else
        log_error "❌ env_config.dart not found for comparison"
        return 1
    fi
}

# Main execution function
main() {
    log_info "🚀 Starting Environment Variable Injection Verification..."
    
    # Check environment variables
    check_environment_variables
    
    # Test environment configuration generation
    test_env_config_generation
    
    # Compare expected vs actual values
    compare_values
    
    log_success "🎉 Environment variable injection verification completed"
    log_info "📋 Summary:"
    log_info "   ✅ Environment variables checked"
    log_info "   ✅ Configuration generation tested"
    log_info "   ✅ Value comparison completed"
}

# Run main function
main "$@" 