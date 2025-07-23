#!/usr/bin/env bash

# Simplified iOS Build Script
# This script uses a simple Podfile approach to avoid GoogleUtilities header issues

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[IOS_BUILD] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[IOS_BUILD] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[IOS_BUILD] $1${NC}"
}

log_error() {
    echo -e "${RED}[IOS_BUILD] $1${NC}"
}

# Main build function
main() {
    log_info "🏗️ Building iOS App (Simplified Approach)"
    
    # Step 1: Generate simple Podfile
    log_info "🔍 Step 1: Generating simple Podfile"
    chmod +x scripts/generate_simple_podfile.sh
    ./scripts/generate_simple_podfile.sh
    
    # Step 2: Handle Firebase dependencies
    log_info "🔍 Step 2: Handling Firebase dependencies"
    chmod +x scripts/fix_firebase_dependencies.sh
    ./scripts/fix_firebase_dependencies.sh
    
    # Step 3: Handle speech_to_text dependency issue
    log_info "🔍 Step 3: Handling speech_to_text dependency issue"
    
    # Backup pubspec.yaml
    if [ -f "pubspec.yaml" ]; then
        cp pubspec.yaml pubspec.yaml.backup
    fi
    
    # Temporarily remove speech_to_text to prevent CwlCatchException issues
    if grep -q "speech_to_text:" pubspec.yaml; then
        log_warning "⚠️ speech_to_text plugin detected - temporarily removing to prevent CwlCatchException dependency"
        sed -i.bak '/speech_to_text:/d' pubspec.yaml
        sed -i.bak '/speech_to_text_platform_interface:/d' pubspec.yaml
        log_success "✅ Temporarily removed speech_to_text from pubspec.yaml"
        
        # Update dependencies
        log_info "🔍 Running flutter pub get to update dependencies"
        flutter pub get
    fi
    
    # Step 4: Clean and install pods
    log_info "🔍 Step 4: Installing pods with simple Podfile"
    
    cd ios
    
    # Clean existing pods
    if [ -d "Pods" ]; then
        log_info "Cleaning existing pods"
        rm -rf Pods
        rm -f Podfile.lock
    fi
    
    # Install pods with the simple Podfile
    log_info "Installing pods with simple configuration"
    pod install --repo-update --verbose
    
    cd ..
    
    # Step 5: Build Flutter app
    log_info "🔍 Step 5: Building Flutter app"
    flutter build ios --release --no-codesign
    
    # Step 6: Create archive with proper signing
    log_info "🔍 Step 6: Creating iOS archive"
    
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
        exit 1
    fi
    
    log_success "✅ iOS archive created successfully: build/Runner.xcarchive"
    
    # Step 7: Export IPA
    log_info "🔍 Step 7: Exporting IPA"
    
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
    
    # Step 8: Restore speech_to_text (if it was removed)
    log_info "🔍 Step 8: Restoring speech_to_text dependency"
    if [ -f "pubspec.yaml.backup" ]; then
        log_info "Restoring original pubspec.yaml"
        mv pubspec.yaml.backup pubspec.yaml
        log_success "✅ Original pubspec.yaml restored"
    fi
    
    # Step 9: Restore original Podfile (if it exists)
    log_info "🔍 Step 9: Restoring original Podfile"
    if [ -f "ios/Podfile.original" ]; then
        log_info "Restoring original Podfile"
        mv ios/Podfile.original ios/Podfile
        log_success "✅ Original Podfile restored"
    fi
    
    log_success "🎉 iOS build completed successfully!"
    log_info "📦 IPA file: build/export/Runner.ipa"
    log_info "📁 Archive: build/Runner.xcarchive"
}

# Error handling
handle_error() {
    log_error "❌ Build failed at step: $1"
    
    # Restore files if they exist
    if [ -f "pubspec.yaml.backup" ]; then
        mv pubspec.yaml.backup pubspec.yaml
        log_info "Restored pubspec.yaml"
    fi
    
    if [ -f "ios/Podfile.original" ]; then
        mv ios/Podfile.original ios/Podfile
        log_info "Restored Podfile"
    fi
    
    exit 1
}

# Set error trap
trap 'handle_error "Unknown"' ERR

# Run main function
main

log_success "✅ ✅ iOS build process completed successfully" 