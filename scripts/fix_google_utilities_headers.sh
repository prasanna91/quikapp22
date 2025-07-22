#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILITIES_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILITIES_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILITIES_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILITIES_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILITIES_FIX] ❌ $1"; }

log "🔧 Fixing GoogleUtilities Header Issues"

# Check if we're in the ios directory or need to navigate there
if [ -d "ios" ]; then
    cd ios
fi

# Check if GoogleUtilities exists
if [ ! -d "Pods/GoogleUtilities" ]; then
    log_warning "GoogleUtilities not found, skipping header fix"
    exit 0
fi

log_info "Found GoogleUtilities, fixing header files..."

# Create missing header directories
mkdir -p Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted
mkdir -p Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities
mkdir -p Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities
mkdir -p Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities
mkdir -p Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities

# Copy header files to the expected locations
if [ -f "Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h" ]; then
    cp Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted/
    log_success "Fixed IsAppEncrypted.h"
fi

if [ -f "Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h" ]; then
    cp Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities/
    log_success "Fixed GULUserDefaults.h"
fi

if [ -f "Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h" ]; then
    cp Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/
    log_success "Fixed GULSceneDelegateSwizzler.h"
fi

if [ -f "Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h" ]; then
    cp Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities/
    log_success "Fixed GULReachabilityChecker.h"
fi

if [ -f "Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h" ]; then
    cp Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities/
    log_success "Fixed GULNetworkURLSession.h"
fi

# Also fix any other missing headers by copying all .h files to their Public directories
find Pods/GoogleUtilities -name "*.h" | while read -r header_file; do
    # Get the directory of the header file
    header_dir=$(dirname "$header_file")
    header_name=$(basename "$header_file")
    
    # Create the Public directory structure
    public_dir="${header_dir}/Public/$(basename "$header_dir")"
    mkdir -p "$public_dir"
    
    # Copy the header to the Public directory if it doesn't exist
    public_header="${public_dir}/${header_name}"
    if [ ! -f "$public_header" ]; then
        cp "$header_file" "$public_header"
        log_info "Fixed header: $header_name"
    fi
done

# Update Pods project file to include proper header search paths
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
    log_info "Updating Pods project file with header search paths"
    
    # Create backup
    cp Pods/Pods.xcodeproj/project.pbxproj Pods/Pods.xcodeproj/project.pbxproj.bak3
    
    # Add header search paths for GoogleUtilities
    sed -i '' 's/HEADER_SEARCH_PATHS = (/HEADER_SEARCH_PATHS = (\n\t\t\t\t\t"$(PODS_ROOT)\/GoogleUtilities\/third_party\/IsAppEncrypted",\n\t\t\t\t\t"$(PODS_ROOT)\/GoogleUtilities\/GoogleUtilities\/UserDefaults",\n\t\t\t\t\t"$(PODS_ROOT)\/GoogleUtilities\/GoogleUtilities\/AppDelegateSwizzler",\n\t\t\t\t\t"$(PODS_ROOT)\/GoogleUtilities\/GoogleUtilities\/Reachability",\n\t\t\t\t\t"$(PODS_ROOT)\/GoogleUtilities\/GoogleUtilities\/Network",/g' Pods/Pods.xcodeproj/project.pbxproj
    
    log_success "Updated Pods project file"
fi

log_success "✅ GoogleUtilities header files fixed successfully"

# Navigate back to root if we changed directories
if [ "$(pwd)" != "$(dirname "$0")/.." ]; then
    cd ..
fi

exit 0 