#!/bin/bash

# API Variables Summary Script
# Shows which variables are being prioritized from the API

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

log_info "📋 API Variables Summary - Prioritized Variables"

# List of variables that are prioritized from API (not from env.sh defaults)
api_prioritized_vars=(
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

# Function to check variable status
check_variable_status() {
    local var_name="$1"
    local api_value="${!var_name:-}"
    local env_value=""
    
    # Try to get value from env.sh if it exists
    if [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
        source "${SCRIPT_DIR}/../../lib/config/env.sh" 2>/dev/null || true
        env_value="${!var_name:-}"
    fi
    
    if [ -n "$api_value" ]; then
        if [ "$api_value" != "$env_value" ]; then
            log_success "✅ $var_name: API value '$api_value' (overrides env.sh)"
        else
            log_info "ℹ️ $var_name: API value '$api_value' (matches env.sh)"
        fi
    else
        if [ -n "$env_value" ]; then
            log_warning "⚠️ $var_name: Using env.sh value '$env_value' (no API value)"
        else
            log_error "❌ $var_name: No value available"
        fi
    fi
}

# Main execution
main() {
    log_info "🔍 Checking API Variable Prioritization..."
    log_info "📋 Total API variables to check: ${#api_prioritized_vars[@]}"
    log_info ""
    
    local found_api_vars=0
    local found_env_vars=0
    local missing_vars=0
    
    for var in "${api_prioritized_vars[@]}"; do
        local api_value="${!var:-}"
        if [ -n "$api_value" ]; then
            found_api_vars=$((found_api_vars + 1))
        else
            missing_vars=$((missing_vars + 1))
        fi
    done
    
    log_info "📊 Summary:"
    log_info "   ✅ API variables found: $found_api_vars"
    log_info "   ❌ Missing API variables: $missing_vars"
    log_info "   📋 Total variables: ${#api_prioritized_vars[@]}"
    log_info ""
    
    # Check each variable
    for var in "${api_prioritized_vars[@]}"; do
        check_variable_status "$var"
    done
    
    log_info ""
    log_info "🎯 API Variable Prioritization Summary:"
    log_info "   - Only the above variables are prioritized from API"
    log_info "   - All other variables use env.sh defaults"
    log_info "   - API values take precedence over env.sh values"
    log_info "   - If API value is missing, fallback to env.sh or default"
}

# Run main function
main "$@" 