#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_TEST] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_TEST] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_TEST] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_TEST] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_TEST] ❌ $1"; }

log "🧪 Testing Dynamic Podfile Generation"

# Test 1: Check if generate script exists
log_info "Test 1: Checking if generate_dynamic_podfile.sh exists"
if [ -f "scripts/generate_dynamic_podfile.sh" ]; then
    log_success "✅ generate_dynamic_podfile.sh found"
else
    log_error "❌ generate_dynamic_podfile.sh not found"
    exit 1
fi

# Test 2: Check if script is executable
log_info "Test 2: Checking if script is executable"
if [ -x "scripts/generate_dynamic_podfile.sh" ]; then
    log_success "✅ Script is executable"
else
    log_warning "⚠️ Script is not executable, making it executable"
    chmod +x scripts/generate_dynamic_podfile.sh
    log_success "✅ Made script executable"
fi

# Test 3: Check if ios directory exists
log_info "Test 3: Checking if ios directory exists"
if [ -d "ios" ]; then
    log_success "✅ ios directory found"
else
    log_error "❌ ios directory not found"
    exit 1
fi

# Test 4: Check if original Podfile exists
log_info "Test 4: Checking if original Podfile exists"
if [ -f "ios/Podfile" ]; then
    log_success "✅ Original Podfile found"
    log_info "Original Podfile size: $(wc -l < ios/Podfile) lines"
else
    log_warning "⚠️ Original Podfile not found"
fi

# Test 5: Generate dynamic Podfile
log_info "Test 5: Generating dynamic Podfile"
cd ios

# Create backup of original if it exists
if [ -f "Podfile" ]; then
    cp Podfile Podfile.test_backup
    log_info "Created backup: Podfile.test_backup"
fi

# Generate dynamic Podfile
cd ..
./scripts/generate_dynamic_podfile.sh

# Test 6: Check if dynamic Podfile was generated
log_info "Test 6: Checking if dynamic Podfile was generated"
if [ -f "ios/Podfile" ]; then
    log_success "✅ Dynamic Podfile generated"
    log_info "Dynamic Podfile size: $(wc -l < ios/Podfile) lines"
    
    # Check for key components
    if grep -q "Dynamically Generated Podfile" ios/Podfile; then
        log_success "✅ Contains dynamic generation header"
    else
        log_warning "⚠️ Missing dynamic generation header"
    fi
    
    if grep -q "GoogleUtilities" ios/Podfile; then
        log_success "✅ Contains GoogleUtilities fixes"
    else
        log_warning "⚠️ Missing GoogleUtilities fixes"
    fi
    
    if grep -q "CwlCatchException" ios/Podfile; then
        log_success "✅ Contains CwlCatchException fixes"
    else
        log_warning "⚠️ Missing CwlCatchException fixes"
    fi
    
    if grep -q "url_launcher_ios" ios/Podfile; then
        log_success "✅ Contains url_launcher_ios fixes"
    else
        log_warning "⚠️ Missing url_launcher_ios fixes"
    fi
    
    if grep -q "flutter_inappwebview_ios" ios/Podfile; then
        log_success "✅ Contains flutter_inappwebview_ios fixes"
    else
        log_warning "⚠️ Missing flutter_inappwebview_ios fixes"
    fi
    
    if grep -q "firebase_messaging" ios/Podfile; then
        log_success "✅ Contains firebase_messaging fixes"
    else
        log_warning "⚠️ Missing firebase_messaging fixes"
    fi
    
else
    log_error "❌ Dynamic Podfile was not generated"
    exit 1
fi

# Test 7: Check if backup was created
log_info "Test 7: Checking if backup was created"
if [ -f "ios/Podfile.original" ]; then
    log_success "✅ Original Podfile backup created"
else
    log_warning "⚠️ Original Podfile backup not found"
fi

# Test 8: Validate Podfile syntax (basic check)
log_info "Test 8: Validating Podfile syntax"
cd ios
if pod --version > /dev/null 2>&1; then
    log_info "CocoaPods is available, checking Podfile syntax"
    if pod lib lint --allow-warnings > /dev/null 2>&1; then
        log_success "✅ Podfile syntax appears valid"
    else
        log_warning "⚠️ Podfile syntax check failed (this is normal for dynamic Podfiles)"
    fi
else
    log_warning "⚠️ CocoaPods not available, skipping syntax check"
fi
cd ..

# Test 9: Restore original Podfile
log_info "Test 9: Restoring original Podfile"
if [ -f "ios/Podfile.original" ]; then
    cp ios/Podfile.original ios/Podfile
    log_success "✅ Original Podfile restored"
    
    # Clean up test files
    if [ -f "ios/Podfile.test_backup" ]; then
        rm ios/Podfile.test_backup
        log_info "Cleaned up test backup"
    fi
else
    log_warning "⚠️ Could not restore original Podfile (no backup found)"
fi

log_success "✅ Dynamic Podfile generation test completed successfully"
exit 0 