#!/bin/bash

# 🛡️ Direct IPA Creator Script
# Purpose: Create a valid IPA directly from Xcode archive, bypassing complex export issues
# Target: Fix 16-byte IPA issue by creating IPA manually with proper structure

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

log_info "🛡️ Direct IPA Creator Script Starting..."

# Function to find Xcode archive
find_xcode_archive() {
    log_info "🔍 Searching for Xcode archive..."
    
    # Common archive locations
    local archive_locations=(
        "build/ios/Runner.xcarchive"
        "output/ios/Runner.xcarchive"
        "ios/build/Runner.xcarchive"
        "build/Runner.xcarchive"
        "output/Runner.xcarchive"
    )
    
    for location in "${archive_locations[@]}"; do
        if [ -d "$location" ]; then
            log_success "✅ Found archive at: $location"
            echo "$location"
            return 0
        fi
    done
    
    # Search recursively
    log_info "🔍 Searching recursively for .xcarchive files..."
    local found_archives
    found_archives=$(find . -name "*.xcarchive" -type d 2>/dev/null | head -5)
    
    if [ -n "$found_archives" ]; then
        local first_archive
        first_archive=$(echo "$found_archives" | head -1)
        log_success "✅ Found archive at: $first_archive"
        echo "$first_archive"
        return 0
    fi
    
    log_error "❌ No Xcode archive found"
    return 1
}

# Function to extract app bundle from archive
extract_app_bundle() {
    local archive_path="$1"
    local temp_dir="$2"
    
    log_info "📦 Extracting app bundle from archive..."
    log_info "📦 Archive: $archive_path"
    log_info "📁 Temp directory: $temp_dir"
    
    # Create temp directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Extract archive - try multiple methods
    log_info "📦 Attempting to extract archive..."
    
    # Method 1: Try with ExportOptions.plist if it exists
    if [ -f "${SCRIPT_DIR}/../ExportOptions.plist" ]; then
        log_info "📋 Using ExportOptions.plist from script directory..."
        if xcrun xcodebuild -exportArchive \
            -archivePath "$archive_path" \
            -exportPath . \
            -exportOptionsPlist "${SCRIPT_DIR}/../ExportOptions.plist" \
            -allowProvisioningUpdates 2>&1 | tee export.log; then
            log_success "✅ Archive extracted successfully with ExportOptions.plist"
        else
            log_warn "⚠️ Failed to extract with ExportOptions.plist, trying without..."
        fi
    fi
    
    # Method 2: Try without ExportOptions.plist (automatic signing)
    if [ ! -f "*.app" ]; then
        log_info "📋 Trying automatic export without ExportOptions.plist..."
        if xcrun xcodebuild -exportArchive \
            -archivePath "$archive_path" \
            -exportPath . \
            -allowProvisioningUpdates 2>&1 | tee export_auto.log; then
            log_success "✅ Archive extracted successfully with automatic export"
        else
            log_warn "⚠️ Failed automatic export, trying manual extraction..."
        fi
    fi
    
    # Method 3: Manual extraction by copying from archive
    if [ ! -f "*.app" ]; then
        log_info "📋 Attempting manual extraction from archive..."
        
        # Find the Products directory in the archive
        local products_dir="$archive_path/Products/Applications"
        if [ -d "$products_dir" ]; then
            log_info "📁 Found Products directory: $products_dir"
            
            # Copy app bundle from Products
            local app_bundles
            app_bundles=$(find "$products_dir" -name "*.app" -type d 2>/dev/null)
            
            if [ -n "$app_bundles" ]; then
                local first_app
                first_app=$(echo "$app_bundles" | head -1)
                log_info "📱 Found app bundle: $first_app"
                
                # Copy to current directory
                cp -R "$first_app" .
                log_success "✅ App bundle copied successfully"
            else
                log_error "❌ No app bundles found in Products directory"
                log_info "📁 Contents of Products directory:"
                ls -la "$products_dir" 2>/dev/null || echo "   Directory not accessible"
                cd - > /dev/null
                return 1
            fi
        else
            log_error "❌ Products directory not found in archive"
            log_info "📁 Archive structure:"
            ls -la "$archive_path" 2>/dev/null || echo "   Archive not accessible"
            cd - > /dev/null
            return 1
        fi
    fi
    
    # Find app bundle
    local app_bundle
    app_bundle=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in extracted archive"
        log_info "📁 Contents of temp directory:"
        ls -la
        cd - > /dev/null
        return 1
    fi
    
    log_success "✅ Found app bundle: $app_bundle"
    cd - > /dev/null
    echo "$temp_dir/$app_bundle"
}

