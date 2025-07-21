#!/bin/bash

# Simple Certificate Validation Script (No Encoding Required)
# Purpose: Basic validation for IPA export without complex setup

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

# Source utilities if available
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
else
    # Basic logging functions if utils not available
    log_info() { echo "ℹ️ $1"; }
    log_success() { echo "✅ $1"; }
    log_warn() { echo "⚠️ $1"; }
    log_error() { echo "❌ $1"; }
fi

log_info "🔒 Certificate Validation with App Store Connect API..."

# Download App Store Connect API Key
log_info "📥 Setting up App Store Connect API credentials..."

# Use the specific credentials provided
export APP_STORE_CONNECT_KEY_IDENTIFIER="${APP_STORE_CONNECT_KEY_IDENTIFIER:-ZFD9GRMS7R}"
export APP_STORE_CONNECT_API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_ZFD9GRMS7R.p8}"
export APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-a99a2ebd-ed3e-4117-9f97-f195823774a7}"

log_info "🔐 App Store Connect API Configuration:"
log_info "   - Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER}"
log_info "   - Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID}"
log_info "   - API Key URL: ${APP_STORE_CONNECT_API_KEY_PATH}"

# Download the p8 file from GitHub
log_info "📥 Downloading p8 API key from GitHub..."
API_KEY_PATH="/tmp/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

if curl -fsSL -o "${API_KEY_PATH}" "${APP_STORE_CONNECT_API_KEY_PATH}"; then
    log_success "✅ API key downloaded successfully to ${API_KEY_PATH}"
    
    # Verify the downloaded file
    if [[ -f "${API_KEY_PATH}" && -s "${API_KEY_PATH}" ]]; then
        log_success "✅ API key file verified (Size: $(du -h "${API_KEY_PATH}" | cut -f1))"
        
        # Check if it looks like a valid p8 file
        if head -1 "${API_KEY_PATH}" | grep -q "BEGIN PRIVATE KEY"; then
            log_success "✅ API key format validation passed"
        else
            log_warn "⚠️ API key format validation warning - file may not be a valid p8 key"
        fi
        
        export APP_STORE_CONNECT_API_KEY_DOWNLOADED_PATH="${API_KEY_PATH}"
        export EXPORT_METHOD="app_store_connect_api"
        log_success "✅ Using App Store Connect API for authentication"
        
    else
        log_error "❌ Downloaded API key file is empty or invalid"
        log_warn "⚠️ Falling back to automatic signing"
        export EXPORT_METHOD="automatic_basic"
    fi
else
    log_error "❌ Failed to download API key from GitHub"
    log_error "   URL: ${APP_STORE_CONNECT_API_KEY_PATH}"
    log_warn "⚠️ Falling back to automatic signing with Team ID"
    
    if [ -n "${APPLE_TEAM_ID:-}" ]; then
        log_info "👥 Team ID available: ${APPLE_TEAM_ID}"
        export EXPORT_METHOD="automatic_with_team"
    else
        log_warn "⚠️ No Team ID configured - using basic automatic signing"
        export EXPORT_METHOD="automatic_basic"
    fi
fi

# Determine export method based on profile type
case "$PROFILE_TYPE" in
    "app-store")
        export_method="app-store"
        distribution_type="app-store"
        log_info "🏪 Using app-store export method"
        ;;
    "ad-hoc")
        export_method="ad-hoc"
        distribution_type="ad-hoc"
        log_info "📱 Using ad-hoc export method"
        ;;
    *)
        log_error "❌ Invalid profile type: $PROFILE_TYPE"
        log_error "Supported types: app-store, ad-hoc"
        return 1
        ;;
esac

log_info "📋 Profile Type: ${PROFILE_TYPE:-app-store}"
log_info "📦 Distribution Type: ${distribution_type}"
log_info "🎯 Export Method: ${export_method}"

# Create simple export options (no encoding required)
log_info "📝 Creating simple ExportOptions.plist..."
mkdir -p ios/export_options

cat > ios/export_options/ExportOptions.plist << SIMPLE_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>${export_method}</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-AUTOMATIC}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
SIMPLE_EOF

log_success "✅ Simple export configuration created"
log_info "📋 Export Method: ${export_method}"
log_info "👥 Team ID: ${APPLE_TEAM_ID:-AUTOMATIC}"
log_info "🔐 Signing Style: automatic"

log_success "✅ Certificate validation completed - Export Method: ${EXPORT_METHOD}"
return 0
 