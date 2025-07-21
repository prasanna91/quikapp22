#!/bin/bash

# 🛡️ Ultimate Bundle Executable Fix Script
# Fixes "Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable" error
# This is a comprehensive fix that addresses the root cause of the 409 error

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

# Source environment configuration
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log_info "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log_info "Environment configuration loaded from lib/config/env.sh"
else
    log_warning "Environment configuration file not found, using system environment variables"
fi

log_info "🛡️ Ultimate Bundle Executable Fix Script Starting..."

# Function to completely rebuild IPA with correct structure
rebuild_ipa_with_correct_structure() {
    local ipa_path="$1"
    local bundle_name="${2:-Runner}"
    
    log_info "🛡️ Rebuilding IPA with correct structure..."
    log_info "📦 IPA Path: $ipa_path"
    log_info "🏷️ Bundle Name: $bundle_name"
    
    # Validate input
    if [ ! -f "$ipa_path" ]; then
        log_error "❌ IPA file not found: $ipa_path"
        return 1
    fi
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temporary directory: $temp_dir"
    
    # Extract IPA
    log_info "📦 Extracting IPA..."
    cd "$temp_dir"
    
    if ! unzip -q "$ipa_path"; then
        log_error "❌ Failed to extract IPA: $ipa_path"
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
    
    log_info "📱 Found app bundle: $app_bundle"
    
    # Get bundle name from path
    local bundle_name_from_path
    bundle_name_from_path=$(basename "$app_bundle" .app)
    log_info "🏷️ Bundle name from path: $bundle_name_from_path"
    
    # Step 1: Find all executables in the bundle
    log_info "🔍 Step 1: Finding all executables in bundle..."
    local found_executables
    found_executables=$(find "$app_bundle" -type f -perm +111 2>/dev/null || true)
    
    if [ -z "$found_executables" ]; then
        log_error "❌ No executable files found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "🔍 Found executables:"
    echo "$found_executables" | while read -r exec_file; do
        log_info "   - $exec_file"
    done
    
    # Step 2: Determine the main executable
    local main_executable
    local main_executable_name
    
    # Try to find executable with bundle name
    main_executable=$(find "$app_bundle" -type f -perm +111 -name "$bundle_name" | head -1)
    
    if [ -n "$main_executable" ]; then
        main_executable_name="$bundle_name"
        log_info "✅ Found main executable with bundle name: $main_executable"
    else
        # Try to find executable with bundle name from path
        main_executable=$(find "$app_bundle" -type f -perm +111 -name "$bundle_name_from_path" | head -1)
        
        if [ -n "$main_executable" ]; then
            main_executable_name="$bundle_name_from_path"
            log_info "✅ Found main executable with path name: $main_executable"
        else
            # Use the first executable found
            main_executable=$(echo "$found_executables" | head -1)
            main_executable_name=$(basename "$main_executable")
            log_info "⚠️ Using first found executable: $main_executable"
        fi
    fi
    
    # Step 3: Fix Info.plist
    log_info "🔧 Step 3: Fixing Info.plist..."
    local info_plist="$app_bundle/Info.plist"
    
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Update CFBundleExecutable
    log_info "📋 Updating CFBundleExecutable to: $main_executable_name"
    if ! plutil -replace CFBundleExecutable -string "$main_executable_name" "$info_plist"; then
        log_error "❌ Failed to update CFBundleExecutable in Info.plist"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Step 4: Ensure main executable is in correct location
    log_info "🔧 Step 4: Ensuring main executable is in correct location..."
    local expected_executable_path="$app_bundle/$main_executable_name"
    
    if [ "$main_executable" != "$expected_executable_path" ]; then
        log_info "📋 Moving executable to expected location..."
        cp "$main_executable" "$expected_executable_path"
        chmod +x "$expected_executable_path"
        log_success "✅ Executable moved to expected location"
    fi
    
    # Step 5: Fix all permissions
    log_info "🔧 Step 5: Fixing all permissions..."
    
    # Fix executable permissions
    chmod +x "$expected_executable_path"
    
    # Fix app bundle permissions
    chmod -R 755 "$app_bundle"
    chmod 644 "$info_plist"
    
    # Fix all other executables
    echo "$found_executables" | while read -r exec_file; do
        if [ -f "$exec_file" ]; then
            chmod +x "$exec_file"
        fi
    done
    
    log_success "✅ All permissions fixed"
    
    # Step 6: Validate bundle structure
    log_info "🔍 Step 6: Validating bundle structure..."
    
    # Check if main executable exists and is executable
    if [ ! -f "$expected_executable_path" ]; then
        log_error "❌ Main executable not found at expected path: $expected_executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ ! -x "$expected_executable_path" ]; then
        log_error "❌ Main executable not executable: $expected_executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check Info.plist CFBundleExecutable
    local updated_executable
    updated_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ "$updated_executable" != "$main_executable_name" ]; then
        log_error "❌ CFBundleExecutable mismatch: expected $main_executable_name, found $updated_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ Bundle structure validation passed"
    
    # Step 7: Recreate IPA
    log_info "📦 Step 7: Recreating IPA..."
    cd - > /dev/null
    
    # Backup original IPA
    local backup_ipa="${ipa_path}.ultimate.backup.$(date +%s)"
    cp "$ipa_path" "$backup_ipa"
    log_info "📋 Original IPA backed up to: $backup_ipa"
    
    # Remove original IPA
    rm -f "$ipa_path"
    
    # Create new IPA
    cd "$temp_dir"
    if ! zip -qr "$ipa_path" Payload/; then
        log_error "❌ Failed to recreate IPA"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_success "✅ Ultimate bundle executable fix completed successfully"
    log_info "🛡️ IPA should now pass App Store validation"
    log_info "📦 Fixed IPA: $ipa_path"
    log_info "📋 Backup: $backup_ipa"
    
    return 0
}