# Function to fix app bundle structure
fix_app_bundle() {
    local app_bundle_path="$1"
    
    log_info "🔧 Fixing app bundle structure..."
    log_info "📱 App bundle: $app_bundle_path"
    
    # Get bundle name
    local bundle_name
    bundle_name=$(basename "$app_bundle_path" .app)
    log_info "🏷️ Bundle name: $bundle_name"
    
    # Check Info.plist
    local info_plist="$app_bundle_path/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        return 1
    fi
    
    # Check CFBundleExecutable
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ -z "$bundle_executable" ]; then
        log_warn "⚠️ CFBundleExecutable not found in Info.plist, adding it..."
        if plutil -replace CFBundleExecutable -string "$bundle_name" "$info_plist"; then
            log_success "✅ Added CFBundleExecutable to Info.plist"
            bundle_executable="$bundle_name"
        else
            log_error "❌ Failed to add CFBundleExecutable to Info.plist"
            return 1
        fi
    fi
    
    log_info "📋 CFBundleExecutable: $bundle_executable"
    
    # Check if executable exists
    local expected_executable="$app_bundle_path/$bundle_executable"
    if [ ! -f "$expected_executable" ]; then
        log_warn "⚠️ Expected executable not found, looking for alternatives..."
        
        # Find all executables
        local found_executables
        found_executables=$(find "$app_bundle_path" -type f -perm +111 2>/dev/null || true)
        
        if [ -n "$found_executables" ]; then
            log_info "🔍 Found executables:"
            echo "$found_executables" | while read -r exec_file; do
                log_info "   - $exec_file"
            done
            
            # Use the first executable
            local first_executable
            first_executable=$(echo "$found_executables" | head -1)
            local first_executable_name
            first_executable_name=$(basename "$first_executable")
            
            log_info "🔧 Using first executable: $first_executable_name"
            
            # Copy to expected location
            cp "$first_executable" "$expected_executable"
            chmod +x "$expected_executable"
            log_success "✅ Executable copied to expected location"
            
            # Update Info.plist
            if plutil -replace CFBundleExecutable -string "$bundle_name" "$info_plist"; then
                log_success "✅ Info.plist updated with correct executable name"
            else
                log_warn "⚠️ Failed to update Info.plist"
            fi
        else
            log_error "❌ No executable files found in bundle"
            return 1
        fi
    fi
    
    # Ensure executable permissions
    chmod +x "$expected_executable"
    
    # Verify executable
    if [ -x "$expected_executable" ]; then
        local exec_size=$(ls -lh "$expected_executable" | awk '{print $5}')
        log_success "✅ Executable verified: $expected_executable ($exec_size)"
    else
        log_error "❌ Executable not executable: $expected_executable"
        return 1
    fi
    
    return 0
}

