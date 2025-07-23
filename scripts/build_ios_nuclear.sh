#!/usr/bin/env bash

# Nuclear iOS Build Script
# This script uses the nuclear GoogleUtilities fix for guaranteed success

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[NUCLEAR_BUILD] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[NUCLEAR_BUILD] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[NUCLEAR_BUILD] $1${NC}"
}

log_error() {
    echo -e "${RED}[NUCLEAR_BUILD] $1${NC}"
}

# Main build function
main() {
    log_info "🚀 Nuclear iOS Build Starting"
    log_warning "⚠️ This uses aggressive fixes to bypass GoogleUtilities issues"
    
    # Step 1: Apply nuclear GoogleUtilities fix
    log_info "🔍 Step 1: Applying Nuclear GoogleUtilities Fix"
    chmod +x scripts/nuclear_google_utilities_fix.sh
    ./scripts/nuclear_google_utilities_fix.sh
    
    # Step 2: Handle speech_to_text dependency issue
    log_info "🔍 Step 2: Handling speech_to_text dependency"
    
    # Backup pubspec.yaml
    if [ -f "pubspec.yaml" ]; then
        cp pubspec.yaml pubspec.yaml.backup
    fi
    
    # Temporarily remove speech_to_text to prevent CwlCatchException issues
    if grep -q "speech_to_text:" pubspec.yaml; then
        log_warning "⚠️ Temporarily removing speech_to_text to prevent CwlCatchException issues"
        sed -i.bak '/speech_to_text:/d' pubspec.yaml
        sed -i.bak '/speech_to_text_platform_interface:/d' pubspec.yaml
        log_success "✅ Temporarily removed speech_to_text from pubspec.yaml"
        
        # Update dependencies
        log_info "🔍 Running flutter pub get to update dependencies"
        flutter pub get
    fi
    
    # Step 3: Nuclear pod install
    log_info "🔍 Step 3: Nuclear Pod Install"
    
    cd ios
    
    # The nuclear fix already cleaned everything, now install
    log_info "Installing pods with nuclear configuration..."
    
    # Use specific pod install flags for maximum compatibility
    pod install \
        --repo-update \
        --verbose \
        --clean-install \
        --deployment
    
    cd ..
    
    # Step 4: Verify pod installation
    log_info "🔍 Step 4: Verifying pod installation"
    
    if [ ! -f "ios/Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig" ]; then
        log_error "❌ Pod installation verification failed"
        exit 1
    fi
    
    log_success "✅ Pod installation verified"
    
    # Step 5: Build Flutter app
    log_info "🔍 Step 5: Building Flutter app"
    
    # Clean Flutter build
    flutter clean
    flutter pub get
    
    # Build iOS with specific flags
    flutter build ios \
        --release \
        --no-codesign \
        --no-tree-shake-icons \
        --dart-define=FLUTTER_WEB_USE_SKIA=true
    
    # Step 6: Create archive with proper signing
    log_info "🔍 Step 6: Creating iOS archive"
    
    # Create build directory if it doesn't exist
    mkdir -p build
    
    # Build the archive with automatic signing and specific settings
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
      ENABLE_BITCODE=NO \
      STRIP_BITCODE_FROM_COPIED_FILES=NO \
      -allowProvisioningUpdates \
      -allowProvisioningDeviceRegistration \
      -quiet
    
    # Check if archive was created successfully
    if [ ! -d "build/Runner.xcarchive" ]; then
        log_error "❌ Archive was not created successfully"
        
        # Try to get build logs
        log_info "Checking for build logs..."
        find . -name "*.log" -type f -exec tail -20 {} \;
        
        exit 1
    fi
    
    log_success "✅ iOS archive created successfully: build/Runner.xcarchive"
    
    # Step 7: Export IPA
    log_info "🔍 Step 7: Exporting IPA"
    
    # Create nuclear exportOptions.plist
    mkdir -p scripts
    cat > scripts/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${PROFILE_TYPE:-app-store}</string>
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
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF
    
    # Create export directory
    mkdir -p build/export
    
    # Export the IPA with specific settings
    xcodebuild -exportArchive \
      -archivePath build/Runner.xcarchive \
      -exportOptionsPlist scripts/exportOptions.plist \
      -exportPath build/export \
      -allowProvisioningUpdates \
      -allowProvisioningDeviceRegistration \
      -quiet
    
    # Check if IPA was created successfully
    IPA_FILE=$(find build/export -name "*.ipa" | head -1)
    if [ -z "$IPA_FILE" ]; then
        log_error "❌ IPA was not created successfully"
        log_info "Export directory contents:"
        ls -la build/export/
        exit 1
    fi
    
    log_success "✅ IPA created successfully: $IPA_FILE"
    
    # Step 8: Restore speech_to_text (if it was removed)
    log_info "🔍 Step 8: Restoring speech_to_text dependency"
    if [ -f "pubspec.yaml.backup" ]; then
        log_info "Restoring original pubspec.yaml"
        mv pubspec.yaml.backup pubspec.yaml
        log_success "✅ Original pubspec.yaml restored"
    fi
    
    log_success "🎉 Nuclear iOS build completed successfully!"
    log_info "📦 IPA file: $IPA_FILE"
    log_info "📁 Archive: build/Runner.xcarchive"
}

# Error handling
handle_error() {
    log_error "❌ Nuclear build failed at step: $1"
    
    # Restore files if they exist
    if [ -f "pubspec.yaml.backup" ]; then
        mv pubspec.yaml.backup pubspec.yaml
        log_info "Restored pubspec.yaml"
    fi
    
    # Show recent logs for debugging
    log_info "Recent build logs:"
    find . -name "*.log" -type f -newer pubspec.yaml 2>/dev/null | head -3 | xargs tail -10
    
    exit 1
}

# Set error trap
trap 'handle_error "Unknown"' ERR

# Run main function
main

log_success "🚀 🚀 Nuclear iOS build process completed successfully!" 