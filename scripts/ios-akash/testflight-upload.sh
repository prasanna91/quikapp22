#!/bin/bash
set -euo pipefail
trap 'echo "❌ Error at line $LINENO. Exit code: $?" >&2; exit 1' ERR

if [ "${IS_TESTFLIGHT:-false}" != "true" ]; then
  echo "⚠️ IS_TESTFLIGHT is not true. Skipping TestFlight upload."
  exit 0
fi

echo "🚀 Uploading to TestFlight..."

# Required credentials
API_KEY_ID="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
API_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-}"
API_KEY_URL="${APP_STORE_CONNECT_API_KEY:-}"

# Validate credentials
if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ] || [ -z "$API_KEY_URL" ]; then
  echo "❌ Missing App Store Connect API credentials"
  exit 1
fi

# Setup API key
KEY_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$KEY_DIR"
API_KEY_PATH="$KEY_DIR/AuthKey_${API_KEY_ID}.p8"

if [ ! -f "$API_KEY_PATH" ]; then
  curl -L -o "$API_KEY_PATH" "$API_KEY_URL"
  chmod 600 "$API_KEY_PATH"
fi

# Find IPA
IPA_PATH=$(find output/ios -name "*.ipa" | sort | head -n 1)
if [ -z "$IPA_PATH" ] || [ ! -s "$IPA_PATH" ]; then
  echo "❌ No valid IPA found at: $IPA_PATH"
  exit 1
fi

echo "📦 Uploading: $IPA_PATH"

# Upload via xcrun (App Store Connect API)
xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$API_KEY_ID" \
  --apiIssuer "$API_ISSUER_ID" \
  --verbose

echo "✅ Successfully uploaded to TestFlight!"