# Function to create IPA manually
create_ipa_manually() {
    local app_bundle_path="$1"
    local output_dir="$2"
    local ipa_name="$3"
    
    log_info "📦 Creating IPA manually..."
    log_info "📱 App bundle: $app_bundle_path"
    log_info "📁 Output directory: $output_dir"
    log_info "📦 IPA name: $ipa_name"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Create temp directory for IPA creation
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temp directory: $temp_dir"
    
    cd "$temp_dir"
    
    # Create Payload directory
    mkdir -p Payload
    
    # Copy app bundle to Payload
    cp -R "$app_bundle_path" Payload/
    
    # Create IPA using zip
    local ipa_path="$output_dir/$ipa_name"
    log_info "📦 Creating IPA: $ipa_path"
    
    if zip -r "$ipa_path" Payload/ >/dev/null 2>&1; then
        local ipa_size=$(du -h "$ipa_path" | cut -f1)
        log_success "✅ IPA created successfully: $ipa_name ($ipa_size)"
        
        # Verify IPA structure
        if verify_ipa_structure "$ipa_path"; then
            log_success "✅ IPA structure verified"
        else
            log_warn "⚠️ IPA structure verification failed"
        fi
        
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    else
        log_error "❌ Failed to create IPA"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to verify IPA structure
verify_ipa_structure() {
    local ipa_path="$1"
    
    log_info "🔍 Verifying IPA structure..."
    log_info "📦 IPA: $ipa_path"
    
    # Check file size
    local file_size
    file_size=$(stat -f%z "$ipa_path" 2>/dev/null || stat -c%s "$ipa_path" 2>/dev/null || echo "0")
    
    if [ "$file_size" -lt 1000 ]; then
        log_error "❌ IPA file is too small ($file_size bytes)"
        return 1
    fi
    
    log_info "📋 IPA file size: $file_size bytes"
    
    # Create temp directory for verification
    local temp_dir
    temp_dir=$(mktemp -d)
    
    cd "$temp_dir"
    
    # Extract IPA
    if ! unzip -q "$ipa_path"; then
        log_error "❌ Failed to extract IPA"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find app bundle
    local app_bundle
    app_bundle=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in IPA"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Get bundle name
    local bundle_name
    bundle_name=$(basename "$app_bundle" .app)
    
    # Check Info.plist
    local info_plist="$app_bundle/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check CFBundleExecutable
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ -z "$bundle_executable" ]; then
        log_error "❌ CFBundleExecutable not found in Info.plist"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check if executable exists
    local expected_executable="$app_bundle/$bundle_executable"
    if [ ! -f "$expected_executable" ]; then
        log_error "❌ Expected executable not found: $expected_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ ! -x "$expected_executable" ]; then
        log_error "❌ Expected executable not executable: $expected_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ IPA structure verification passed"
    log_info "📋 Bundle name: $bundle_name"
    log_info "📋 Bundle executable: $bundle_executable"
    log_info "📋 Executable path: $expected_executable"
    log_info "📋 Executable size: $(ls -lh "$expected_executable" | awk '{print $5}')"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    return 0
}

# Main function
main() {
    case "${1:-}" in
        "--create-ipa")
            if [ -z "${2:-}" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
                log_error "❌ All parameters required for --create-ipa"
                log_error "Usage: $0 --create-ipa <archive_path> <output_dir> <ipa_name>"
                exit 1
            fi
            
            local archive_path="$2"
            local output_dir="$3"
            local ipa_name="$4"
            
            log_info "🛡️ Creating IPA directly from archive..."
            log_info "📦 Archive: $archive_path"
            log_info "📁 Output: $output_dir"
            log_info "📦 IPA name: $ipa_name"
            
            # Find archive if not provided
            if [ ! -d "$archive_path" ]; then
                log_info "🔍 Archive not found, searching for available archives..."
                archive_path=$(find_xcode_archive)
                if [ $? -ne 0 ]; then
                    log_error "❌ No valid archive found"
                    exit 1
                fi
            fi
            
            # Create temp directory
            local temp_dir
            temp_dir=$(mktemp -d)
            log_info "📁 Temp directory: $temp_dir"
            
            # Extract app bundle
            local app_bundle_path
            app_bundle_path=$(extract_app_bundle "$archive_path" "$temp_dir")
            if [ $? -ne 0 ]; then
                log_error "❌ Failed to extract app bundle"
                rm -rf "$temp_dir"
                exit 1
            fi
            
            # Fix app bundle structure
            if ! fix_app_bundle "$app_bundle_path"; then
                log_error "❌ Failed to fix app bundle structure"
                rm -rf "$temp_dir"
                exit 1
            fi
            
            # Create IPA manually
            if ! create_ipa_manually "$app_bundle_path" "$output_dir" "$ipa_name"; then
                log_error "❌ Failed to create IPA"
                rm -rf "$temp_dir"
                exit 1
            fi
            
            # Cleanup
            rm -rf "$temp_dir"
            
            log_success "✅ Direct IPA creation completed successfully"
            ;;
        "--verify-ipa")
            if [ -z "${2:-}" ]; then
                log_error "❌ IPA path required for --verify-ipa"
                exit 1
            fi
            
            verify_ipa_structure "$2"
            ;;
        "--help"|"-h"|"")
            echo "🛡️ Direct IPA Creator Script"
            echo "Usage: $0 [OPTION] [PARAMETERS]"
            echo ""
            echo "Options:"
            echo "  --create-ipa [ARCHIVE] [OUTPUT_DIR] [IPA_NAME]  Create IPA directly from archive"
            echo "  --verify-ipa [IPA_PATH]                         Verify IPA structure"
            echo "  --help, -h                                      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --create-ipa build/ios/Runner.xcarchive output/ios Runner.ipa"
            echo "  $0 --verify-ipa output/ios/Runner.ipa"
            ;;
        *)
            log_error "❌ Unknown option: $1"
            log_error "❌ Use --help for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 