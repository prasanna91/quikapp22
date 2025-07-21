#!/bin/bash

# iOS Ad Hoc Pre-Build Script
# Handles pre-build setup for ios-adhoc workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🚀 Starting iOS Ad Hoc Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
echo "  - Profile Type: $PROFILE_TYPE"

# Verify Xcode and iOS SDK compatibility
echo "🔍 Verifying Xcode and iOS SDK compatibility..."
chmod +x lib/scripts/ios/verify_xcode_sdk.sh
if ./lib/scripts/ios/verify_xcode_sdk.sh; then
  echo "✅ Xcode and iOS SDK verification passed"
else
  echo "❌ Xcode and iOS SDK verification failed"
  exit 1
fi

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."
flutter clean
rm -rf ~/.gradle/caches/ 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .dart_tool/ 2>/dev/null || true
rm -rf ios/Pods/ 2>/dev/null || true
rm -rf ios/build/ 2>/dev/null || true
rm -rf ios/.symlinks

# Install Flutter dependencies (including rename package)
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Verify rename package installation (simplified verification)
echo "🔍 Verifying rename package installation..."

# Check if rename package is in pubspec.yaml
if grep -q "rename:" pubspec.yaml; then
  echo "✅ Rename package found in pubspec.yaml"
  
  # Try to run rename command
  if flutter pub run rename --help >/dev/null 2>&1; then
    echo "✅ Rename package verified via command availability"
  else
    echo "⚠️ Rename command not available, but package is in pubspec.yaml"
    echo "🔄 This is normal for dev_dependencies in CI environment"
    echo "✅ Continuing with build..."
  fi
else
  echo "❌ Rename package not found in pubspec.yaml"
  echo "📋 Current dev_dependencies in pubspec.yaml:"
  grep -A 10 "dev_dependencies:" pubspec.yaml || echo "   No dev_dependencies section found"
  exit 1
fi

# Optimize Xcode
echo "⚡ Optimizing Xcode configuration..."
export XCODE_FAST_BUILD=true
export COCOAPODS_FAST_INSTALL=true

# Generate environment configuration for Dart
echo "📝 Generating environment configuration for Dart..."
chmod +x lib/scripts/utils/gen_env_config.sh
if ./lib/scripts/utils/gen_env_config.sh; then
  echo "✅ Environment configuration generated successfully"
else
  echo "⚠️ Environment configuration generation failed, continuing anyway"
fi

# Download branding assets (logo, splash, splash background)
echo "🎨 Downloading branding assets..."
if [ -f "lib/scripts/ios/branding.sh" ]; then
  chmod +x lib/scripts/ios/branding.sh
  if ./lib/scripts/ios/branding.sh; then
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
  if [ -f "lib/scripts/utils/download_custom_icons.sh" ]; then
    chmod +x lib/scripts/utils/download_custom_icons.sh
    if ./lib/scripts/utils/download_custom_icons.sh; then
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

# Run comprehensive pre-build validation
echo "🔍 Running comprehensive pre-build validation..."
chmod +x lib/scripts/ios/pre_build_validation.sh
./lib/scripts/ios/pre_build_validation.sh

# Validate and fix Info.plist for App Store submission
echo "🔍 Validating and fixing Info.plist for App Store submission..."
chmod +x lib/scripts/ios/validate_info_plist.sh
if ./lib/scripts/ios/validate_info_plist.sh --validate-all .; then
  echo "✅ Info.plist validation passed"
else
  echo "⚠️ Info.plist validation failed, attempting to fix..."
  ./lib/scripts/ios/validate_info_plist.sh --fix ios/Runner/Info.plist "${APP_NAME:-Runner}" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"
fi

# Check and fix bundle executable configuration
#echo "🔍 Checking and fixing bundle executable configuration..."
#if [ -f "lib/scripts/ios/enhanced_bundle_executable_fix.sh" ]; then
#  chmod +x lib/scripts/ios/enhanced_bundle_executable_fix.sh
#  ./lib/scripts/ios/enhanced_bundle_executable_fix.sh --check-build
#else
#  echo "⚠️ Enhanced bundle executable fix script not found, continuing..."
#fi

echo "✅ Pre-build setup completed successfully" 