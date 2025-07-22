#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IMPORT_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IMPORT_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IMPORT_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IMPORT_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IMPORT_FIX] ❌ $1"; }

log "🔧 Fixing GoogleUtilities Import Paths"

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

# The specific import paths that are failing and their solutions
declare -A import_fixes=(
    # Format: "import_path" = "source_location"
    ["third_party/IsAppEncrypted/Public/IsAppEncrypted.h"]="third_party/IsAppEncrypted/IsAppEncrypted.h"
    ["GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"]="GoogleUtilities/UserDefaults/GULUserDefaults.h"
    ["GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h"]="GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h"
    ["GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h"]="GoogleUtilities/Reachability/GULReachabilityChecker.h"
    ["GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h"]="GoogleUtilities/Network/GULNetworkURLSession.h"
)

# Function to create the exact import path structure
create_import_path() {
    local import_path="$1"
    local source_location="$2"
    local google_utilities_path="Pods/GoogleUtilities"
    
    # Check if source file exists
    local source_file="$google_utilities_path/$source_location"
    if [ ! -f "$source_file" ]; then
        log_warning "Source file not found: $source_file"
        return 1
    fi
    
    # Create the exact import path directory structure
    local import_dir="$google_utilities_path/$(dirname "$import_path")"
    local import_file="$google_utilities_path/$import_path"
    
    # Create directory structure
    mkdir -p "$import_dir"
    
    # Copy the header to the exact import path
    cp "$source_file" "$import_file"
    
    log_success "Created import path: $import_path"
    return 0
}

# Process each import fix
log_info "Processing import path fixes..."

success_count=0
total_count=0

for import_path in "${!import_fixes[@]}"; do
    total_count=$((total_count + 1))
    source_location="${import_fixes[$import_path]}"
    
    if create_import_path "$import_path" "$source_location"; then
        success_count=$((success_count + 1))
    fi
done

log_info "Import path fix summary: $success_count/$total_count paths created successfully"

# Also create symbolic links for broader compatibility
log_info "Creating symbolic links for broader compatibility..."

# Create symbolic links for the problematic imports
for import_path in "${!import_fixes[@]}"; do
    source_location="${import_fixes[$import_path]}"
    google_utilities_path="Pods/GoogleUtilities"
    
    source_file="$google_utilities_path/$source_location"
    import_file="$google_utilities_path/$import_path"
    
    if [ -f "$source_file" ] && [ -f "$import_file" ]; then
        # Create a symbolic link as backup
        backup_file="$google_utilities_path/${import_path}.backup"
        if [ ! -f "$backup_file" ]; then
            ln -sf "$source_file" "$backup_file"
            log_info "Created symbolic link: $backup_file -> $source_file"
        fi
    fi
done

log_success "✅ Import path fixes completed"

# Verify the critical import paths exist
log_info "Verifying critical import paths..."

critical_imports=(
    "Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted.h"
    "Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"
    "Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h"
    "Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h"
    "Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h"
)

all_imports_exist=true

for import_file in "${critical_imports[@]}"; do
    if [ -f "$import_file" ]; then
        log_success "✅ $import_file exists"
    else
        log_error "❌ $import_file missing"
        all_imports_exist=false
    fi
done

if [ "$all_imports_exist" = true ]; then
    log_success "✅ All critical import paths verified successfully"
else
    log_warning "⚠️ Some critical import paths are missing"
fi

log_success "✅ GoogleUtilities import path fix completed"
exit 0 