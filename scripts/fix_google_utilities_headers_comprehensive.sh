#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILS_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILS_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILS_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILS_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [GOOGLE_UTILS_FIX] ❌ $1"; }

log "🔧 Comprehensive GoogleUtilities Header Fix"

# Check if we're in the ios directory or need to navigate there
if [ -d "ios" ]; then
    cd ios
fi

# Check if Pods directory exists
if [ ! -d "Pods" ]; then
    log_error "Pods directory not found. Please run 'pod install' first."
    exit 1
fi

# Check if GoogleUtilities pod exists
if [ ! -d "Pods/GoogleUtilities" ]; then
    log_error "GoogleUtilities pod not found. Please ensure it's installed."
    exit 1
fi

log_info "Found GoogleUtilities pod at: $(pwd)/Pods/GoogleUtilities"

# Define the problematic headers and their expected locations
declare -A header_mappings=(
    ["IsAppEncrypted.h"]="third_party/IsAppEncrypted/Public/IsAppEncrypted.h"
    ["GULUserDefaults.h"]="GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"
    ["GULSceneDelegateSwizzler.h"]="GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h"
    ["GULReachabilityChecker.h"]="GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h"
    ["GULNetworkURLSession.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h"
    ["GULAppDelegateSwizzler.h"]="GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULAppDelegateSwizzler.h"
    ["GULApplication.h"]="GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULApplication.h"
    ["GULReachabilityChecker+Internal.h"]="GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker+Internal.h"
    ["GULReachabilityMessageCode.h"]="GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityMessageCode.h"
    ["GULNetwork.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetwork.h"
    ["GULNetworkConstants.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkConstants.h"
    ["GULNetworkLoggerProtocol.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkLoggerProtocol.h"
    ["GULNetworkMessageCode.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkMessageCode.h"
    ["GULMutableDictionary.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULMutableDictionary.h"
    ["GULNetworkInternal.h"]="GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkInternal.h"
    ["GULLogger.h"]="GoogleUtilities/Logger/Public/GoogleUtilities/GULLogger.h"
    ["GULLoggerLevel.h"]="GoogleUtilities/Logger/Public/GoogleUtilities/GULLoggerLevel.h"
    ["GULLoggerCodes.h"]="GoogleUtilities/Common/Public/GoogleUtilities/GULLoggerCodes.h"
    ["GULAppEnvironmentUtil.h"]="GoogleUtilities/Environment/Public/GoogleUtilities/GULAppEnvironmentUtil.h"
    ["GULKeychainStorage.h"]="GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainStorage.h"
    ["GULKeychainUtils.h"]="GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainUtils.h"
    ["GULNetworkInfo.h"]="GoogleUtilities/Environment/Public/GoogleUtilities/GULNetworkInfo.h"
    ["GULNSData+zlib.h"]="GoogleUtilities/NSData+zlib/Public/GoogleUtilities/GULNSData+zlib.h"
    ["GULAppDelegateSwizzler_Private.h"]="GoogleUtilities/AppDelegateSwizzler/Internal/Public/GoogleUtilities/GULAppDelegateSwizzler_Private.h"
    ["GULSceneDelegateSwizzler_Private.h"]="GoogleUtilities/AppDelegateSwizzler/Internal/Public/GoogleUtilities/GULSceneDelegateSwizzler_Private.h"
)

# Function to find a header file in the GoogleUtilities directory
find_header() {
    local header_name="$1"
    local search_path="Pods/GoogleUtilities"
    
    # Search recursively for the header file
    find "$search_path" -name "$header_name" -type f 2>/dev/null | head -1
}

# Function to copy header to expected location
copy_header_to_location() {
    local header_name="$1"
    local expected_path="$2"
    local google_utilities_path="Pods/GoogleUtilities"
    
    # Find the actual header file
    local actual_header=$(find_header "$header_name")
    
    if [ -n "$actual_header" ]; then
        log_info "Found $header_name at: $actual_header"
        
        # Create target directory
        local target_dir="$google_utilities_path/$(dirname "$expected_path")"
        mkdir -p "$target_dir"
        
        # Copy header to expected location
        local target_file="$google_utilities_path/$expected_path"
        cp "$actual_header" "$target_file"
        
        log_success "Copied $header_name to: $target_file"
        return 0
    else
        log_warning "Could not find $header_name"
        return 1
    fi
}

# Process each header mapping
log_info "Processing header mappings..."

success_count=0
total_count=0

for header_name in "${!header_mappings[@]}"; do
    total_count=$((total_count + 1))
    expected_path="${header_mappings[$header_name]}"
    
    if copy_header_to_location "$header_name" "$expected_path"; then
        success_count=$((success_count + 1))
    fi
done

log_info "Header fix summary: $success_count/$total_count headers processed successfully"

# Also create additional header search paths by copying headers to multiple locations
log_info "Creating additional header locations for broader compatibility..."

# Copy all .h files to their Public directories
find "Pods/GoogleUtilities" -name "*.h" -type f | while read -r header_file; do
    relative_path="${header_file#Pods/GoogleUtilities/}"
    public_dir="Pods/GoogleUtilities/$(dirname "$relative_path")/Public/$(dirname "$relative_path")"
    
    mkdir -p "$public_dir"
    cp "$header_file" "$public_dir/"
done

log_success "✅ Comprehensive GoogleUtilities header fix completed"

# Verify critical headers exist
log_info "Verifying critical headers..."

critical_headers=(
    "Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted.h"
    "Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"
    "Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h"
    "Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h"
    "Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h"
)

all_critical_headers_exist=true

for header_path in "${critical_headers[@]}"; do
    if [ -f "$header_path" ]; then
        log_success "✅ $header_path exists"
    else
        log_error "❌ $header_path missing"
        all_critical_headers_exist=false
    fi
done

if [ "$all_critical_headers_exist" = true ]; then
    log_success "✅ All critical headers verified successfully"
else
    log_warning "⚠️ Some critical headers are missing"
fi

log_success "✅ GoogleUtilities header fix completed"
exit 0 