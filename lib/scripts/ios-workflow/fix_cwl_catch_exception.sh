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
if [ "${CONFIGURATION:-}" = "Release" ] || [ "${CONFIGURATION:-}" = "Profile" ]; then
    log_info "Release build detected, removing CwlCatchException pods"
    
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
    
    log_success "CwlCatchException pods removed for release build"
else
    log_info "Debug build detected, keeping CwlCatchException pods"
fi

log_success "CwlCatchException fix completed"
exit 0 