# Function to validate IPA structure
validate_ipa_structure() {
    local ipa_path="$1"
    
    log_info "🔍 Validating IPA structure..."
    
    if [ ! -f "$ipa_path" ]; then
        log_error "❌ IPA file not found: $ipa_path"
        return 1
    fi
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Extract IPA
    cd "$temp_dir"
    if ! unzip -q "$ipa_path"; then
        log_error "❌ Failed to extract IPA for validation"
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
    
    log_info "📱 Found app bundle: $app_bundle"
    
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
    
    log_info "🎯 CFBundleExecutable: $bundle_executable"
    
    # Check if executable exists
    local executable_path="$app_bundle/$bundle_executable"
    if [ ! -f "$executable_path" ]; then
        log_error "❌ Executable not found: $executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ ! -x "$executable_path" ]; then
        log_error "❌ Executable not executable: $executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_success "✅ IPA structure validation passed"
    return 0
}

# Main function
main() {
    local action="${1:-}"
    local target="${2:-}"
    local bundle_name="${3:-Runner}"
    
    case "$action" in
        "--rebuild-ipa")
            log_info "🛡️ Rebuilding IPA with correct structure..."
            if [ -z "$target" ]; then
                log_error "❌ IPA path not provided"
                exit 1
            fi
            if rebuild_ipa_with_correct_structure "$target" "$bundle_name"; then
                log_success "✅ IPA rebuild completed successfully"
                exit 0
            else
                log_error "❌ IPA rebuild failed"
                exit 1
            fi
            ;;
        "--validate-ipa")
            log_info "🔍 Validating IPA structure..."
            if [ -z "$target" ]; then
                log_error "❌ IPA path not provided"
                exit 1
            fi
            if validate_ipa_structure "$target"; then
                log_success "✅ IPA validation passed"
                exit 0
            else
                log_error "❌ IPA validation failed"
                exit 1
            fi
            ;;
        *)
            log_info "🛡️ Ultimate Bundle Executable Fix Script"
            log_info "Usage: $0 [OPTION] [TARGET] [BUNDLE_NAME]"
            log_info ""
            log_info "Options:"
            log_info "  --rebuild-ipa [IPA_PATH] [BUNDLE_NAME]  Rebuild IPA with correct structure"
            log_info "  --validate-ipa [IPA_PATH]               Validate IPA structure"
            log_info ""
            log_info "Examples:"
            log_info "  $0 --rebuild-ipa output/ios/app.ipa Runner"
            log_info "  $0 --validate-ipa output/ios/app.ipa"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 