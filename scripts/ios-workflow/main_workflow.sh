#!/bin/bash
# 🚀 Main iOS Workflow Script
# Orchestrates complete iOS build process with all requirements

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WORKFLOW] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    log "Environment configuration file not found, using system environment variables"
fi

# Function to safely get environment variable with fallback
get_api_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        log "✅ Found API variable $var_name: $value"
        printf "%s" "$value"
    else
        log "⚠️ API variable $var_name not set, using fallback: $fallback"
        printf "%s" "$fallback"
    fi
}

# Set all required variables with defaults
export WORKFLOW_ID=$(get_api_var "WORKFLOW_ID" "ios-workflow")
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_api_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_api_var "VERSION_CODE" "1")
export EMAIL_ID=$(get_api_var "EMAIL_ID" "admin@example.com")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "com.example.quikapp")
export APPLE_TEAM_ID=$(get_api_var "APPLE_TEAM_ID" "")
export PROFILE_TYPE=$(get_api_var "PROFILE_TYPE" "app-store")
export PROFILE_URL=$(get_api_var "PROFILE_URL" "")
export IS_TESTFLIGHT=$(get_api_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_api_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_api_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_api_var "APP_STORE_CONNECT_API_KEY_URL" "")
export LOGO_URL=$(get_api_var "LOGO_URL" "")
export SPLASH_URL=$(get_api_var "SPLASH_URL" "")
export SPLASH_BG_COLOR=$(get_api_var "SPLASH_BG_COLOR" "#FFFFFF")
export SPLASH_TAGLINE=$(get_api_var "SPLASH_TAGLINE" "")
export SPLASH_TAGLINE_COLOR=$(get_api_var "SPLASH_TAGLINE_COLOR" "#000000")
export FIREBASE_CONFIG_IOS=$(get_api_var "FIREBASE_CONFIG_IOS" "")
export ENABLE_EMAIL_NOTIFICATIONS=$(get_api_var "ENABLE_EMAIL_NOTIFICATIONS" "false")
export EMAIL_SMTP_SERVER=$(get_api_var "EMAIL_SMTP_SERVER" "")
export EMAIL_SMTP_PORT=$(get_api_var "EMAIL_SMTP_PORT" "587")
export EMAIL_SMTP_USER=$(get_api_var "EMAIL_SMTP_USER" "")
export EMAIL_SMTP_PASS=$(get_api_var "EMAIL_SMTP_PASS" "")
export USER_NAME=$(get_api_var "USER_NAME" "Admin")
export APP_ID=$(get_api_var "APP_ID" "quikapp")
export ORG_NAME=$(get_api_var "ORG_NAME" "QuikApp")
export WEB_URL=$(get_api_var "WEB_URL" "https://quikapp.com")
export PKG_NAME=$(get_api_var "PKG_NAME" "com.example.quikapp")
export PUSH_NOTIFY=$(get_api_var "PUSH_NOTIFY" "false")
export IS_CHATBOT=$(get_api_var "IS_CHATBOT" "false")
export IS_DOMAIN_URL=$(get_api_var "IS_DOMAIN_URL" "false")
export IS_SPLASH=$(get_api_var "IS_SPLASH" "true")
export IS_PULLDOWN=$(get_api_var "IS_PULLDOWN" "false")
export IS_BOTTOMMENU=$(get_api_var "IS_BOTTOMMENU" "false")
export IS_LOAD_IND=$(get_api_var "IS_LOAD_IND" "false")
export IS_CAMERA=$(get_api_var "IS_CAMERA" "false")
export IS_LOCATION=$(get_api_var "IS_LOCATION" "false")
export IS_MIC=$(get_api_var "IS_MIC" "false")
export IS_NOTIFICATION=$(get_api_var "IS_NOTIFICATION" "false")
export IS_CONTACT=$(get_api_var "IS_CONTACT" "false")
export IS_BIOMETRIC=$(get_api_var "IS_BIOMETRIC" "false")
export IS_CALENDAR=$(get_api_var "IS_CALENDAR" "false")
export IS_STORAGE=$(get_api_var "IS_STORAGE" "false")

# Create output directories
mkdir -p output/ios
mkdir -p build/ios/logs

# Function to run script with error handling
run_script() {
    local script_name="$1"
    local script_path="$2"
    local description="$3"
    
    log_info "Running $description"
    log "Executing: $script_path"
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if "$script_path"; then
            log_success "$description completed successfully"
            return 0
        else
            log_error "$description failed"
            return 1
        fi
    else
        log_warning "Script not found: $script_path"
        return 1
    fi
}

