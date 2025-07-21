#!/bin/bash

# Combined Build Script
# Handles the actual build process for combined workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

echo "🏗️ Starting Universal Combined Build..."

chmod +x lib/scripts/combined/*.sh
chmod +x lib/scripts/utils/*.sh

# Enhanced build with retry logic
MAX_RETRIES=${MAX_RETRIES:-3}
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "🏗️ Build attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"

  if ./lib/scripts/combined/main.sh; then
    echo "✅ Build completed successfully!"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "⚠️ Build failed, retrying in 10 seconds..."
      sleep 10
      flutter clean
    else
      echo "❌ Build failed after $MAX_RETRIES attempts"
      exit 1
    fi
  fi
done

echo "✅ Universal Combined Build completed successfully" 