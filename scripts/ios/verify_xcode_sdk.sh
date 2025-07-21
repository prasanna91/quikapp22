#!/bin/bash

# 🔍 Xcode and iOS SDK Verification Script
# Verifies Xcode version and iOS SDK compatibility for App Store submission

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    warning "Environment configuration file not found, using system environment variables"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

log "🔍 Starting Xcode and iOS SDK verification..."

# Check if we're in Codemagic environment
if [ -n "${CM_BUILD_ID:-}" ]; then
    log "📱 Detected Codemagic environment"
    
    # Check Xcode version from environment
    if [ -n "${XCODE_VERSION:-}" ]; then
        log "   Xcode Version from environment: $XCODE_VERSION"
        XCODE_MAJOR_VERSION=$(echo $XCODE_VERSION | cut -d. -f1)
        
        if [ "$XCODE_MAJOR_VERSION" -ge 16 ]; then
            success "Xcode version is compatible (16.0 or later)"
        else
            error "Xcode version $XCODE_VERSION is not compatible"
            error "App Store Connect requires Xcode 16.0 or later"
            exit 1
        fi
    else
        # Try to get Xcode version from command line
        if command -v xcodebuild >/dev/null 2>&1; then
            XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            log "   Xcode Version: $XCODE_VERSION"
            XCODE_MAJOR_VERSION=$(echo $XCODE_VERSION | cut -d. -f1)
            
            if [ "$XCODE_MAJOR_VERSION" -ge 16 ]; then
                success "Xcode version is compatible (16.0 or later)"
            else
                error "Xcode version $XCODE_VERSION is not compatible"
                error "App Store Connect requires Xcode 16.0 or later"
                exit 1
            fi
        else
            warning "xcodebuild not available, skipping Xcode version check"
        fi
    fi
    
    # Check iOS SDK version
    if command -v xcodebuild >/dev/null 2>&1; then
        SDK_VERSION=$(xcodebuild -version -sdk iphoneos ProductVersion 2>/dev/null | head -1 || echo "unknown")
        if [ "$SDK_VERSION" != "unknown" ]; then
            log "   iOS SDK Version: $SDK_VERSION"
            
            # Extract major version
            SDK_MAJOR_VERSION=$(echo $SDK_VERSION | cut -d. -f1)
            
            if [ "$SDK_MAJOR_VERSION" -ge 18 ]; then
                success "iOS SDK version is compatible (18.0 or later)"
            else
                error "iOS SDK version $SDK_VERSION is not compatible"
                error "App Store Connect requires iOS 18 SDK or later"
                exit 1
            fi
        else
            warning "Could not determine iOS SDK version"
        fi
    else
        warning "xcodebuild not available, skipping iOS SDK version check"
    fi
else
    log "📱 Running in local environment"
    
    # For local development, just check if Xcode is available
    if command -v xcodebuild >/dev/null 2>&1; then
        success "Xcode is available for local development"
    else
        warning "Xcode not available locally (this is normal for local development)"
    fi
fi

# Check iOS deployment target
log "📱 Checking iOS deployment target..."
if [ -f "ios/Podfile" ]; then
    DEPLOYMENT_TARGET=$(grep -o "platform :ios, '[^']*'" ios/Podfile | cut -d"'" -f2 || echo "unknown")
    if [ -n "$DEPLOYMENT_TARGET" ] && [ "$DEPLOYMENT_TARGET" != "unknown" ]; then
        log "   iOS Deployment Target: $DEPLOYMENT_TARGET"
        
        # Convert to major version for comparison
        DEPLOYMENT_MAJOR=$(echo $DEPLOYMENT_TARGET | cut -d. -f1)
        
        if [ "$DEPLOYMENT_MAJOR" -ge 13 ]; then
            success "iOS deployment target ($DEPLOYMENT_TARGET) is compatible"
        else
            warning "iOS deployment target ($DEPLOYMENT_TARGET) may be too low"
            warning "Consider updating to iOS 13.0 or later"
        fi
    else
        warning "Could not determine iOS deployment target from Podfile"
    fi
else
    warning "Podfile not found, skipping deployment target check"
fi

# Check Flutter iOS configuration
log "📱 Checking Flutter iOS configuration..."
if [ -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
    MINIMUM_VERSION=$(grep -A1 "MinimumOSVersion" ios/Flutter/AppFrameworkInfo.plist | tail -1 | sed 's/[^0-9.]//g' || echo "unknown")
    if [ -n "$MINIMUM_VERSION" ] && [ "$MINIMUM_VERSION" != "unknown" ]; then
        log "   Flutter Minimum iOS Version: $MINIMUM_VERSION"
        
        MINIMUM_MAJOR=$(echo $MINIMUM_VERSION | cut -d. -f1)
        if [ "$MINIMUM_MAJOR" -ge 13 ]; then
            success "Flutter minimum iOS version ($MINIMUM_VERSION) is compatible"
        else
            warning "Flutter minimum iOS version ($MINIMUM_VERSION) may be too low"
        fi
    fi
else
    warning "Flutter AppFrameworkInfo.plist not found"
fi

# Summary
log "📊 Verification Summary:"
if [ -n "${XCODE_VERSION:-}" ]; then
    success "Xcode Version: $XCODE_VERSION (✓ Compatible)"
fi
if [ -n "${SDK_VERSION:-}" ] && [ "$SDK_VERSION" != "unknown" ]; then
    success "iOS SDK Version: $SDK_VERSION (✓ Compatible)"
fi
if [ -n "$DEPLOYMENT_TARGET" ] && [ "$DEPLOYMENT_TARGET" != "unknown" ]; then
    success "Deployment Target: $DEPLOYMENT_TARGET (✓ Compatible)"
fi

log "🎉 Compatibility checks completed!"
log "📱 Ready for iOS 18 SDK and Xcode 16+ requirements."

exit 0 