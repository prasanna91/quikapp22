#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_ID] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_ID] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_ID] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_ID] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [BUNDLE_ID] ❌ $1"; }

log "🎯 Updating Bundle ID"

bundle_id="${1:-$BUNDLE_ID}"

if [ -z "$bundle_id" ]; then
    log_error "❌ No bundle ID provided"
    exit 1
fi

log_info "Setting bundle ID to: $bundle_id"

# Update iOS project.pbxproj
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_info "Updating iOS project.pbxproj"
    sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $bundle_id;/g" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null || {
        log_warning "Failed to update iOS bundle ID using sed"
    }
    log_success "✅ Updated iOS bundle ID"
else
    log_warning "⚠️ iOS project.pbxproj not found"
fi

# Update Android build.gradle
if [ -f "android/app/build.gradle" ]; then
    log_info "Updating Android build.gradle"
    sed -i '' "s/applicationId \".*\"/applicationId \"$bundle_id\"/g" android/app/build.gradle 2>/dev/null || {
        log_warning "Failed to update Android applicationId"
    }
    log_success "✅ Updated Android applicationId"
else
    log_warning "⚠️ Android build.gradle not found"
fi

# Update AndroidManifest.xml package name
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    log_info "Updating AndroidManifest.xml package"
    sed -i '' "s/package=\".*\"/package=\"$bundle_id\"/g" android/app/src/main/AndroidManifest.xml 2>/dev/null || {
        log_warning "Failed to update AndroidManifest.xml package"
    }
    log_success "✅ Updated AndroidManifest.xml package"
else
    log_warning "⚠️ AndroidManifest.xml not found"
fi

# Update MainActivity.kt package name
if [ -f "android/app/src/main/kotlin/com/example/quikapp22/MainActivity.kt" ]; then
    log_info "Updating MainActivity.kt package"
    # Extract package name from bundle ID
    package_name=$(echo "$bundle_id" | sed 's/\./\//g')
    sed -i '' "s/package com.example.quikapp22/package $bundle_id/g" android/app/src/main/kotlin/com/example/quikapp22/MainActivity.kt 2>/dev/null || {
        log_warning "Failed to update MainActivity.kt package"
    }
    log_success "✅ Updated MainActivity.kt package"
else
    log_warning "⚠️ MainActivity.kt not found"
fi

log_success "✅ Bundle ID update completed successfully"
exit 0 