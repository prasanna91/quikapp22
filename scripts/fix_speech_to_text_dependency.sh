#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SPEECH_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SPEECH_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SPEECH_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SPEECH_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SPEECH_FIX] ❌ $1"; }

log "🔧 Fixing speech_to_text dependency issue"

# Check if speech_to_text is being used
if grep -q "speech_to_text" pubspec.yaml; then
    log_warning "speech_to_text plugin detected - this causes CwlCatchException dependency"
    log_info "Temporarily removing speech_to_text to prevent CwlCatchException issues"
    
    # Create backup of pubspec.yaml
    cp pubspec.yaml pubspec.yaml.bak
    
    # Remove speech_to_text dependency
    sed -i '' '/speech_to_text/d' pubspec.yaml
    
    log_success "Temporarily removed speech_to_text from pubspec.yaml"
    log_info "Note: speech_to_text functionality will be disabled in this build"
    
    # Run flutter pub get to update dependencies
    log_info "Running flutter pub get to update dependencies"
    flutter pub get
    
    # Clean and reinstall pods
    cd ios
    if [ -d "Pods" ]; then
        log_info "Cleaning pods"
        rm -rf Pods
        rm -f Podfile.lock
    fi
    
    log_info "Installing pods without speech_to_text"
    pod install --repo-update
    
    cd ..
    
    log_success "✅ speech_to_text dependency issue fixed"
    log_warning "⚠️ speech_to_text functionality is disabled in this build"
    log_info "To restore speech_to_text, run: git checkout pubspec.yaml"
else
    log_info "speech_to_text not detected, skipping fix"
fi

exit 0 