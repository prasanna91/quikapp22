#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ❌ $1"; }

log "⚙️ Configuring App Permissions"

# Function to add permission to iOS Info.plist
add_ios_permission() {
    local permission="$1"
    local description="$2"
    local plist="ios/Runner/Info.plist"
    
    if [ -f "$plist" ]; then
        log_info "Adding iOS permission: $permission"
        plutil -insert "$permission" -string "$description" "$plist" 2>/dev/null || {
            log_warning "Failed to add iOS permission: $permission"
        }
    fi
}

# Function to add permission to Android AndroidManifest.xml
add_android_permission() {
    local permission="$1"
    local manifest="android/app/src/main/AndroidManifest.xml"
    
    if [ -f "$manifest" ]; then
        log_info "Adding Android permission: $permission"
        # Check if permission already exists
        if ! grep -q "$permission" "$manifest"; then
            # Add permission before the closing </manifest> tag
            sed -i '' "s/<\/manifest>/    <uses-permission android:name=\"$permission\" \/>\n<\/manifest>/" "$manifest" 2>/dev/null || {
                log_warning "Failed to add Android permission: $permission"
            }
        else
            log_info "Android permission already exists: $permission"
        fi
    fi
}

# iOS Permissions
if [ "$IS_CAMERA" = "true" ]; then
    add_ios_permission "NSCameraUsageDescription" "This app needs camera access to take photos and videos"
    add_android_permission "android.permission.CAMERA"
fi

if [ "$IS_LOCATION" = "true" ]; then
    add_ios_permission "NSLocationWhenInUseUsageDescription" "This app needs location access to provide location-based services"
    add_ios_permission "NSLocationAlwaysAndWhenInUseUsageDescription" "This app needs location access to provide location-based services"
    add_ios_permission "NSLocationAlwaysUsageDescription" "This app needs location access to provide location-based services"
    add_android_permission "android.permission.ACCESS_FINE_LOCATION"
    add_android_permission "android.permission.ACCESS_COARSE_LOCATION"
fi

if [ "$IS_MIC" = "true" ]; then
    add_ios_permission "NSMicrophoneUsageDescription" "This app needs microphone access to record audio"
    add_android_permission "android.permission.RECORD_AUDIO"
fi

if [ "$IS_NOTIFICATION" = "true" ]; then
    add_android_permission "android.permission.POST_NOTIFICATIONS"
fi

if [ "$IS_CONTACT" = "true" ]; then
    add_ios_permission "NSContactsUsageDescription" "This app needs contact access to manage your contacts"
    add_android_permission "android.permission.READ_CONTACTS"
    add_android_permission "android.permission.WRITE_CONTACTS"
fi

if [ "$IS_BIOMETRIC" = "true" ]; then
    add_ios_permission "NSFaceIDUsageDescription" "This app uses Face ID for secure authentication"
    add_android_permission "android.permission.USE_BIOMETRIC"
    add_android_permission "android.permission.USE_FINGERPRINT"
fi

if [ "$IS_CALENDAR" = "true" ]; then
    add_ios_permission "NSCalendarsUsageDescription" "This app needs calendar access to manage your events"
    add_android_permission "android.permission.READ_CALENDAR"
    add_android_permission "android.permission.WRITE_CALENDAR"
fi

if [ "$IS_STORAGE" = "true" ]; then
    add_ios_permission "NSPhotoLibraryUsageDescription" "This app needs photo library access to save and share images"
    add_ios_permission "NSPhotoLibraryAddUsageDescription" "This app needs photo library access to save images"
    add_ios_permission "NSDocumentsFolderUsageDescription" "This app needs document folder access to save files"
    add_android_permission "android.permission.READ_EXTERNAL_STORAGE"
    add_android_permission "android.permission.WRITE_EXTERNAL_STORAGE"
fi

# Additional Android permissions for basic functionality
add_android_permission "android.permission.INTERNET"
add_android_permission "android.permission.ACCESS_NETWORK_STATE"
add_android_permission "android.permission.WAKE_LOCK"

log_success "✅ Permissions configuration completed successfully"
exit 0 