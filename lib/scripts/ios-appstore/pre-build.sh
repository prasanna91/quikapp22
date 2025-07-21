#!/bin/bash

# 🍎 iOS App Store Pre-Build Script
# Handles all pre-build setup for iOS App Store builds

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting iOS App Store Pre-Build Setup${NC}"
echo "================================================"

# Verify Xcode and iOS SDK compatibility
echo "🔍 Verifying Xcode and iOS SDK compatibility..."
chmod +x lib/scripts/ios/verify_xcode_sdk.sh
if ./lib/scripts/ios/verify_xcode_sdk.sh; then
  echo "✅ Xcode and iOS SDK verification passed"
else
  echo "❌ Xcode and iOS SDK verification failed"
  exit 1
fi

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
  echo "⚠️ Branding script not found, skipping branding assets"
fi

# Download custom icons from BOTTOMMENU_ITEMS
echo "🎨 Downloading custom icons from BOTTOMMENU_ITEMS..."
if [ -f "lib/scripts/utils/download_custom_icons.sh" ]; then
  chmod +x lib/scripts/utils/download_custom_icons.sh
  if ./lib/scripts/utils/download_custom_icons.sh; then
    echo "✅ Custom icons download completed"
  else
    echo "⚠️ Custom icons download failed, continuing anyway"
  fi
else
  echo "⚠️ Custom icons script not found, skipping custom icons"
fi

# Run comprehensive pre-build validation
echo "🔍 Running comprehensive pre-build validation..."
chmod +x lib/scripts/ios/pre_build_validation.sh
./lib/scripts/ios/pre_build_validation.sh

# Dynamic Info.plist injection from environment variables
echo "📱 Injecting Info.plist values from environment variables..."
chmod +x lib/scripts/ios/inject_info_plist.sh
if ./lib/scripts/ios/inject_info_plist.sh; then
  echo "✅ Info.plist injection completed"
else
  echo "❌ Info.plist injection failed"
  exit 1
fi

# Launch screen fix for iPad multitasking
echo "🖥️ Setting up launch screen for iPad multitasking..."
chmod +x lib/scripts/ios/launch-screen-fix.sh
if ./lib/scripts/ios/launch-screen-fix.sh; then
  echo "✅ Launch screen setup completed"
else
  echo "❌ Launch screen setup failed"
  exit 1
fi

# iOS code signing setup
echo "🔐 Setting up iOS code signing..."
chmod +x lib/scripts/ios-appstore/simple-code-signing.sh
if ./lib/scripts/ios-appstore/simple-code-signing.sh; then
  echo "✅ iOS code signing setup completed"
else
  echo "❌ iOS code signing setup failed"
  exit 1
fi

echo -e "${GREEN}🎉 iOS App Store Pre-Build Setup Completed Successfully!${NC}"
echo "================================================" 