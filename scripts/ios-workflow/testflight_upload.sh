#!/bin/bash
# 🚀 TestFlight Upload Script for iOS Workflow
# Uploads IPA to TestFlight only when IS_TESTFLIGHT is true

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TESTFLIGHT] $1"; }
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

# Set TestFlight configuration variables
export IS_TESTFLIGHT=$(get_api_var "IS_TESTFLIGHT" "false")
export APP_STORE_CONNECT_KEY_IDENTIFIER=$(get_api_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "")
export APP_STORE_CONNECT_ISSUER_ID=$(get_api_var "APP_STORE_CONNECT_ISSUER_ID" "")
export APP_STORE_CONNECT_API_KEY_URL=$(get_api_var "APP_STORE_CONNECT_API_KEY_URL" "")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "com.example.quikapp")
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_api_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_api_var "VERSION_CODE" "1")

# Check if TestFlight upload is required
if [ "$IS_TESTFLIGHT" != "true" ]; then
    log_info "TestFlight Upload (Skipped)"
    log "IS_TESTFLIGHT is false, skipping TestFlight upload"
    exit 0
fi

log_info "TestFlight Upload for iOS"
log "Preparing to upload to TestFlight..."

# Step 1: Validate TestFlight Configuration
log_info "Step 1: Validate TestFlight Configuration"
log "Validating TestFlight configuration..."

