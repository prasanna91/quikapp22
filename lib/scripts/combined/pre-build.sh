#!/bin/bash

# Combined Pre-Build Script
# Handles pre-build setup for combined workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🚀 Starting Universal Combined Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"
echo "  - Gradle: $(./android/gradlew --version | grep "Gradle" | head -1)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."
flutter clean
rm -rf ~/.gradle/caches/ 2>/dev/null || true
rm -rf .dart_tool/ 2>/dev/null || true
rm -rf ios/Pods/ 2>/dev/null || true
rm -rf ios/build/ 2>/dev/null || true

# Optimize Gradle
echo "⚡ Optimizing Gradle configuration..."
export GRADLE_OPTS="$GRADLE_OPTS"
export GRADLE_DAEMON=true
export GRADLE_PARALLEL=true

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

# Verify Firebase configuration
if [ -n "$FIREBASE_CONFIG_ANDROID" ]; then
  echo "🔥 Android Firebase configuration detected"
else
  echo "⚠️ No Android Firebase configuration provided"
fi

if [ -n "$FIREBASE_CONFIG_IOS" ]; then
  echo "🔥 iOS Firebase configuration detected"
else
  echo "⚠️ No iOS Firebase configuration provided"
fi

# Verify Android keystore configuration
if [ -n "$KEY_STORE_URL" ]; then
  echo "🔐 Android keystore configuration detected"
else
  echo "⚠️ No Android keystore configuration provided"
fi

# Verify iOS signing configuration
if [ -n "$CERT_PASSWORD" ] && [ -n "$PROFILE_URL" ]; then
  echo "🔐 iOS signing configuration detected"
else
  echo "⚠️ Incomplete iOS signing configuration"
fi

# Verify environment
echo "✅ Environment verification completed"

# 🔍 QuikApp Rules Validation for Combined Workflow
echo "🔍 Validating QuikApp Rules Compliance for Combined Workflow..."

# Required field validation (per QuikApp rules)
echo "📋 Validating required fields..."

# App Metadata & Versioning (✅ Required for all workflows)
if [ -z "${APP_ID:-}" ]; then
  echo "❌ APP_ID is required but not set"
  exit 1
fi
if [ -z "${USER_NAME:-}" ]; then
  echo "❌ USER_NAME is required but not set"
  exit 1
fi
if [ -z "${VERSION_NAME:-}" ]; then
  echo "❌ VERSION_NAME is required but not set"
  exit 1
fi
if [ -z "${VERSION_CODE:-}" ]; then
  echo "❌ VERSION_CODE is required but not set"
  exit 1
fi
if [ -z "${APP_NAME:-}" ]; then
  echo "❌ APP_NAME is required but not set"
  exit 1
fi
if [ -z "${ORG_NAME:-}" ]; then
  echo "❌ ORG_NAME is required but not set"
  exit 1
fi
if [ -z "${WEB_URL:-}" ]; then
  echo "❌ WEB_URL is required but not set"
  exit 1
fi
if [ -z "${EMAIL_ID:-}" ]; then
  echo "❌ EMAIL_ID is required but not set"
  exit 1
fi

# Customization Block (✅ Required for combined workflows)
if [ -z "${PKG_NAME:-}" ]; then
  echo "❌ PKG_NAME is required for Android workflows but not set"
  exit 1
fi
if [ -z "${BUNDLE_ID:-}" ]; then
  echo "❌ BUNDLE_ID is required for iOS workflows but not set"
  exit 1
fi

# App Icon Path (⚠️ Optional - will use default if not set)
if [ -z "${APP_ICON_PATH:-}" ]; then
  echo "⚠️ APP_ICON_PATH not set, using default: assets/images/logo.png"
  export APP_ICON_PATH="assets/images/logo.png"
fi

# Splash Screen (✅ Required)
if [ -z "${SPLASH_URL:-}" ]; then
  echo "❌ SPLASH_URL is required but not set"
  exit 1
fi

# Android Keystore (✅ Required for combined workflow)
if [ -z "${KEY_STORE_URL:-}" ]; then
  echo "❌ KEY_STORE_URL is required for combined workflow but not set"
  exit 1
fi
if [ -z "${CM_KEYSTORE_PASSWORD:-}" ]; then
  echo "❌ CM_KEYSTORE_PASSWORD is required for combined workflow but not set"
  exit 1
