#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PERMISSIONS] ❌ $1"; }

# Permission flags with dynamic environment variable support
IS_CAMERA=${IS_CAMERA:-"false"}
IS_LOCATION=${IS_LOCATION:-"false"}
IS_MIC=${IS_MIC:-"false"}
IS_NOTIFICATION=${IS_NOTIFICATION:-"false"}
IS_CONTACT=${IS_CONTACT:-"false"}
IS_BIOMETRIC=${IS_BIOMETRIC:-"false"}
IS_CALENDAR=${IS_CALENDAR:-"false"}
IS_STORAGE=${IS_STORAGE:-"false"}

log "🔐 Starting iOS permissions configuration"
log "📋 Permission flags:"
log "   Camera: $IS_CAMERA"
log "   Location: $IS_LOCATION"
log "   Microphone: $IS_MIC"
log "   Notification: $IS_NOTIFICATION"
log "   Contact: $IS_CONTACT"
log "   Biometric: $IS_BIOMETRIC"
log "   Calendar: $IS_CALENDAR"
log "   Storage: $IS_STORAGE"

INFO_PLIST_PATH="ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST_PATH" ]; then
  log_error "Info.plist not found at $INFO_PLIST_PATH"
  exit 1
fi

log_info "📝 Updating Info.plist with dynamic permissions"

# Create backup
cp "$INFO_PLIST_PATH" "$INFO_PLIST_PATH.bak"
log_success "Created backup of Info.plist"

# Function to add permission to Info.plist
add_permission() {
    local permission="$1"
    local description="$2"
    
    # Check if permission already exists
    if ! grep -q "<key>$permission</key>" "$INFO_PLIST_PATH"; then
        log_info "Adding $permission permission"
        
        # Find the position to insert (after the last </dict> before </plist>)
        local temp_file=$(mktemp)
        
        # Insert permission before the closing </dict> tag
        awk -v perm="$permission" -v desc="$description" '
        /<\/dict>/ {
            if (!added) {
                print "	<key>" perm "</key>"
                print "	<string>" desc "</string>"
                added = 1
            }
        }
        { print }
        ' "$INFO_PLIST_PATH" > "$temp_file"
        
        mv "$temp_file" "$INFO_PLIST_PATH"
    else
        log_info "Permission $permission already exists"
    fi
}

# Add permissions based on flags
if [ "$IS_CAMERA" = "true" ]; then
    add_permission "NSCameraUsageDescription" "This app needs camera access to take photos and videos"
fi

if [ "$IS_LOCATION" = "true" ]; then
    add_permission "NSLocationWhenInUseUsageDescription" "This app needs location access to provide location-based services"
    add_permission "NSLocationAlwaysAndWhenInUseUsageDescription" "This app needs location access to provide location-based services"
    add_permission "NSLocationAlwaysUsageDescription" "This app needs location access to provide location-based services"
fi

if [ "$IS_MIC" = "true" ]; then
    add_permission "NSMicrophoneUsageDescription" "This app needs microphone access to record audio"
fi

if [ "$IS_NOTIFICATION" = "true" ]; then
    # Notifications are handled by the app itself, no special permission needed
    log_info "Notification permissions are handled by the app"
fi

if [ "$IS_CONTACT" = "true" ]; then
    add_permission "NSContactsUsageDescription" "This app needs contact access to manage your contacts"
fi

if [ "$IS_BIOMETRIC" = "true" ]; then
    add_permission "NSFaceIDUsageDescription" "This app uses Face ID for secure authentication"
fi

if [ "$IS_CALENDAR" = "true" ]; then
    add_permission "NSCalendarsUsageDescription" "This app needs calendar access to manage your events"
fi

if [ "$IS_STORAGE" = "true" ]; then
    add_permission "NSPhotoLibraryUsageDescription" "This app needs photo library access to save and share images"
    add_permission "NSPhotoLibraryAddUsageDescription" "This app needs photo library access to save images"
    add_permission "NSDocumentsFolderUsageDescription" "This app needs document folder access to save files"
fi

# Verify the plist is valid
log_info "🔍 Verifying Info.plist..."
if plutil -lint "$INFO_PLIST_PATH" > /dev/null 2>&1; then
    log_success "Info.plist is valid"
else
    log_error "Info.plist validation failed, restoring backup"
    cp "$INFO_PLIST_PATH.bak" "$INFO_PLIST_PATH"
    exit 1
fi

# Clean up backup
rm "$INFO_PLIST_PATH.bak" || true

log_success "iOS permissions configuration completed successfully"
exit 0 