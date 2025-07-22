#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VERSION] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VERSION] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VERSION] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [VERSION] ❌ $1"; }

log "📦 Setting App Version"

version_name="${1:-$VERSION_NAME}"
version_code="${2:-$VERSION_CODE}"

if [ -z "$version_name" ] || [ -z "$version_code" ]; then
    log_error "❌ Version name or code not provided"
    exit 1
fi

log_info "Setting version to: $version_name ($version_code)"

# Update pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    log_info "Updating pubspec.yaml version"
    sed -i '' "s/version:.*/version: $version_name+$version_code/g" pubspec.yaml 2>/dev/null || {
        log_warning "Failed to update pubspec.yaml version"
    }
    log_success "✅ Updated pubspec.yaml version"
else
    log_warning "⚠️ pubspec.yaml not found"
fi

# Update iOS Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    log_info "Updating iOS Info.plist version"
    plutil -replace CFBundleShortVersionString -string "$version_name" ios/Runner/Info.plist 2>/dev/null || {
        log_warning "Failed to update iOS CFBundleShortVersionString"
    }
    plutil -replace CFBundleVersion -string "$version_code" ios/Runner/Info.plist 2>/dev/null || {
        log_warning "Failed to update iOS CFBundleVersion"
    }
    log_success "✅ Updated iOS Info.plist version"
else
    log_warning "⚠️ iOS Info.plist not found"
fi

# Update Android build.gradle
if [ -f "android/app/build.gradle" ]; then
    log_info "Updating Android build.gradle version"
    sed -i '' "s/versionName \".*\"/versionName \"$version_name\"/g" android/app/build.gradle 2>/dev/null || {
        log_warning "Failed to update Android versionName"
    }
    sed -i '' "s/versionCode [0-9]*/versionCode $version_code/g" android/app/build.gradle 2>/dev/null || {
        log_warning "Failed to update Android versionCode"
    }
    log_success "✅ Updated Android build.gradle version"
else
    log_warning "⚠️ Android build.gradle not found"
fi

# Update AndroidManifest.xml
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    log_info "Updating AndroidManifest.xml version"
    sed -i '' "s/android:versionName=\".*\"/android:versionName=\"$version_name\"/g" android/app/src/main/AndroidManifest.xml 2>/dev/null || {
        log_warning "Failed to update AndroidManifest.xml versionName"
    }
    sed -i '' "s/android:versionCode=\"[0-9]*\"/android:versionCode=\"$version_code\"/g" android/app/src/main/AndroidManifest.xml 2>/dev/null || {
        log_warning "Failed to update AndroidManifest.xml versionCode"
    }
    log_success "✅ Updated AndroidManifest.xml version"
else
    log_warning "⚠️ AndroidManifest.xml not found"
fi

log_success "✅ Version update completed successfully"
exit 0 