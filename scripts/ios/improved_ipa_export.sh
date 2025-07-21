#!/bin/bash

# 🚀 Improved IPA Export Script
# Purpose: Handle archive structure issues and ensure proper IPA creation
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

log_info "🚀 Improved IPA Export Script Starting..."

# Function to validate archive structure
validate_archive_structure() {
    local archive_path="$1"
    
    log_info "🔍 Validating archive structure: $archive_path"
    
    if [ ! -d "$archive_path" ]; then
        log_error "❌ Archive directory not found: $archive_path"
        return 1
    fi
    
    # Check for Products directory
    local products_dir="$archive_path/Products"
    if [ ! -d "$products_dir" ]; then
        log_error "❌ Products directory not found in archive"
        return 1
    fi
    
    # Check for Applications directory
    local applications_dir="$products_dir/Applications"
    if [ ! -d "$applications_dir" ]; then
        log_error "❌ Applications directory not found in Products"
        return 1
    fi
    
    # Find app bundle
    local app_bundle=$(find "$applications_dir" -name "*.app" -type d 2>/dev/null | head -1)
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in Applications directory"
        return 1
    fi
    
    log_success "✅ Archive structure validation passed"
    return 0
}

# Function to fix archive structure
fix_archive_structure() {
    local archive_path="$1"
    
    log_info "🔧 Attempting to fix archive structure..."
    
    # Create Products/Applications structure if missing
    local products_dir="$archive_path/Products"
    local applications_dir="$products_dir/Applications"
    
    mkdir -p "$applications_dir"
    
    # Look for app bundle in various locations
    local app_bundle=""
    local possible_locations=(
        "$archive_path/Products/Applications"
        "$archive_path/Applications"
        "$archive_path"
        "$archive_path/Products"
    )
    
    for location in "${possible_locations[@]}"; do
        if [ -d "$location" ]; then
            app_bundle=$(find "$location" -name "*.app" -type d 2>/dev/null | head -1)
            if [ -n "$app_bundle" ]; then
                log_info "📦 Found app bundle: $app_bundle"
                break
            fi
        fi
    done
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in archive"
        return 1
    fi
    
    # Move app bundle to correct location if needed
    local target_app_bundle="$applications_dir/$(basename "$app_bundle")"
    if [ "$app_bundle" != "$target_app_bundle" ]; then
        log_info "📦 Moving app bundle to correct location..."
        cp -R "$app_bundle" "$target_app_bundle"
        app_bundle="$target_app_bundle"
    fi
    
    log_success "✅ Archive structure fixed"
    return 0
}

# Function to validate app bundle
validate_app_bundle() {
    local app_bundle="$1"
    
    log_info "🔍 Validating app bundle: $app_bundle"
    
    if [ ! -d "$app_bundle" ]; then
        log_error "❌ App bundle directory not found: $app_bundle"
        return 1
    fi
    
    # Check for executable
    local app_name=$(basename "$app_bundle" .app)
    local executable="$app_bundle/$app_name"
    
    if [ ! -f "$executable" ]; then
        log_error "❌ App bundle executable not found: $executable"
        return 1
    fi
    
    if [ ! -x "$executable" ]; then
        log_error "❌ App bundle executable is not executable: $executable"
        return 1
    fi
    
    # Check file size of executable
    local exec_size=$(stat -f%z "$executable" 2>/dev/null || stat -c%s "$executable" 2>/dev/null || echo "0")
    if [ "$exec_size" -lt 1000 ]; then
        log_error "❌ App bundle executable is too small ($exec_size bytes) - corrupted"
        return 1
    fi
    
    # Check for Info.plist
    local info_plist="$app_bundle/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        return 1
    fi
    
    # Validate Info.plist
    if ! plutil -lint "$info_plist" >/dev/null 2>&1; then
        log_error "❌ Info.plist is not valid"
        return 1
    fi
    
    log_success "✅ App bundle validation passed"
    return 0
}

