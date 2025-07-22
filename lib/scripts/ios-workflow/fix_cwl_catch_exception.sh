#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CWL_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CWL_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CWL_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CWL_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [CWL_FIX] ❌ $1"; }

log "🔧 Fixing CwlCatchException Swift compiler error"

# Check if we're in a release build
# Check multiple possible indicators of release build
RELEASE_BUILD=false

if [ "${CONFIGURATION:-}" = "Release" ] || [ "${CONFIGURATION:-}" = "Profile" ]; then
    RELEASE_BUILD=true
fi

# Check if building for device (which indicates release build)
if [ "${FLUTTER_BUILD_MODE:-}" = "release" ] || [ "${FLUTTER_BUILD_MODE:-}" = "profile" ]; then
    RELEASE_BUILD=true
fi

# Check if we're building for device (ios-release)
if echo "$*" | grep -q "ios-release" || echo "$FLUTTER_BUILD_MODE" | grep -q "release"; then
    RELEASE_BUILD=true
fi

# Check if we're in a release configuration
if [ "${BUILD_CONFIGURATION:-}" = "Release" ] || [ "${BUILD_CONFIGURATION:-}" = "Profile" ]; then
    RELEASE_BUILD=true
fi

# Always remove CwlCatchException pods as they cause Swift compiler errors
# These are test-only dependencies that shouldn't be in any production build
log_info "Removing CwlCatchException pods to prevent Swift compiler errors"

# Remove CwlCatchException pods from Pods project
if [ -d "ios/Pods/CwlCatchException" ]; then
    log_info "Removing CwlCatchException pod"
    rm -rf ios/Pods/CwlCatchException
fi

if [ -d "ios/Pods/CwlCatchExceptionSupport" ]; then
    log_info "Removing CwlCatchExceptionSupport pod"
    rm -rf ios/Pods/CwlCatchExceptionSupport
fi

# Update Pods project file to remove these targets
if [ -f "ios/Pods/Pods.xcodeproj/project.pbxproj" ]; then
    log_info "Updating Pods project file"
    
    # Create backup
    cp ios/Pods/Pods.xcodeproj/project.pbxproj ios/Pods/Pods.xcodeproj/project.pbxproj.bak
    
    # Remove CwlCatchException targets from project file
    sed -i '' '/CwlCatchException/d' ios/Pods/Pods.xcodeproj/project.pbxproj
    sed -i '' '/CwlCatchExceptionSupport/d' ios/Pods/Pods.xcodeproj/project.pbxproj
    
    log_success "Updated Pods project file"
fi

log_success "CwlCatchException pods removed successfully"

log_success "CwlCatchException fix completed"
exit 0 