#!/bin/bash

# iOS Ad Hoc Pre-Build Script
# Handles pre-build setup for ios-adhoc workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }


echo "🚀 Starting iOS Akash Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
echo "  - Profile Type: $PROFILE_TYPE"

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."

flutter clean > /dev/null 2>&1 || {
  log_warn "⚠️ flutter clean failed (continuing)"
}

rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

# Optimize Xcode
echo "⚡ Optimizing Xcode configuration..."
export XCODE_FAST_BUILD=true
export COCOAPODS_FAST_INSTALL=true

# Function to run CocoaPods commands
run_cocoapods_commands() {

  # Backup and remove Podfile.lock if it exists
  if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
  else
    log_warn "⚠️ Podfile.lock not found — skipping backup and removal"
  fi

    log_info "📦 Running CocoaPods commands..."

    if ! command -v pod &>/dev/null; then
        log_error "CocoaPods is not installed!"
        exit 1
    fi

    pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }

    log_info "🔄 Running: pod install"
    if pod install > /dev/null 2>&1; then
        log_success "✅ pod install completed successfully"
    else
        log_error "❌ pod install failed"
        popd > /dev/null
        return 1
    fi

    if [ "${RUN_POD_UPDATE:-false}" = "true" ]; then
        log_info "🔄 Running: pod update"
        if ! pod update > /dev/null 2>&1; then
            log_warn "⚠️ pod update had issues (continuing)"
        fi
    fi

    popd > /dev/null

    log_success "✅ CocoaPods commands completed"
}

# Function to echo bundle identifiers for all frameworks and target
echo_bundle_identifiers() {
    log_info "📱 Echoing bundle identifiers for all frameworks and target..."

    echo ""
    echo "🎯 BUNDLE IDENTIFIERS REPORT"
    echo "================================================================="

    # Main app bundle ID
    if [ -f "ios/Runner/Info.plist" ]; then
        main_bundle_id=$(plutil -extract CFBundleIdentifier raw "ios/Runner/Info.plist" 2>/dev/null || echo "NOT_FOUND")
        echo "📱 Main App Bundle ID: $main_bundle_id"
    else
        echo "❌ Main app Info.plist not found"
    fi

    # Xcode project
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        echo ""
        echo "🏗️ Xcode Project Bundle Identifiers:"
        grep -o "PRODUCT_BUNDLE_IDENTIFIER = [^;]*;" "ios/Runner.xcodeproj/project.pbxproj"
    else
        echo "❌ Xcode project file not found"
    fi

    # CocoaPods Info.plists
    if [ -d "ios/Pods" ]; then
        echo ""
        echo "📦 CocoaPods Framework Bundle Identifiers:"
        find "ios/Pods" -name "Info.plist" | while read -r plist; do
            framework_name=$(echo "$plist" | sed 's|.*Pods/\([^/]*\).*|\1|')
            bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "NOT_FOUND")
            echo "   📦 $framework_name: $bundle_id"
        done
    else
        echo "ℹ️ CocoaPods directory not found"
    fi

    echo ""
    echo "================================================================="
    log_success "✅ Bundle identifiers report completed"
}

echo "📝 Generating environment configuration for Dart..."
chmod +x lib/scripts/ios-akash/gen_env_config.sh
if ./lib/scripts/ios-akash/gen_env_config.sh; then
  echo "✅ Environment configuration generated successfully"
else
  echo "❌ Environment configuration generation failed, continuing anyway"
