#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DOWNLOAD] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DOWNLOAD] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DOWNLOAD] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DOWNLOAD] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DOWNLOAD] ❌ $1"; }

log "⬇️ Downloading Assets and Configuration Files"

# Create necessary directories
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p ios/Runner
mkdir -p certificates

# Function to download file with error handling
download_file() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    if [ -n "$url" ]; then
        log_info "Downloading $description from: $url"
        if curl -L -o "$output_path" "$url" 2>/dev/null; then
            log_success "✅ Downloaded $description"
        else
            log_warning "⚠️ Failed to download $description from $url"
        fi
    else
        log_info "⏭️ Skipping $description (URL not provided)"
    fi
}

# Download app logo
download_file "$LOGO_URL" "assets/images/logo.png" "app logo"

# Download splash screen
download_file "$SPLASH_URL" "assets/images/splash.png" "splash screen"

# Download Firebase configuration for iOS
download_file "$FIREBASE_CONFIG_IOS" "ios/Runner/GoogleService-Info.plist" "Firebase iOS config"

# Download Firebase configuration for Android
download_file "$FIREBASE_CONFIG_ANDROID" "android/app/google-services.json" "Firebase Android config"

# Download iOS provisioning profile
download_file "$PROFILE_URL" "certificates/ios_profile.mobileprovision" "iOS provisioning profile"

# Download App Store Connect API key
download_file "$APP_STORE_CONNECT_API_KEY_URL" "certificates/AuthKey.p8" "App Store Connect API key"

# Download APNS auth key
download_file "$APNS_AUTH_KEY_URL" "certificates/AuthKey_${APNS_KEY_ID}.p8" "APNS auth key"

# Download Android keystore
download_file "$KEY_STORE_URL" "certificates/keystore.jks" "Android keystore"

# Download default assets if not provided
if [ ! -f "assets/images/logo.png" ]; then
    log_info "Creating default logo"
    # Create a simple default logo (1x1 pixel transparent PNG)
    echo -en '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x00\x00\x02\x00\x01\xe5\x27\xde\xfc\x00\x00\x00\x00IEND\xaeB`\x82' > assets/images/logo.png
fi

if [ ! -f "assets/images/splash.png" ]; then
    log_info "Creating default splash screen"
    # Create a simple default splash (1x1 pixel transparent PNG)
    echo -en '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x00\x00\x02\x00\x01\xe5\x27\xde\xfc\x00\x00\x00\x00IEND\xaeB`\x82' > assets/images/splash.png
fi

# Set proper permissions for certificates
if [ -f "certificates/AuthKey.p8" ]; then
    chmod 600 certificates/AuthKey.p8
fi

if [ -f "certificates/keystore.jks" ]; then
    chmod 600 certificates/keystore.jks
fi

log_success "✅ Asset download completed successfully"
exit 0 