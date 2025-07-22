#!/bin/bash

# 🛡️ Archive Structure Fix Script
# Purpose: Fix archive structure issues and properly detect app bundles
# Target: Fix "No app bundle found in archive" and "Products directory not found" errors

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
else
    # Fallback logging functions
    log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
    log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
    log_warning() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
    log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }
fi

log_info "🛡️ Archive Structure Fix Script Starting..."

# Function to find app bundle in archive
find_app_bundle() {
    local archive_path="$1"
    local temp_dir="$2"
    
    log_info "🔍 Searching for app bundle in archive: $archive_path"
    
    # List archive contents
    log_info "📋 Archive contents:"
    ls -la "$archive_path" 2>/dev/null || true
    
    # Check for Products directory
    if [ -d "$archive_path/Products" ]; then
        log_info "📁 Found Products directory"
        ls -la "$archive_path/Products" 2>/dev/null || true
        
        # Look for Applications directory
        if [ -d "$archive_path/Products/Applications" ]; then
            log_info "📱 Found Applications directory"
            ls -la "$archive_path/Products/Applications" 2>/dev/null || true
            
            # Find .app bundles
            local app_bundles=$(find "$archive_path/Products/Applications" -name "*.app" -type d 2>/dev/null || true)
            if [ -n "$app_bundles" ]; then
                echo "$app_bundles" | head -1
                return 0
            fi
        fi
        
        # Look for .app bundles directly in Products
        local app_bundles=$(find "$archive_path/Products" -name "*.app" -type d 2>/dev/null || true)
        if [ -n "$app_bundles" ]; then
            echo "$app_bundles" | head -1
            return 0
        fi
    fi
    
    # Check for .app bundles directly in archive root
    local app_bundles=$(find "$archive_path" -name "*.app" -type d 2>/dev/null || true)
    if [ -n "$app_bundles" ]; then
        log_info "📱 Found app bundles in archive root"
        echo "$app_bundles" | head -1
        return 0
    fi
    
    # Check for dSYM files to understand archive structure
    local dsym_files=$(find "$archive_path" -name "*.dSYM" -type d 2>/dev/null || true)
    if [ -n "$dsym_files" ]; then
        log_info "📋 Found dSYM files, checking for corresponding app bundles..."
        echo "$dsym_files" | while read -r dsym_file; do
            local dsym_name=$(basename "$dsym_file" .dSYM)
            local potential_app="$archive_path/Products/Applications/$dsym_name.app"
            if [ -d "$potential_app" ]; then
                log_info "✅ Found app bundle: $potential_app"
                echo "$potential_app"
                return 0
            fi
        done
    fi
    
    # Last resort: check for any executable files
    local executables=$(find "$archive_path" -type f -executable 2>/dev/null || true)
    if [ -n "$executables" ]; then
        log_info "🔍 Found executable files, checking for app bundle structure..."
        echo "$executables" | head -5 | while read -r executable; do
            local app_dir=$(dirname "$executable")
            if [[ "$app_dir" == *".app" ]]; then
                log_info "✅ Found app bundle: $app_dir"
                echo "$app_dir"
                return 0
            fi
        done
    fi
    
    return 1
}

