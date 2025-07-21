#!/bin/bash

# iOS Workflow Verification Runner
# Purpose: Easy way to run comprehensive verification of iOS build system
# Usage: ./run_verification.sh [profile_type] [firebase_enabled]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "🔍 iOS Workflow Verification Runner"
echo "📁 Project Root: $PROJECT_ROOT"
echo "🎯 Testing iOS build system with app-store and ad-hoc profiles"

# Configuration
PROFILE_TYPE="${1:-app-store}"
FIREBASE_ENABLED="${2:-true}"
OUTPUT_DIR="$PROJECT_ROOT/output/verification"

# Set environment variables for verification
export BUNDLE_ID="${BUNDLE_ID:-com.twinklub.twinklub}"
export APP_NAME="${APP_NAME:-Twinklub App}"
export VERSION_NAME="${VERSION_NAME:-1.0.6}"
export VERSION_CODE="${VERSION_CODE:-50}"
export PUSH_NOTIFY="$FIREBASE_ENABLED"
export PROFILE_TYPE="$PROFILE_TYPE"

# Firebase configuration (mock for testing)
if [ "$FIREBASE_ENABLED" = "true" ]; then
    export FIREBASE_CONFIG_IOS="${FIREBASE_CONFIG_IOS:-https://raw.githubusercontent.com/prasanna91/QuikApp/main/GoogleService-Info.plist}"
fi

# Email configuration (optional)
export ENABLE_EMAIL_NOTIFICATIONS="${ENABLE_EMAIL_NOTIFICATIONS:-false}"

# Change to project root
cd "$PROJECT_ROOT"

echo ""
echo "📋 Verification Configuration:"
echo "   Profile Type: $PROFILE_TYPE"
echo "   Firebase: $FIREBASE_ENABLED"
echo "   Bundle ID: $BUNDLE_ID"
echo "   App Name: $APP_NAME"
echo "   Version: $VERSION_NAME ($VERSION_CODE)"
echo ""

# Make verification script executable
chmod +x lib/scripts/ios/verify_ios_workflow.sh

# Run verification
echo "🚀 Starting iOS Workflow Verification..."
if lib/scripts/ios/verify_ios_workflow.sh; then
    echo ""
    echo "✅ VERIFICATION PASSED!"
    echo "🎉 iOS workflow is ready for production builds"
    echo "📊 Check detailed report at: $OUTPUT_DIR"
    
    # Display quick summary
    # shellcheck disable=SC2144
    if [ -f "$OUTPUT_DIR"/*_report.txt ]; then
        echo ""
        echo "📋 Quick Summary:"
        tail -20 "$OUTPUT_DIR"/*_report.txt | head -15
    fi
    
    exit 0
else
    echo ""
    echo "❌ VERIFICATION FAILED!"
    echo "🔧 Please review the issues and fix them before proceeding"
    echo "📊 Check detailed report at: $OUTPUT_DIR"
    
    # Display quick summary of failures
    # shellcheck disable=SC2144
    if [ -f "$OUTPUT_DIR"/*_report.txt ]; then
        echo ""
        echo "❌ Failed Tests:"
        grep "❌ FAIL:" "$OUTPUT_DIR"/*_report.txt || echo "No failures found in report"
    fi
    
    exit 1
fi 