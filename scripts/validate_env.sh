#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VALIDATE] ❌ $1"; }

log "🔍 Validating Required Environment Variables"

# Define all required environment variables
REQUIRED_VARS=(
    "APP_NAME"
    "VERSION_NAME"
    "VERSION_CODE"
    "EMAIL_ID"
    "BUNDLE_ID"
    "APPLE_TEAM_ID"
    "PROFILE_TYPE"
    "WORKFLOW_ID"
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
    "LOGO_URL"
    "SPLASH_URL"
    "SPLASH_BG_COLOR"
    "SPLASH_TAGLINE"
    "SPLASH_TAGLINE_COLOR"
    "FIREBASE_CONFIG_ANDROID"
    "APNS_KEY_ID"
    "APNS_AUTH_KEY_URL"
    "KEY_STORE_URL"
    "CM_KEYSTORE_PASSWORD"
    "CM_KEY_ALIAS"
    "CM_KEY_PASSWORD"
)

# Check for all required env vars
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
        log_error "Missing environment variable: $var"
    else
        log_info "✅ $var: ${!var}"
    fi
done

# Check for optional but important variables
OPTIONAL_VARS=(
    "APP_STORE_CONNECT_KEY_IDENTIFIER"
    "APP_STORE_CONNECT_ISSUER_ID"
    "APP_STORE_CONNECT_API_KEY_URL"
    "IS_TESTFLIGHT"
    "PROFILE_URL"
)

for var in "${OPTIONAL_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        log_info "⚠️ Optional variable not set: $var"
    else
        log_info "✅ $var: ${!var}"
    fi
done

# Exit with error if any required variables are missing
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "❌ Missing required environment variables: ${MISSING_VARS[*]}"
    log_error "Please set all required environment variables in Codemagic"
    exit 1
fi

log_success "✅ All required environment variables are present"
log_success "✅ Environment validation completed successfully"
exit 0 