# Function to fix archive structure
fix_archive_structure() {
    local archive_path="$1"
    local temp_dir="$2"
    
    log_info "🔧 Attempting to fix archive structure..."
    
    # Create a proper archive structure if missing
    if [ ! -d "$archive_path/Products" ]; then
        log_info "📁 Creating Products directory..."
        mkdir -p "$archive_path/Products"
    fi
    
    if [ ! -d "$archive_path/Products/Applications" ]; then
        log_info "📱 Creating Applications directory..."
        mkdir -p "$archive_path/Products/Applications"
    fi
    
    # Look for any .app bundles in the archive
    local app_bundles=$(find "$archive_path" -name "*.app" -type d 2>/dev/null || true)
    if [ -n "$app_bundles" ]; then
        log_info "📦 Moving app bundles to proper location..."
        echo "$app_bundles" | while read -r app_bundle; do
            local app_name=$(basename "$app_bundle")
            local target_path="$archive_path/Products/Applications/$app_name"
            
            if [ "$app_bundle" != "$target_path" ]; then
                log_info "🔄 Moving $app_bundle to $target_path"
                mv "$app_bundle" "$target_path" 2>/dev/null || true
            fi
        done
    fi
    
    # Verify the fix worked
    local fixed_app_bundle=$(find_app_bundle "$archive_path" "$temp_dir")
    if [ -n "$fixed_app_bundle" ]; then
        log_success "✅ Archive structure fixed successfully"
        echo "$fixed_app_bundle"
        return 0
    else
        log_error "❌ Failed to fix archive structure"
        return 1
    fi
}

# Main function
main() {
    local archive_path="$1"
    local output_dir="$2"
    local ipa_name="$3"
    
    if [ -z "$archive_path" ] || [ -z "$output_dir" ] || [ -z "$ipa_name" ]; then
        log_error "❌ Usage: $0 <archive_path> <output_dir> <ipa_name>"
        exit 1
    fi
    
    if [ ! -d "$archive_path" ]; then
        log_error "❌ Archive not found: $archive_path"
        exit 1
    fi
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT
    
    log_info "📦 Archive: $archive_path"
    log_info "📁 Output: $output_dir"
    log_info "📦 IPA name: $ipa_name"
    log_info "📁 Temp directory: $temp_dir"
    
    # Try to find app bundle
    local app_bundle=$(find_app_bundle "$archive_path" "$temp_dir")
    
    if [ -z "$app_bundle" ]; then
        log_warning "⚠️ No app bundle found, attempting to fix archive structure..."
        app_bundle=$(fix_archive_structure "$archive_path" "$temp_dir")
    fi
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in archive after fix attempts"
        log_info "📋 Archive contents:"
        find "$archive_path" -type f -o -type d 2>/dev/null | head -20 || true
        exit 1
    fi
    
    log_success "✅ Found app bundle: $app_bundle"
    
    # Verify app bundle structure
    local executable="$app_bundle/$(basename "$app_bundle" .app)"
    if [ ! -f "$executable" ]; then
        log_error "❌ App bundle executable not found: $executable"
        log_info "📋 App bundle contents:"
        ls -la "$app_bundle" 2>/dev/null || true
        exit 1
    fi
    
    log_success "✅ App bundle executable verified: $executable"
    
    # Create IPA
    log_info "📦 Creating IPA..."
    mkdir -p "$output_dir"
    
    # Create Payload directory
    local payload_dir="$temp_dir/Payload"
    mkdir -p "$payload_dir"
    
    # Copy app bundle to Payload
    cp -R "$app_bundle" "$payload_dir/"
    
    # Create IPA using zip
    cd "$temp_dir"
    if zip -r "$output_dir/$ipa_name" Payload/ >/dev/null 2>&1; then
        log_success "✅ IPA created successfully: $output_dir/$ipa_name"
        
        # Verify IPA
        local ipa_size=$(stat -f%z "$output_dir/$ipa_name" 2>/dev/null || stat -c%s "$output_dir/$ipa_name" 2>/dev/null || echo "0")
        log_info "📋 IPA file size: $ipa_size bytes"
        
        if [ "$ipa_size" -gt 1000 ]; then
            log_success "✅ IPA validation passed"
            exit 0
        else
            log_error "❌ IPA file is too small ($ipa_size bytes)"
            exit 1
        fi
    else
        log_error "❌ Failed to create IPA"
        exit 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 <archive_path> <output_dir> <ipa_name>"
        echo "  archive_path: Path to the Xcode archive"
        echo "  output_dir: Directory to save the IPA"
        echo "  ipa_name: Name of the IPA file"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 