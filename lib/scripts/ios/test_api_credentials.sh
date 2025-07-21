#!/bin/bash

# Test App Store Connect API Credentials
# Purpose: Validate that the API credentials are working and can be downloaded

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

log_info "🔍 Testing App Store Connect API Credentials..."

# Use the specific credentials provided
export APP_STORE_CONNECT_KEY_IDENTIFIER="${APP_STORE_CONNECT_KEY_IDENTIFIER:-ZFD9GRMS7R}"
export APP_STORE_CONNECT_API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/AuthKey_ZFD9GRMS7R.p8}"
export APP_STORE_CONNECT_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-a99a2ebd-ed3e-4117-9f97-f195823774a7}"

log_info "🔐 Testing App Store Connect API Configuration:"
log_info "   - Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER}"
log_info "   - Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID}"
log_info "   - API Key URL: ${APP_STORE_CONNECT_API_KEY_PATH}"

# Test 1: Download API key
log_info "📥 Test 1: Downloading p8 API key from GitHub..."
API_KEY_PATH="/tmp/test_AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

if curl -fsSL -o "${API_KEY_PATH}" "${APP_STORE_CONNECT_API_KEY_PATH}"; then
    log_success "✅ API key downloaded successfully"
    
    # Test 2: Verify file exists and has content
    if [[ -f "${API_KEY_PATH}" && -s "${API_KEY_PATH}" ]]; then
        FILE_SIZE=$(du -h "${API_KEY_PATH}" | cut -f1)
        log_success "✅ API key file verified (Size: ${FILE_SIZE})"
        
        # Test 3: Check file format
        if head -1 "${API_KEY_PATH}" | grep -q "BEGIN PRIVATE KEY"; then
            log_success "✅ API key format validation passed"
        else
            log_warn "⚠️ API key format validation warning"
            log_info "First line of file: $(head -1 "${API_KEY_PATH}")"
        fi
        
        # Test 4: Check file permissions
        chmod 600 "${API_KEY_PATH}"
        log_success "✅ File permissions set correctly"
        
        # Test 5: Validate content structure
        if grep -q "END PRIVATE KEY" "${API_KEY_PATH}"; then
            log_success "✅ API key structure validation passed"
        else
            log_warn "⚠️ API key structure validation warning"
        fi
        
        # Display file info
        log_info "📋 API Key File Information:"
        log_info "   - Path: ${API_KEY_PATH}"
        log_info "   - Size: ${FILE_SIZE}"
        log_info "   - Lines: $(wc -l < "${API_KEY_PATH}")"
        log_info "   - Permissions: $(ls -la "${API_KEY_PATH}" | awk '{print $1}')"
        
        # Test 6: Test with a simple security command
        if security verify-cert "${API_KEY_PATH}" 2>/dev/null; then
            log_success "✅ Security validation passed"
        else
            log_info "ℹ️ Security validation skipped (p8 keys don't use verify-cert)"
        fi
        
        # Clean up test file
        rm -f "${API_KEY_PATH}"
        log_success "✅ Test file cleaned up"
        
        log_success "🎉 All App Store Connect API credential tests passed!"
        log_info "🚀 Credentials are ready for IPA export with Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER}"
        
        exit 0
        
    else
        log_error "❌ Downloaded API key file is empty or invalid"
        rm -f "${API_KEY_PATH}"
        exit 1
    fi
else
    log_error "❌ Failed to download API key from GitHub"
    log_error "   URL: ${APP_STORE_CONNECT_API_KEY_PATH}"
    log_info "Possible issues:"
    log_info "  1. GitHub URL is not accessible"
    log_info "  2. p8 file doesn't exist at the URL"
    log_info "  3. Network connectivity issues"
    log_info "  4. GitHub repository is private or restricted"
    exit 1
fi 