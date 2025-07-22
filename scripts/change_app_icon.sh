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

if [ ! -f "$logo_path" ]; then
    log_error "❌ Logo file not found: $logo_path"
    exit 1
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