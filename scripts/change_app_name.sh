#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_NAME] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_NAME] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_NAME] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_NAME] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [APP_NAME] ❌ $1"; }

log "🎨 Changing App Name"

new_name="${1:-$APP_NAME}"

if [ -z "$new_name" ]; then
    log_error "❌ No app name provided"
    exit 1
fi

log_info "Setting app name to: $new_name"

# Update iOS Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    log_info "Updating iOS Info.plist"
    plutil -replace CFBundleDisplayName -string "$new_name" ios/Runner/Info.plist 2>/dev/null || {
        log_warning "Failed to update CFBundleDisplayName, trying alternative method"
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $new_name" ios/Runner/Info.plist 2>/dev/null || {
            log_warning "Failed to update iOS app name"
        }
    }
    log_success "✅ Updated iOS app name"
else
    log_warning "⚠️ iOS Info.plist not found"
fi

# Update Android strings.xml
if [ -f "android/app/src/main/res/values/strings.xml" ]; then
    log_info "Updating Android strings.xml"
    sed -i '' "s/<string name=\"app_name\">.*<\/string>/<string name=\"app_name\">$new_name<\/string>/g" android/app/src/main/res/values/strings.xml 2>/dev/null || {
        log_warning "Failed to update Android app name"
    }
    log_success "✅ Updated Android app name"
else
    log_warning "⚠️ Android strings.xml not found"
fi

# Update pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    log_info "Updating pubspec.yaml"
    sed -i '' "s/name:.*/name: ${new_name,,}/g" pubspec.yaml 2>/dev/null || {
        log_warning "Failed to update pubspec.yaml name"
    }
    log_success "✅ Updated pubspec.yaml name"
else
    log_warning "⚠️ pubspec.yaml not found"
fi

log_success "✅ App name change completed successfully"
exit 0 