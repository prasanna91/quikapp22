#!/bin/bash

# 🔍 Codemagic API Variable Injection Test Script
# Purpose: Test and debug dynamic API variable injection
# Target: Ensure API variables are properly received and used

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

log_info "🔍 Starting Codemagic API Variable Injection Test..."

# Function to test API variable injection
test_api_variables() {
    log_info "🔍 Testing Codemagic API variable injection..."
    
    # Critical API variables that should be injected by Codemagic
    local api_vars=(
        "WORKFLOW_ID"
        "APP_NAME"
        "VERSION_NAME" 
        "VERSION_CODE"
        "EMAIL_ID"
        "BUNDLE_ID"
        "APPLE_TEAM_ID"
        "PROFILE_TYPE"
        "PROFILE_URL"
        "IS_TESTFLIGHT"
        "APP_STORE_CONNECT_KEY_IDENTIFIER"
        "APP_STORE_CONNECT_ISSUER_ID"
        "APP_STORE_CONNECT_API_KEY_URL"
        "LOGO_URL"
        "SPLASH_URL"
        "SPLASH_BG_COLOR"
        "SPLASH_TAGLINE"
        "SPLASH_TAGLINE_COLOR"
        "FIREBASE_CONFIG_IOS"
        "ENABLE_EMAIL_NOTIFICATIONS"
        "EMAIL_SMTP_SERVER"
        "EMAIL_SMTP_PORT"
        "EMAIL_SMTP_USER"
        "EMAIL_SMTP_PASS"
        "USER_NAME"
        "APP_ID"
        "ORG_NAME"
        "WEB_URL"
        "PKG_NAME"
        "PUSH_NOTIFY"
        "IS_CHATBOT"
        "IS_DOMAIN_URL"
        "IS_SPLASH"
        "IS_PULLDOWN"
        "IS_BOTTOMMENU"
        "IS_LOAD_IND"
        "IS_CAMERA"
        "IS_LOCATION"
        "IS_MIC"
        "IS_NOTIFICATION"
        "IS_CONTACT"
        "IS_BIOMETRIC"
        "IS_CALENDAR"
        "IS_STORAGE"
        "SPLASH_BG_URL"
        "SPLASH_ANIMATION"
        "SPLASH_DURATION"
        "BOTTOMMENU_ITEMS"
        "BOTTOMMENU_BG_COLOR"
        "BOTTOMMENU_ICON_COLOR"
        "BOTTOMMENU_TEXT_COLOR"
        "BOTTOMMENU_FONT"
        "BOTTOMMENU_FONT_SIZE"
        "BOTTOMMENU_FONT_BOLD"
        "BOTTOMMENU_FONT_ITALIC"
        "BOTTOMMENU_ACTIVE_TAB_COLOR"
        "BOTTOMMENU_ICON_POSITION"
        "FIREBASE_CONFIG_ANDROID"
        "APNS_KEY_ID"
        "APNS_AUTH_KEY_URL"
        "KEY_STORE_URL"
        "CM_KEYSTORE_PASSWORD"
        "CM_KEY_ALIAS"
        "CM_KEY_PASSWORD"
    )
    
    local found_vars=()
    local missing_vars=()
    local api_values=()
    
    for var in "${api_vars[@]}"; do
        local value="${!var:-}"
        if [ -n "$value" ]; then
            found_vars+=("$var")
            api_values+=("$var=$value")
            log_info "✅ Found API variable: $var = $value"
        else
            missing_vars+=("$var")
            log_warning "⚠️ Missing API variable: $var"
        fi
    done
    
    # Report results
    log_info "📊 API Variable Injection Results:"
    log_info "   Found: ${#found_vars[@]} variables"
    log_info "   Missing: ${#missing_vars[@]} variables"
    
    if [ ${#found_vars[@]} -gt 0 ]; then
        log_success "✅ API variables found: ${found_vars[*]}"
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_warning "⚠️ Missing API variables: ${missing_vars[*]}"
    fi
    
    # Show all found values
    if [ ${#api_values[@]} -gt 0 ]; then
        log_info "📋 API Variable Values:"
        for value in "${api_values[@]}"; do
            log_info "   $value"
        done
    fi
}

# Function to test environment variable resolution
test_env_resolution() {
    log_info "🔍 Testing environment variable resolution..."
    
    # Test if we're in Codemagic environment
    if [ -n "${CM_BUILD_ID:-}" ]; then
        log_success "✅ Running in Codemagic environment"
        log_info "   Build ID: ${CM_BUILD_ID}"
        log_info "   Project ID: ${CM_PROJECT_ID:-unknown}"
        log_info "   Workflow: ${CM_WORKFLOW_NAME:-unknown}"
    else
        log_warning "⚠️ Not running in Codemagic environment"
    fi
    
    # Test Codemagic-specific variables
    local cm_vars=(
        "CM_BUILD_ID"
        "CM_PROJECT_ID"
        "CM_WORKFLOW_NAME"
        "FCI_BUILD_ID"
        "FCI_PROJECT_ID"
        "FCI_WORKFLOW_NAME"
    )
    
    log_info "📋 Codemagic Environment Variables:"
    for var in "${cm_vars[@]}"; do
        local value="${!var:-}"
        if [ -n "$value" ]; then
            log_info "   $var: $value"
        else
            log_info "   $var: NOT_SET"
        fi
    done
}

# Function to test variable precedence
test_variable_precedence() {
    log_info "🔍 Testing variable precedence..."
    
    # Test if API variables override defaults
    local test_vars=(
        "APP_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "BUNDLE_ID"
    )
    
    log_info "📋 Variable Precedence Test:"
    for var in "${test_vars[@]}"; do
        local api_value="${!var:-}"
        local default_value=""
        
        # Get default value from env.sh if it exists
        if [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
            # Source env.sh temporarily to get default
            source "${SCRIPT_DIR}/../../lib/config/env.sh" 2>/dev/null || true
            default_value="${!var:-}"
        fi
        
        if [ -n "$api_value" ]; then
            log_success "✅ $var: API value '$api_value' (takes precedence)"
        elif [ -n "$default_value" ]; then
            log_warning "⚠️ $var: Using default '$default_value' (no API value)"
        else
            log_error "❌ $var: No value available"
        fi
    done
}

# Function to simulate API variable injection
simulate_api_injection() {
    log_info "🔍 Simulating API variable injection..."
    
    # Create a test environment with API variables
    export TEST_APP_NAME="Test App from API"
    export TEST_VERSION_NAME="2.0.0"
    export TEST_VERSION_CODE="2"
    export TEST_BUNDLE_ID="com.test.api"
    
    log_info "📋 Simulated API Variables:"
    log_info "   TEST_APP_NAME: $TEST_APP_NAME"
    log_info "   TEST_VERSION_NAME: $TEST_VERSION_NAME"
    log_info "   TEST_VERSION_CODE: $TEST_VERSION_CODE"
    log_info "   TEST_BUNDLE_ID: $TEST_BUNDLE_ID"
    
    # Test the get_api_var function
    if [ -f "${UTILS_DIR}/gen_env_config.sh" ]; then
        log_info "🔧 Testing gen_env_config.sh with simulated API variables..."
        
        # Source the script to test the function
        source "${UTILS_DIR}/gen_env_config.sh" 2>/dev/null || true
        
        log_info "📋 Results after API variable injection:"
        log_info "   APP_NAME: ${APP_NAME:-NOT_SET}"
        log_info "   VERSION_NAME: ${VERSION_NAME:-NOT_SET}"
        log_info "   VERSION_CODE: ${VERSION_CODE:-NOT_SET}"
        log_info "   BUNDLE_ID: ${BUNDLE_ID:-NOT_SET}"
    else
        log_error "❌ gen_env_config.sh not found"
    fi
}

# Function to generate API variable report
generate_api_report() {
    log_info "📊 Generating API variable report..."
    
    cat > api_variable_report.txt <<EOF
Codemagic API Variable Injection Report
=======================================

Generated: $(date)
Environment: ${CM_BUILD_ID:-local}

API Variables Status:
$(for var in APP_NAME VERSION_NAME VERSION_CODE BUNDLE_ID APPLE_TEAM_ID WORKFLOW_ID APP_ID ORG_NAME WEB_URL EMAIL_ID USER_NAME PKG_NAME; do
    value="${!var:-}"
    if [ -n "$value" ]; then
        echo "- $var: $value (✅ SET)"
    else
        echo "- $var: NOT_SET (❌ MISSING)"
    fi
done)

Codemagic Environment:
- CM_BUILD_ID: ${CM_BUILD_ID:-NOT_SET}
- CM_PROJECT_ID: ${CM_PROJECT_ID:-NOT_SET}
- CM_WORKFLOW_NAME: ${CM_WORKFLOW_NAME:-NOT_SET}
- FCI_BUILD_ID: ${FCI_BUILD_ID:-NOT_SET}
- FCI_PROJECT_ID: ${FCI_PROJECT_ID:-NOT_SET}
- FCI_WORKFLOW_NAME: ${FCI_WORKFLOW_NAME:-NOT_SET}

Variable Precedence Test:
$(for var in APP_NAME VERSION_NAME VERSION_CODE BUNDLE_ID; do
    api_value="${!var:-}"
    if [ -n "$api_value" ]; then
        echo "- $var: API value '$api_value' (✅ PRIORITY)"
    else
        echo "- $var: No API value (⚠️ USING DEFAULT)"
    fi
done)

EOF

    log_success "✅ API variable report generated: api_variable_report.txt"
}

# Main execution function
main() {
    log_info "🚀 Starting Codemagic API Variable Injection Test..."
    
    # Test API variable injection
    test_api_variables
    
    # Test environment variable resolution
    test_env_resolution
    
    # Test variable precedence
    test_variable_precedence
    
    # Simulate API variable injection
    simulate_api_injection
    
    # Generate API variable report
    generate_api_report
    
    log_success "🎉 Codemagic API variable injection test completed"
    log_info "📋 Summary:"
    log_info "   ✅ API variables checked"
    log_info "   ✅ Environment resolution tested"
    log_info "   ✅ Variable precedence tested"
    log_info "   ✅ API injection simulated"
    log_info "   ✅ Report generated"
}

# Run main function
main "$@" 