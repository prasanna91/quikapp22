#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE_FIX] ❌ $1"; }

log "🔧 Fixing Firebase Dependencies"

# Check if we're in the ios directory or need to navigate there
if [ -d "ios" ]; then
    cd ios
fi

# Check if Firebase dependencies are being used
if grep -q "firebase" pubspec.yaml; then
    log_info "Firebase dependencies detected"
    
    # Check for specific Firebase packages
    if grep -q "firebase_core" pubspec.yaml; then
        log_info "firebase_core detected"
    fi
    
    if grep -q "firebase_messaging" pubspec.yaml; then
        log_info "firebase_messaging detected"
    fi
    
    if grep -q "firebase_analytics" pubspec.yaml; then
        log_info "firebase_analytics detected"
    fi
    
    # Update iOS deployment target in project.pbxproj if needed
    if [ -f "Runner.xcodeproj/project.pbxproj" ]; then
        log_info "Updating iOS deployment target for Firebase compatibility"
        
        # Create backup
        cp Runner.xcodeproj/project.pbxproj Runner.xcodeproj/project.pbxproj.firebase_backup
        
        # Update deployment target to 13.0 (Firebase requirement)
        sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' Runner.xcodeproj/project.pbxproj
        sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = "[0-9.]*";/IPHONEOS_DEPLOYMENT_TARGET = "13.0";/g' Runner.xcodeproj/project.pbxproj
        
        log_success "Updated iOS deployment target to 13.0"
    fi
    
    # Check if GoogleService-Info.plist exists
    if [ ! -f "Runner/GoogleService-Info.plist" ]; then
        log_warning "GoogleService-Info.plist not found in Runner directory"
        log_info "This is required for Firebase to work properly"
        log_info "Please ensure GoogleService-Info.plist is placed in ios/Runner/"
    else
        log_success "GoogleService-Info.plist found"
    fi
    
    # Check if Firebase configuration is properly set up
    if [ -f "Runner/GoogleService-Info.plist" ]; then
        log_info "Validating Firebase configuration..."
        
        # Check for required Firebase keys
        if grep -q "REVERSED_CLIENT_ID" Runner/GoogleService-Info.plist; then
            log_success "Firebase configuration appears valid"
        else
            log_warning "Firebase configuration may be incomplete"
        fi
    fi
    
else
    log_info "No Firebase dependencies detected"
fi

# Navigate back to root if we changed directories
if [ "$(pwd)" != "$(dirname "$0")/.." ]; then
    cd ..
fi

log_success "✅ Firebase dependency checks completed"
exit 0 