fi
if [ -z "${CM_KEY_ALIAS:-}" ]; then
  echo "❌ CM_KEY_ALIAS is required for combined workflow but not set"
  exit 1
fi
if [ -z "${CM_KEY_PASSWORD:-}" ]; then
  echo "❌ CM_KEY_PASSWORD is required for combined workflow but not set"
  exit 1
fi

# iOS Signing (✅ Required for combined workflow)
if [ -z "${PROFILE_TYPE:-}" ]; then
  echo "❌ PROFILE_TYPE is required but not set"
  exit 1
fi
if [ -z "${CERT_PASSWORD:-}" ]; then
  echo "❌ CERT_PASSWORD is required but not set"
  exit 1
fi
if [ -z "${PROFILE_URL:-}" ]; then
  echo "❌ PROFILE_URL is required but not set"
  exit 1
fi

# Apple Push & StoreConnect (✅ Required for combined workflow)
if [ -z "${APPLE_TEAM_ID:-}" ]; then
  echo "❌ APPLE_TEAM_ID is required but not set"
  exit 1
fi
if [ -z "${APNS_KEY_ID:-}" ]; then
  echo "❌ APNS_KEY_ID is required but not set"
  exit 1
fi
if [ -z "${APNS_AUTH_KEY_URL:-}" ]; then
  echo "❌ APNS_AUTH_KEY_URL is required but not set"
  exit 1
fi
if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ]; then
  echo "❌ APP_STORE_CONNECT_KEY_IDENTIFIER is required but not set"
  exit 1
fi

# Certificate validation (one of these combinations required)
if [ -z "${CERT_P12_URL:-}" ] && [ -z "${CERT_CER_URL:-}" ]; then
  echo "❌ Either CERT_P12_URL or CERT_CER_URL is required but neither is set"
  exit 1
fi
if [ -z "${CERT_P12_URL:-}" ] && [ -z "${CERT_KEY_URL:-}" ]; then
  echo "❌ CERT_KEY_URL is required when CERT_P12_URL is not provided"
  exit 1
fi

# Firebase validation based on PUSH_NOTIFY
echo "🔍 Validating Firebase configuration..."
if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
  echo "🔔 Push notifications ENABLED - Firebase required for both platforms"
  if [ -z "$FIREBASE_CONFIG_ANDROID" ]; then
    echo "❌ FIREBASE_CONFIG_ANDROID is required when PUSH_NOTIFY is true"
    exit 1
  fi
  if [ -z "$FIREBASE_CONFIG_IOS" ]; then
    echo "❌ FIREBASE_CONFIG_IOS is required when PUSH_NOTIFY is true"
    exit 1
  fi
  echo "✅ Firebase configuration provided for both platforms"
else
  echo "🔕 Push notifications DISABLED - Firebase optional"
fi

# Profile type validation
echo "🔍 Validating profile type: $PROFILE_TYPE"
case "$PROFILE_TYPE" in
  "app-store"|"ad-hoc")
    echo "✅ Valid profile type: $PROFILE_TYPE"
    ;;
  *)
    echo "❌ Invalid profile type: $PROFILE_TYPE"
    echo "   Supported types: app-store, ad-hoc"
    exit 1
    ;;
esac

# Email notification validation (if enabled)
if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
  if [ -z "${EMAIL_SMTP_SERVER:-}" ]; then
    echo "❌ EMAIL_SMTP_SERVER is required when ENABLE_EMAIL_NOTIFICATIONS is true"
    exit 1
  fi
  if [ -z "${EMAIL_SMTP_PORT:-}" ]; then
    echo "❌ EMAIL_SMTP_PORT is required when ENABLE_EMAIL_NOTIFICATIONS is true"
    exit 1
  fi
  if [ -z "${EMAIL_SMTP_USER:-}" ]; then
    echo "❌ EMAIL_SMTP_USER is required when ENABLE_EMAIL_NOTIFICATIONS is true"
    exit 1
  fi
  if [ -z "${EMAIL_SMTP_PASS:-}" ]; then
    echo "❌ EMAIL_SMTP_PASS is required when ENABLE_EMAIL_NOTIFICATIONS is true"
    exit 1
  fi
  echo "✅ Email notification configuration validated"
fi

echo "✅ Combined workflow validation completed" 