fi

    # Download branding assets (logo, splash, splash background)
    echo "🎨 Downloading branding assets..."
    if [ -f "lib/scripts/ios-akash/branding.sh" ]; then
      chmod +x lib/scripts/ios-akash/branding.sh
      if ./lib/scripts/ios-akash/branding.sh; then
        echo "✅ Branding assets download completed"
      else
        echo "❌ Branding assets download failed"
        exit 1
      fi
    else
      echo "⚠️ Branding script not found, skipping branding assets download"
    fi

    # Download custom icons for bottom menu (if enabled)
    echo "🎨 Downloading custom icons for bottom menu..."
    if [ "${IS_BOTTOMMENU:-false}" = "true" ]; then
      if [ -f "lib/scripts/ios-akash/download_custom_icons.sh" ]; then
        chmod +x lib/scripts/ios-akash/download_custom_icons.sh
        if ./lib/scripts/ios-akash/download_custom_icons.sh; then
          echo "✅ Custom icons download completed"

          # Validate custom icons if BOTTOMMENU_ITEMS contains custom icons
          if [ -n "${BOTTOMMENU_ITEMS:-}" ]; then
            echo "🔍 Validating custom icons..."
            if [ -d "assets/icons" ] && [ "$(ls -A assets/icons 2>/dev/null)" ]; then
              echo "✅ Custom icons found in assets/icons/"
              ls -la assets/icons/ | while read -r line; do
                echo "   $line"
              done
            else
              echo "ℹ️ No custom icons found (using preset icons only)"
            fi
          fi
        else
          echo "❌ Custom icons download failed"
          exit 1
        fi
      else
        echo "⚠️ Custom icons download script not found, skipping..."
      fi
    else
      echo "ℹ️ Bottom menu disabled (IS_BOTTOMMENU=false), skipping custom icons download"
    fi

    echo "✅ Pre-build setup completed successfully"

# Dynamic Info.plist injection from environment variables
echo "📱 Injecting Info.plist values from environment variables..."
chmod +x lib/scripts/ios-akash/inject_info_plist.sh
if ./lib/scripts/ios-akash/inject_info_plist.sh; then
  echo "✅ Info.plist injection completed"
else
  echo "❌ Info.plist injection failed"
  exit 1
fi

    # Make conditional Firebase injection script executable
    chmod +x lib/scripts/ios-akash/conditional_firebase_injection.sh

    # Run conditional Firebase injection based on PUSH_NOTIFY flag
    if ! ./lib/scripts/ios-akash/conditional_firebase_injection.sh; then
        send_email "build_failed" "iOS" "${CM_BUILD_ID:-unknown}" "Conditional Firebase injection failed."
        return 1
    fi

log_info "Building Flutter iOS app..."

    # Determine build configuration based on profile type
   build_mode="release"
   build_config="Release"

    case "${PROFILE_TYPE:-app-store}" in
        "development")
            build_mode="debug"
            build_config="Debug"
            ;;
        "ad-hoc"|"enterprise"|"app-store")
            build_mode="release"
            build_config="Release"
            ;;
    esac

    log_info "Building in $build_mode mode for $PROFILE_TYPE distribution"

# Install Flutter dependencies (including rename package)
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

    run_cocoapods_commands

    echo_bundle_identifiers

# Determine build mode and config
case "$PROFILE_TYPE" in
  development)
    build_mode="debug"
    build_config="Debug"
    ;;
  ad-hoc|enterprise|app-store)
    build_mode="release"
    build_config="Release"
    ;;
  *)
    log_warn "Unknown PROFILE_TYPE '$PROFILE_TYPE', defaulting to release"
    build_mode="release"
    build_config="Release"
    ;;
esac

log_info "📱 Building Flutter iOS app in $build_mode mode..."
flutter build ios --$build_mode --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE" \
  2>&1 | tee flutter_build.log | grep -E "(Building|Error|FAILURE|warning|Warning|error|Exception|\.dart)"

log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration "$build_config" \
  -archivePath build/ios/archive/Runner.xcarchive \
  -allowProvisioningUpdates \
  -destination 'generic/platform=iOS' \
  archive \
  2>&1 | tee xcodebuild_archive.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>$PROFILE_TYPE</string>
  <key>teamID</key>
  <string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
EOF

log_info "📤 Exporting IPA..."
OUTPUT_DIR="${OUTPUT_DIR:-build/ios/output}"
mkdir -p "$OUTPUT_DIR"
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath "$OUTPUT_DIR" \
  -exportOptionsPlist ios/ExportOptions.plist \
  -allowProvisioningUpdates \
  2>&1 | tee xcodebuild_export.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

IPA_PATH=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -n 1)

if [ -f "$IPA_PATH" ]; then
  mv "$IPA_PATH" "$OUTPUT_DIR/$APP_NAME.ipa"
  log_success "✅ IPA created: $OUTPUT_DIR/$APP_NAME.ipa"
else
  log_error "❌ IPA file not found. Build may have failed."
  exit 1
fi


log_success "🎉 iOS build process completed successfully!"