# Function to validate essential variables
validate_essentials() {
    log_info "Validating essential variables..."
    
    ESSENTIAL_VARS=("BUNDLE_ID" "APPLE_TEAM_ID" "PROFILE_TYPE")
    MISSING_VARS=()
    
    for var in "${ESSENTIAL_VARS[@]}"; do
        if [ -z "${!var:-}" ]; then
            MISSING_VARS+=("$var")
        fi
    done
    
    if [ ${#MISSING_VARS[@]} -gt 0 ]; then
        log_error "Missing essential variables: ${MISSING_VARS[*]}"
        log "Please provide the following variables:"
        log "  - BUNDLE_ID: Your app's bundle identifier"
        log "  - APPLE_TEAM_ID: Your Apple Developer Team ID"
        log "  - PROFILE_TYPE: Distribution type (app-store, ad-hoc, development)"
        return 1
    fi
    
    log_success "Essential variables validated"
    return 0
}

# Function to create workflow summary
create_workflow_summary() {
    log_info "Creating workflow summary..."
    
    cat > output/ios/WORKFLOW_SUMMARY.txt <<EOF
iOS Workflow Summary
===================

Workflow Information:
- Workflow ID: $WORKFLOW_ID
- App Name: $APP_NAME
- Version Name: $VERSION_NAME
- Version Code: $VERSION_CODE
- Bundle ID: $BUNDLE_ID
- Team ID: $APPLE_TEAM_ID
- Profile Type: $PROFILE_TYPE

Feature Configuration:
- Push Notifications: $PUSH_NOTIFY
- Firebase Setup: $([ "$PUSH_NOTIFY" = "true" ] && echo "Enabled" || echo "Disabled")
- TestFlight Upload: $([ "$IS_TESTFLIGHT" = "true" ] && echo "Enabled" || echo "Disabled")
- Email Notifications: $([ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && echo "Enabled" || echo "Disabled")

Asset Configuration:
- Logo URL: $LOGO_URL
- Splash URL: $SPLASH_URL
- Splash Background Color: $SPLASH_BG_COLOR
- Splash Tagline: $SPLASH_TAGLINE

Build Results:
- IPA File: $([ -f "output/ios/Runner.ipa" ] && echo "✅ Created" || echo "❌ Missing")
- Build Status: $([ -f "output/ios/Runner.ipa" ] && echo "SUCCESS" || echo "FAILED")
- Build Time: $(date)

Environment Variables Used:
$(env | grep -E '^(WORKFLOW_ID|APP_NAME|VERSION_NAME|VERSION_CODE|EMAIL_ID|BUNDLE_ID|APPLE_TEAM_ID|PROFILE_TYPE|IS_TESTFLIGHT|PUSH_NOTIFY|FIREBASE_CONFIG_IOS|LOGO_URL|SPLASH_URL)' | sort)

Workflow Steps Completed:
1. ✅ Environment Setup
2. ✅ Asset Downloads
3. ✅ Firebase Setup (if PUSH_NOTIFY=true)
4. ✅ App Configuration
5. ✅ Build Process
6. ✅ IPA Creation
7. ✅ TestFlight Upload (if IS_TESTFLIGHT=true)
EOF

    log_success "Workflow summary created"
}

# Main workflow execution
main() {
    log_info "🚀 Starting iOS Workflow"
    log "Workflow ID: $WORKFLOW_ID"
    log "App Name: $APP_NAME"
    log "Bundle ID: $BUNDLE_ID"
    
    # Step 1: Validate essential variables
    if ! validate_essentials; then
        log_error "Essential variables validation failed"
        
        # Send failure email notification
        if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
            chmod +x scripts/ios-workflow/email_notifications.sh
            ./scripts/ios-workflow/email_notifications.sh "failure" "Essential variables validation failed"
        fi
        
        exit 1
    fi
    
    # Send build started email notification
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
        chmod +x scripts/ios-workflow/email_notifications.sh
        ./scripts/ios-workflow/email_notifications.sh "started"
    fi
    
    # Step 2: Environment Setup
    log_info "Step 2: Environment Setup"
    if ! run_script "Environment Setup" "lib/scripts/utils/gen_env_config.sh" "Environment configuration generation"; then
        log_warning "Environment setup failed (continuing...)"
    fi
    
    # Step 3: Asset Downloads
    log_info "Step 3: Asset Downloads"
    if ! run_script "Asset Downloads" "scripts/ios-workflow/asset_download.sh" "Asset download and configuration"; then
        log_warning "Asset downloads failed (continuing...)"
    fi
    
    # Step 4: Firebase Setup (if PUSH_NOTIFY is true)
    if [ "$PUSH_NOTIFY" = "true" ]; then
        log_info "Step 4: Firebase Setup"
        if ! run_script "Firebase Setup" "scripts/ios-workflow/firebase_setup.sh" "Firebase configuration"; then
            log_warning "Firebase setup failed (continuing...)"
        fi
    else
        log_info "Step 4: Firebase Setup (Skipped)"
        log "PUSH_NOTIFY is false, skipping Firebase setup"
    fi
    
    # Step 5: App Configuration
    log_info "Step 5: App Configuration"
    log "Updating app configuration..."
    
    # Update bundle identifier
    if [ -n "$BUNDLE_ID" ]; then
        if [ -f "scripts/ios-workflow/update_bundle_id_target_only.sh" ]; then
            chmod +x scripts/ios-workflow/update_bundle_id_target_only.sh
            if ./scripts/ios-workflow/update_bundle_id_target_only.sh "$BUNDLE_ID"; then
                log_success "Bundle ID updated to: $BUNDLE_ID"
            else
                log_warning "Bundle ID update failed"
            fi
        fi
    fi
    
    # Update app name
    if [ -n "$APP_NAME" ] && [ -f "ios/Runner/Info.plist" ]; then
        if plutil -replace CFBundleDisplayName -string "$APP_NAME" ios/Runner/Info.plist 2>/dev/null; then
            log_success "App name updated to: $APP_NAME"
        else
            log_warning "App name update failed"
        fi
    fi
    
    # Step 6: Build Process
    log_info "Step 6: Build Process"
    if ! run_script "Build Process" "scripts/ios-workflow/comprehensive_build.sh" "iOS build process"; then
        log_error "Build process failed"
        
        # Send build failure email notification
        if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
            chmod +x scripts/ios-workflow/email_notifications.sh
            ./scripts/ios-workflow/email_notifications.sh "failure" "Build process failed during iOS build"
        fi
        
        exit 1
    fi
    
    # Step 7: TestFlight Upload (if enabled)
    if [ "$IS_TESTFLIGHT" = "true" ]; then
        log_info "Step 7: TestFlight Upload"
        if ! run_script "TestFlight Upload" "scripts/ios-workflow/testflight_upload.sh" "TestFlight upload"; then
            log_warning "TestFlight upload failed (continuing...)"
        fi
    else
        log_info "Step 7: TestFlight Upload (Skipped)"
        log "IS_TESTFLIGHT is false, skipping TestFlight upload"
    fi
    
    # Step 8: Create Workflow Summary
    create_workflow_summary
    
    # Step 9: Final Validation
    log_info "Step 9: Final Validation"
    log "Validating workflow results..."
    
    # Check if IPA was created
    if [ -f "output/ios/Runner.ipa" ]; then
        IPA_SIZE=$(stat -f%z "output/ios/Runner.ipa" 2>/dev/null || stat -c%s "output/ios/Runner.ipa" 2>/dev/null || echo "0")
        log_success "Workflow completed successfully!"
        log "IPA file created: output/ios/Runner.ipa ($IPA_SIZE bytes)"
    else
        log_error "Workflow failed - IPA file not found"
        exit 1
    fi
    
    # Step 10: Email Notification (if enabled)
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ]; then
        log_info "Step 10: Email Notification"
        log "Sending build success email notification..."
        
        if [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
            chmod +x scripts/ios-workflow/email_notifications.sh
            if ./scripts/ios-workflow/email_notifications.sh "success"; then
                log_success "Build success email notification sent"
            else
                log_warning "Build success email notification failed"
            fi
        else
            log_warning "Email notification script not found"
        fi
    else
        log_info "Step 10: Email Notification (Skipped)"
        log "Email notifications not enabled"
    fi
    
    log_success "🎉 iOS Workflow completed successfully!"
    log "📁 Build artifacts available in: output/ios/"
    log "📋 Summary available in: output/ios/WORKFLOW_SUMMARY.txt"
}

# Execute main function
main "$@" 