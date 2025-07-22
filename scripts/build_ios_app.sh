#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD] ❌ $1"; }

log "🏗️ Building iOS App"

# Step 1: Generate dynamic Podfile with all fixes
log_info "Step 1: Generating dynamic Podfile"
chmod +x scripts/generate_dynamic_podfile.sh
./scripts/generate_dynamic_podfile.sh

# Step 2: Handle Firebase dependencies
log_info "Step 2: Handling Firebase dependencies"
chmod +x scripts/fix_firebase_dependencies.sh
./scripts/fix_firebase_dependencies.sh

# Step 3: Handle speech_to_text dependency issue
log_info "Step 3: Handling speech_to_text dependency issue"
if [ -f "scripts/fix_speech_to_text_dependency.sh" ]; then
    chmod +x scripts/fix_speech_to_text_dependency.sh
    ./scripts/fix_speech_to_text_dependency.sh
else
    log_warning "fix_speech_to_text_dependency.sh not found, using fallback approach"
    
    # Check if speech_to_text is being used
    if grep -q "speech_to_text" pubspec.yaml; then
        log_warning "speech_to_text plugin detected - this may cause CwlCatchException to be reinstalled"
        log_info "Temporarily removing speech_to_text to prevent CwlCatchException issues"
        
        # Create backup
        cp pubspec.yaml pubspec.yaml.bak
        
        # Remove speech_to_text from pubspec.yaml
        sed -i '' '/speech_to_text/d' pubspec.yaml
        sed -i '' '/speech_to_text_platform_interface/d' pubspec.yaml
        
        log_success "Temporarily removed speech_to_text from pubspec.yaml"
        log_warning "Note: speech_to_text functionality will be disabled in this build"
    fi
fi

# Step 4: Clean and install pods with dynamic Podfile
log_info "Step 4: Installing pods with dynamic Podfile"

cd ios

# Clean existing pods
if [ -d "Pods" ]; then
    log_info "Cleaning existing pods"
    rm -rf Pods
    rm -f Podfile.lock
fi

# Install pods with the dynamically generated Podfile
log_info "Installing pods with comprehensive fixes"
pod install --repo-update

# Step 4.5: Apply comprehensive GoogleUtilities header fix
log_info "Step 4.5: Applying comprehensive GoogleUtilities header fix"
cd ..
chmod +x scripts/fix_google_utilities_headers_comprehensive.sh
./scripts/fix_google_utilities_headers_comprehensive.sh
cd ios

cd ..

# Step 5: Build Flutter app
log_info "Step 5: Building Flutter app"
flutter build ios --release --no-codesign

# Step 6: Create archive with proper signing
log_info "Step 6: Creating iOS archive"

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

# Step 7: Export IPA
log_info "Step 7: Exporting IPA"

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

# Step 8: Restore speech_to_text if it was temporarily removed
log_info "Step 8: Restoring speech_to_text plugin"
if [ -f "pubspec.yaml.bak" ]; then
    log_info "Restoring speech_to_text plugin..."
    cp pubspec.yaml.bak pubspec.yaml
    flutter pub get
    log_success "✅ speech_to_text plugin restored"
else
    log_info "No speech_to_text backup found, skipping restoration"
fi

# Step 9: Restore original Podfile if needed
log_info "Step 9: Restoring original Podfile"
if [ -f "ios/Podfile.original" ]; then
    log_info "Restoring original Podfile..."
    cp ios/Podfile.original ios/Podfile
    log_success "✅ Original Podfile restored"
else
    log_info "No original Podfile backup found, keeping dynamic Podfile"
fi

log_success "✅ iOS build completed successfully"
exit 0 