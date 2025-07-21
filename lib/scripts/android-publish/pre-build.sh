#!/bin/bash

# Android Publish Pre-Build Script
# Handles pre-build setup for android-publish workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🚀 Starting Android Publish Pre-Build Setup..."

# Environment verification
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Gradle: $(./android/gradlew --version | grep "Gradle" | head -1)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."
flutter clean
rm -rf ~/.gradle/caches/ 2>/dev/null || true
rm -rf .dart_tool/ 2>/dev/null || true

# Optimize Gradle
echo "⚡ Optimizing Gradle configuration..."
export GRADLE_OPTS="$GRADLE_OPTS"
export GRADLE_DAEMON=true
export GRADLE_PARALLEL=true

# Generate environment configuration for Dart
echo "📝 Generating environment configuration for Dart..."
chmod +x lib/scripts/utils/gen_env_config.sh
if ./lib/scripts/utils/gen_env_config.sh; then
  echo "✅ Environment configuration generated successfully"
else
  echo "⚠️ Environment configuration generation failed, continuing anyway"
fi

# Verify Firebase configuration
if [ -n "$FIREBASE_CONFIG_ANDROID" ]; then
  echo "🔥 Firebase configuration detected"
else
  echo "⚠️ No Firebase configuration provided"
fi

# Verify keystore configuration
if [ -n "$KEY_STORE_URL" ]; then
  echo "🔐 Keystore configuration detected"
else
  echo "⚠️ No keystore configuration provided"
fi

# Verify environment
echo "✅ Environment verification completed"

# Make all scripts executable
echo "🔧 Making scripts executable..."
chmod +x lib/scripts/android/*.sh
chmod +x lib/scripts/utils/*.sh

echo "✅ Pre-build setup completed successfully" 