# Check required variables
MISSING_VARS=()
if [ -z "$APP_STORE_CONNECT_KEY_IDENTIFIER" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_KEY_IDENTIFIER")
fi

if [ -z "$APP_STORE_CONNECT_ISSUER_ID" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_ISSUER_ID")
fi

if [ -z "$APP_STORE_CONNECT_API_KEY_URL" ]; then
    MISSING_VARS+=("APP_STORE_CONNECT_API_KEY_URL")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_error "Missing required TestFlight variables: ${MISSING_VARS[*]}"
    log "Please provide the following variables:"
    log "  - APP_STORE_CONNECT_KEY_IDENTIFIER: Your API key ID"
    log "  - APP_STORE_CONNECT_ISSUER_ID: Your issuer ID"
    log "  - APP_STORE_CONNECT_API_KEY_URL: URL to your .p8 API key file"
    exit 1
fi

log_success "TestFlight configuration validated"

# Step 2: Find IPA File
log_info "Step 2: Find IPA File"
log "Locating IPA file for upload..."

# Look for IPA files in common locations
IPA_PATHS=(
    "output/ios/Runner.ipa"
    "build/ios/ipa/Runner.ipa"
    "ios/build/ios/ipa/Runner.ipa"
    "*.ipa"
)

IPA_FILE=""
for path in "${IPA_PATHS[@]}"; do
    if [ -f "$path" ]; then
        IPA_FILE="$path"
        break
    fi
done

# If no specific file found, search for any IPA
if [ -z "$IPA_FILE" ]; then
    IPA_FILES=$(find . -name "*.ipa" -type f 2>/dev/null || true)
    if [ -n "$IPA_FILES" ]; then
        IPA_FILE=$(echo "$IPA_FILES" | head -1)
    fi
fi

if [ -z "$IPA_FILE" ] || [ ! -f "$IPA_FILE" ]; then
    log_error "No IPA file found for upload"
    log "Searched in: ${IPA_PATHS[*]}"
    exit 1
fi

log_success "Found IPA file: $IPA_FILE"

# Step 3: Validate IPA File
log_info "Step 3: Validate IPA File"
log "Validating IPA file..."

# Check file size
IPA_SIZE=$(stat -f%z "$IPA_FILE" 2>/dev/null || stat -c%s "$IPA_FILE" 2>/dev/null || echo "0")
if [ "$IPA_SIZE" -lt 1000000 ]; then
    log_error "IPA file is too small ($IPA_SIZE bytes) - may be corrupted"
    exit 1
fi

log_success "IPA file is valid ($IPA_SIZE bytes)"

# Step 4: Download API Key
log_info "Step 4: Download API Key"
log "Downloading App Store Connect API key..."

API_KEY_PATH="/tmp/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

if curl -L -o "$API_KEY_PATH" "$APP_STORE_CONNECT_API_KEY_URL" 2>/dev/null; then
    chmod 600 "$API_KEY_PATH"
    
    # Validate API key file
    KEY_SIZE=$(stat -f%z "$API_KEY_PATH" 2>/dev/null || stat -c%s "$API_KEY_PATH" 2>/dev/null || echo "0")
    if [ "$KEY_SIZE" -gt 100 ]; then
        log_success "API key downloaded successfully ($KEY_SIZE bytes)"
    else
        log_error "API key file is too small ($KEY_SIZE bytes) - may be corrupted"
        exit 1
    fi
else
    log_error "Failed to download API key"
    log "URL: $APP_STORE_CONNECT_API_KEY_URL"
    exit 1
fi

# Step 5: Validate App Store Connect Access
log_info "Step 5: Validate App Store Connect Access"
log "Validating App Store Connect API access..."

# Test API access
if xcrun altool --list-providers --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" --apiKeyPath "$API_KEY_PATH" 2>/dev/null; then
    log_success "App Store Connect API access validated"
else
    log_warning "Could not validate App Store Connect API access (continuing anyway)"
fi

# Step 6: Upload to TestFlight
log_info "Step 6: Upload to TestFlight"
log "Uploading IPA to TestFlight..."

# Upload using xcrun altool
if xcrun altool --upload-app \
    --type ios \
    --file "$IPA_FILE" \
    --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
    --apiKeyPath "$API_KEY_PATH" \
    --verbose; then
    
    log_success "TestFlight upload completed successfully"
    
    # Send TestFlight success email notification
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
        chmod +x scripts/ios-workflow/email_notifications.sh
        ./scripts/ios-workflow/email_notifications.sh "testflight_success"
    fi
else
    log_error "TestFlight upload failed"
    
    # Send TestFlight failure email notification
    if [ "$ENABLE_EMAIL_NOTIFICATIONS" = "true" ] && [ -f "scripts/ios-workflow/email_notifications.sh" ]; then
        chmod +x scripts/ios-workflow/email_notifications.sh
        ./scripts/ios-workflow/email_notifications.sh "testflight_failure" "TestFlight upload failed"
    fi
    
    exit 1
fi

# Step 7: Wait for Processing
log_info "Step 7: Wait for Processing"
log "Waiting for App Store Connect to process the upload..."

# Note: Processing can take 5-30 minutes
log "Upload submitted successfully. Processing may take 5-30 minutes."
log "You can check the status in App Store Connect or use the following command:"
log "xcrun altool --list-builds --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath $API_KEY_PATH"

# Step 8: Create Upload Summary
log_info "Step 8: Create Upload Summary"
log "Creating upload summary..."

cat > output/ios/TESTFLIGHT_SUMMARY.txt <<EOF
TestFlight Upload Summary
=========================

Upload Configuration:
- TestFlight Enabled: $IS_TESTFLIGHT
- App Name: $APP_NAME
- Bundle ID: $BUNDLE_ID
- Version Name: $VERSION_NAME
- Version Code: $VERSION_CODE

API Configuration:
- Key Identifier: $APP_STORE_CONNECT_KEY_IDENTIFIER
- Issuer ID: $APP_STORE_CONNECT_ISSUER_ID
- API Key URL: $APP_STORE_CONNECT_API_KEY_URL

Upload Details:
- IPA File: $IPA_FILE
- IPA Size: $IPA_SIZE bytes
- Upload Status: ✅ Success

Processing Status:
- Status: Submitted for Processing
- Estimated Time: 5-30 minutes
- Check Status: App Store Connect or use altool --list-builds

Next Steps:
1. Wait for processing to complete (5-30 minutes)
2. Check App Store Connect for build status
3. Add build to TestFlight testing group
4. Submit for Beta App Review (if required)

Upload Time: $(date)
EOF

log_success "TestFlight upload summary created"

# Step 9: Cleanup
log_info "Step 9: Cleanup"
log "Cleaning up temporary files..."

# Remove API key file
rm -f "$API_KEY_PATH"

log_success "TestFlight upload completed successfully!"
log "Upload summary available in: output/ios/TESTFLIGHT_SUMMARY.txt"

# Step 10: Additional Commands
log_info "Step 10: Additional Commands"
log "Useful commands for managing TestFlight builds:"

cat > output/ios/TESTFLIGHT_COMMANDS.txt <<EOF
TestFlight Management Commands
=============================

List all builds:
xcrun altool --list-builds --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath /path/to/AuthKey_$APP_STORE_CONNECT_KEY_IDENTIFIER.p8

Get build info:
xcrun altool --list-builds --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath /path/to/AuthKey_$APP_STORE_CONNECT_KEY_IDENTIFIER.p8 --bundle-id $BUNDLE_ID

Validate IPA before upload:
xcrun altool --validate-app --type ios --file $IPA_FILE --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath /path/to/AuthKey_$APP_STORE_CONNECT_KEY_IDENTIFIER.p8

List testers:
xcrun altool --list-testers --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath /path/to/AuthKey_$APP_STORE_CONNECT_KEY_IDENTIFIER.p8

Add testers:
xcrun altool --add-testers --apiKey $APP_STORE_CONNECT_KEY_IDENTIFIER --apiIssuer $APP_STORE_CONNECT_ISSUER_ID --apiKeyPath /path/to/AuthKey_$APP_STORE_CONNECT_KEY_IDENTIFIER.p8 --emails "tester@example.com"
EOF

log_success "TestFlight management commands saved to output/ios/TESTFLIGHT_COMMANDS.txt"

log_success "TestFlight upload process completed successfully!"
log "Your app has been uploaded to TestFlight and is being processed." 