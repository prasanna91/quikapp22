#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ❌ $1"; }

log "🏗️ Building iOS App"

# Step 1: Fix iOS build issues
log_info "Step 1: Fixing iOS build issues"
chmod +x scripts/fix_ios_build_issues.sh
./scripts/fix_ios_build_issues.sh

# Step 2: Build Flutter app
log_info "Step 2: Building Flutter app"
flutter build ios --release --no-codesign

# Step 3: Create archive with proper signing
log_info "Step 3: Creating iOS archive"

# Create build directory if it doesn't exist
mkdir -p build

# Build the archive with automatic signing
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -sdk iphoneos \
  -configuration Release archive \
  -archivePath build/Runner.xcarchive \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE="Automatic" \
  CODE_SIGN_IDENTITY="Apple Development" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration

# Check if archive was created successfully
if [ ! -f "build/Runner.xcarchive" ]; then
    log_error "❌ Archive was not created successfully"
    log_info "Checking for build errors..."
    
    # Try to get more detailed error information
    if [ -f "ios/build.log" ]; then
        log_info "Build log contents:"
        tail -50 ios/build.log
    fi
    
    exit 1
fi

log_success "✅ iOS archive created successfully: build/Runner.xcarchive"

# Step 4: Export IPA
log_info "Step 4: Exporting IPA"

# Ensure exportOptions.plist exists
if [ ! -f "scripts/exportOptions.plist" ]; then
    log_warning "exportOptions.plist not found, creating default"
    mkdir -p scripts
    
    cat > scripts/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${PROFILE_TYPE:-app-store}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>${APP_NAME}</string>
    </dict>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
fi

# Create export directory
mkdir -p build/export

# Export the IPA
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist scripts/exportOptions.plist \
  -exportPath build/export \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration

# Check if IPA was created successfully
if [ ! -f "build/export/Runner.ipa" ]; then
    log_error "❌ IPA was not created successfully"
    log_info "Checking export directory contents:"
    ls -la build/export/
    exit 1
fi

log_success "✅ IPA created successfully: build/export/Runner.ipa"

# Step 5: Restore speech_to_text if it was temporarily removed
log_info "Step 5: Restoring speech_to_text plugin"
if [ -f "pubspec.yaml.bak" ]; then
    log_info "Restoring speech_to_text plugin..."
    cp pubspec.yaml.bak pubspec.yaml
    flutter pub get
    log_success "✅ speech_to_text plugin restored"
else
    log_info "No speech_to_text backup found, skipping restoration"
fi

log_success "✅ iOS build completed successfully"
exit 0 