# Function to create IPA from archive
create_ipa_from_archive() {
    local archive_path="$1"
    local output_dir="$2"
    local ipa_name="$3"
    
    log_info "📦 Creating IPA from archive..."
    
    # Validate and fix archive structure
    if ! validate_archive_structure "$archive_path"; then
        log_warning "⚠️ Archive structure validation failed, attempting to fix..."
        if ! fix_archive_structure "$archive_path"; then
            log_error "❌ Failed to fix archive structure"
            return 1
        fi
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Find app bundle
    local app_bundle=$(find "$archive_path/Products/Applications" -name "*.app" -type d 2>/dev/null | head -1)
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found after structure fix"
        return 1
    fi
    
    # Validate app bundle
    if ! validate_app_bundle "$app_bundle"; then
        log_error "❌ App bundle validation failed"
        return 1
    fi
    
    # Create Payload directory
    local payload_dir="$output_dir/Payload"
    mkdir -p "$payload_dir"
    
    # Copy app bundle to Payload
    log_info "📦 Copying app bundle to Payload..."
    cp -R "$app_bundle" "$payload_dir/"
    
    # Create IPA
    local ipa_path="$output_dir/$ipa_name"
    log_info "📦 Creating IPA: $ipa_path"
    
    cd "$output_dir"
    if zip -r "$ipa_name" Payload/ >/dev/null 2>&1; then
        log_success "✅ IPA created successfully: $ipa_path"
        
        # Validate IPA
        local file_size=$(stat -f%z "$ipa_path" 2>/dev/null || stat -c%s "$ipa_path" 2>/dev/null || echo "0")
        log_info "📋 IPA file size: $file_size bytes"
        
        if [ "$file_size" -gt 1000000 ]; then
            log_success "✅ IPA validation passed (size > 1MB)"
            return 0
        else
            log_error "❌ IPA file is too small ($file_size bytes)"
            return 1
        fi
    else
        log_error "❌ Failed to create IPA"
        return 1
    fi
}

# Function to create IPA with fallback methods
create_ipa_with_fallbacks() {
    local output_dir="$1"
    local ipa_name="$2"
    
    log_info "🚀 Creating IPA with fallback methods..."
    
    # Method 1: Try to find and use valid archive
    local archives=$(find . -name "*.xcarchive" -type d 2>/dev/null || true)
    if [ -n "$archives" ]; then
        local archive_path=$(echo "$archives" | head -1)
        log_info "📦 Found archive: $archive_path"
        
        if create_ipa_from_archive "$archive_path" "$output_dir" "$ipa_name"; then
            log_success "✅ IPA created successfully from archive"
            return 0
        fi
    fi
    
    # Method 2: Try to find app bundle directly
    log_info "🔍 Searching for app bundle directly..."
    local app_bundles=$(find . -name "*.app" -type d 2>/dev/null)
    if [ -n "$app_bundles" ]; then
        local app_bundle=$(echo "$app_bundles" | head -1)
        log_info "📦 Found app bundle: $app_bundle"
        
        # Validate app bundle
        if ! validate_app_bundle "$app_bundle"; then
            log_error "❌ App bundle validation failed"
            return 1
        fi
        
        # Create IPA from app bundle
        mkdir -p "$output_dir/Payload"
        cp -R "$app_bundle" "$output_dir/Payload/"
        
        cd "$output_dir"
        if zip -r "$ipa_name" Payload/ >/dev/null 2>&1; then
            log_success "✅ IPA created successfully from app bundle"
            
            # Validate IPA
            local file_size=$(stat -f%z "$ipa_name" 2>/dev/null || stat -c%s "$ipa_name" 2>/dev/null || echo "0")
            log_info "📋 IPA file size: $file_size bytes"
            
            if [ "$file_size" -gt 1000000 ]; then
                log_success "✅ IPA validation passed (size > 1MB)"
                return 0
            else
                log_error "❌ IPA file is too small ($file_size bytes)"
                return 1
            fi
        else
            log_error "❌ Failed to create IPA from app bundle"
            return 1
        fi
    fi
    
    log_error "❌ No valid archives or app bundles found"
    return 1
}

# Main function
main() {
    case "${1:-}" in
        --create-ipa)
            local archive_path="${2:-}"
            local output_dir="${3:-output/ios}"
            local ipa_name="${4:-Runner.ipa}"
            
            if [ -z "$archive_path" ]; then
                log_error "❌ Archive path required for --create-ipa"
                exit 1
            fi
            
            create_ipa_from_archive "$archive_path" "$output_dir" "$ipa_name"
            ;;
        --create-with-fallbacks)
            local output_dir="${2:-output/ios}"
            local ipa_name="${3:-Runner.ipa}"
            
            create_ipa_with_fallbacks "$output_dir" "$ipa_name"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTION] [ARGS]"
            echo ""
            echo "Options:"
            echo "  --create-ipa [ARCHIVE] [OUTPUT_DIR] [IPA_NAME]     Create IPA from archive"
            echo "  --create-with-fallbacks [OUTPUT_DIR] [IPA_NAME]    Create IPA with fallback methods"
            echo "  --help, -h                                         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --create-ipa ./path/to/archive.xcarchive output/ios Runner.ipa"
            echo "  $0 --create-with-fallbacks output/ios Runner.ipa"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Use --help for usage information."
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 