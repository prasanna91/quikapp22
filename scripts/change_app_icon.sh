#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_ICON] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_ICON] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_ICON] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_ICON] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_ICON] ❌ $1"; }

log "🎨 Changing App Icon"

logo_path="${1:-assets/images/logo.png}"

# Check if the path is a URL and download it if needed
if [[ "$logo_path" == http* ]]; then
    log_info "Logo path is a URL, downloading to assets/images/logo.png"
    mkdir -p assets/images
    if curl -L -o "assets/images/logo.png" "$logo_path" 2>/dev/null; then
        logo_path="assets/images/logo.png"
        log_success "✅ Downloaded logo from URL"
    else
        log_warning "⚠️ Failed to download logo from URL, using default"
        logo_path="assets/images/logo.png"
    fi
fi

if [ ! -f "$logo_path" ]; then
    log_warning "⚠️ Logo file not found: $logo_path, creating default"
    mkdir -p assets/images
    # Create a simple default logo (1x1 pixel transparent PNG)
    echo -en '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x00\x00\x02\x00\x01\xe5\x27\xde\xfc\x00\x00\x00\x00IEND\xaeB`\x82' > "$logo_path"
    log_info "Created default logo"
fi

log_info "Using logo from: $logo_path"

# Create flutter_launcher_icons.yaml configuration
cat > flutter_launcher_icons.yaml << EOF
flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "$logo_path"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "$logo_path"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "$logo_path"
    icon_size: 48
  macos:
    generate: true
    image_path: "$logo_path"
EOF

log_info "Generated flutter_launcher_icons.yaml configuration"

# Run flutter_launcher_icons
if command -v flutter >/dev/null 2>&1; then
    log_info "Running flutter_launcher_icons"
    flutter pub get
    flutter pub run flutter_launcher_icons:main || {
        log_warning "flutter_launcher_icons failed, trying alternative method"
        
        # Alternative: Copy icon to iOS assets
        if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
            log_info "Copying icon to iOS assets"
            cp "$logo_path" ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png 2>/dev/null || true
            log_success "✅ Copied icon to iOS assets"
        fi
        
        # Alternative: Copy icon to Android assets
        if [ -d "android/app/src/main/res" ]; then
            log_info "Copying icon to Android assets"
            mkdir -p android/app/src/main/res/mipmap-hdpi
            mkdir -p android/app/src/main/res/mipmap-mdpi
            mkdir -p android/app/src/main/res/mipmap-xhdpi
            mkdir -p android/app/src/main/res/mipmap-xxhdpi
            mkdir -p android/app/src/main/res/mipmap-xxxhdpi
            
            cp "$logo_path" android/app/src/main/res/mipmap-hdpi/ic_launcher.png 2>/dev/null || true
            cp "$logo_path" android/app/src/main/res/mipmap-mdpi/ic_launcher.png 2>/dev/null || true
            cp "$logo_path" android/app/src/main/res/mipmap-xhdpi/ic_launcher.png 2>/dev/null || true
            cp "$logo_path" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png 2>/dev/null || true
            cp "$logo_path" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png 2>/dev/null || true
            
            log_success "✅ Copied icon to Android assets"
        fi
    }
else
    log_warning "⚠️ Flutter not found, skipping icon generation"
fi

log_success "✅ App icon change completed successfully"
exit 0 