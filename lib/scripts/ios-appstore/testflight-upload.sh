#!/bin/bash

# iOS App Store TestFlight Upload Script
# Handles TestFlight upload using App Store Connect API credentials

set -euo pipefail
trap 'echo "\u274c Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

if [ "${IS_TESTFLIGHT:-false}" = "true" ]; then
  echo "\U0001F680 Uploading IPA to TestFlight using App Store Connect API credentials..."
  
  # Required variables
  API_KEY_ID="${APP_STORE_CONNECT_KEY_IDENTIFIER:-}"
  API_ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-}"
  API_KEY_URL="${APP_STORE_CONNECT_API_KEY_PATH:-}"

  if [ -z "$API_KEY_ID" ] || [ -z "$API_ISSUER_ID" ] || [ -z "$API_KEY_URL" ]; then
    echo "\u274c Missing App Store Connect API credentials."
    echo "   APP_STORE_CONNECT_KEY_IDENTIFIER: $API_KEY_ID"
    echo "   APP_STORE_CONNECT_ISSUER_ID: $API_ISSUER_ID"
    echo "   APP_STORE_CONNECT_API_KEY_PATH: $API_KEY_URL"
    exit 1
  fi

  # Create private keys directory
  echo "\U0001F4C1 Setting up API key directory..."
  PRIVATE_KEYS_DIR="$HOME/.appstoreconnect/private_keys"
  mkdir -p "$PRIVATE_KEYS_DIR"
  echo "\u2705 Created directory: $PRIVATE_KEYS_DIR"

  # Download API key file
  echo "\U0001F4E5 Downloading API key file..."
  API_KEY_FILENAME="AuthKey_${API_KEY_ID}.p8"
  API_KEY_PATH="$PRIVATE_KEYS_DIR/$API_KEY_FILENAME"
  
  if curl -L -o "$API_KEY_PATH" "$API_KEY_URL" 2>/dev/null; then
    echo "\u2705 Downloaded API key to: $API_KEY_PATH"
    chmod 600 "$API_KEY_PATH"
    echo "\u2705 Set proper permissions on API key file"
  else
    echo "\u274c Failed to download API key from: $API_KEY_URL"
    echo "\U0001F50D Checking if API key URL is accessible..."
    curl -I "$API_KEY_URL" 2>/dev/null || echo "\u26A0\uFE0F API key URL not accessible"
    exit 1
  fi

  # Find the largest valid IPA in output/ios/ (not just the latest)
  IPA_PATH=""
  IPA_SIZE=0
  for ipa in output/ios/*.ipa; do
    if [ -f "$ipa" ]; then
      size=$(stat -f%z "$ipa" 2>/dev/null || stat -c%s "$ipa" 2>/dev/null || echo "0")
      if [ "$size" -gt "$IPA_SIZE" ]; then
        IPA_PATH="$ipa"
        IPA_SIZE="$size"
      fi
    fi
  done

  if [ -z "$IPA_PATH" ]; then
    echo "\u274c No IPA file found in output/ios/"
    exit 1
  fi

  echo "\U0001F4E6 IPA to upload: $IPA_PATH"
  echo "\U0001F4CB IPA file size: $IPA_SIZE bytes"

  # Validate IPA file size (require at least 1MB for valid IPA)
  if [ "$IPA_SIZE" -lt 1000000 ]; then
    echo "\u274c IPA file is too small ($IPA_SIZE bytes) - likely corrupted"
    echo "\U0001F527 This indicates the IPA export process failed"
    exit 1
  fi

  # Validate IPA structure before upload
  echo "\U0001F50D Validating IPA structure before upload..."
  if [ -f "lib/scripts/ios/app_store_ready_check.sh" ]; then
    chmod +x "lib/scripts/ios/app_store_ready_check.sh"
    if ./lib/scripts/ios/app_store_ready_check.sh --validate "$IPA_PATH" "${BUNDLE_ID:-com.example.app}" "${VERSION_NAME:-1.0.0}" "${VERSION_CODE:-1}"; then
      echo "\u2705 IPA structure validation passed"
    else
      echo "\u274c IPA structure validation failed"
      exit 1
    fi
  fi

  # Proceed with upload (insert your upload logic here)
  echo "\U0001F680 Ready to upload $IPA_PATH to TestFlight!"
  # ... (rest of upload logic) ...
fi 