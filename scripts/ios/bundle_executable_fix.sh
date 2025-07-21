#!/bin/bash

# 🔧 Bundle Executable Fix Script
# Fixes "Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable" error
# This error occurs when the app bundle is missing the main executable or has incorrect permissions

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🔧 Bundle Executable Fix Script Starting..."

# Function to validate app bundle structure
validate_app_bundle() {
    app_bundle_path="$1"
    bundle_name="$2"
    
    log_info "🔍 Validating app bundle structure..."
    log_info "📱 App Bundle: $app_bundle_path"
    log_info "🏷️ Bundle Name: $bundle_name"
    
    # Check if app bundle exists
    if [ ! -d "$app_bundle_path" ]; then
        log_error "❌ App bundle not found: $app_bundle_path"
        return 1
    fi
    
    # Check for main executable
    local executable_path="$app_bundle_path/$bundle_name"
    if [ ! -f "$executable_path" ]; then
        log_error "❌ Main executable not found: $executable_path"
        return 1
    fi
    
    # Check executable permissions
    if [ ! -x "$executable_path" ]; then
        log_error "❌ Main executable not executable: $executable_path"
        return 1
    fi
    
    # Check Info.plist
    local info_plist="$app_bundle_path/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found: $info_plist"
        return 1
    fi
    
    # Check CFBundleExecutable in Info.plist
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ -z "$bundle_executable" ]; then
        log_error "❌ CFBundleExecutable not found in Info.plist"
        return 1
    fi
    
    if [ "$bundle_executable" != "$bundle_name" ]; then
        log_warn "⚠️ CFBundleExecutable mismatch: expected $bundle_name, found $bundle_executable"
    fi
    
    # Check for required frameworks
    local frameworks_dir="$app_bundle_path/Frameworks"
    if [ -d "$frameworks_dir" ]; then
        log_info "✅ Frameworks directory found"
        local framework_count=$(find "$frameworks_dir" -name "*.framework" -type d | wc -l)
        log_info "📦 Framework count: $framework_count"
    else
        log_warn "⚠️ Frameworks directory not found (this might be normal for simple apps)"
    fi
    
    log_success "✅ App bundle structure validation passed"
    return 0
}

# Function to fix bundle executable issues
fix_bundle_executable() {
    app_bundle_path="$1"
    bundle_name="$2"
    
    log_info "🔧 Fixing bundle executable issues..."
    
    # Get the actual executable name from Info.plist
    local info_plist="$app_bundle_path/Info.plist"
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ -z "$bundle_executable" ]; then
        log_error "❌ Cannot determine bundle executable from Info.plist"
        return 1
    fi
    
    log_info "🎯 Bundle executable name: $bundle_executable"
    
    # Check if executable exists
    local executable_path="$app_bundle_path/$bundle_executable"
    if [ ! -f "$executable_path" ]; then
        log_error "❌ Executable not found: $executable_path"
        
        # Try to find any executable in the bundle
        local found_executable
        found_executable=$(find "$app_bundle_path" -type f -perm +111 | head -1)
        
        if [ -n "$found_executable" ]; then
            log_info "🔍 Found alternative executable: $found_executable"
            
            # Copy it to the expected location
            log_info "📋 Copying executable to expected location..."
            cp "$found_executable" "$executable_path"
            
            # Set proper permissions
            chmod +x "$executable_path"
            log_success "✅ Executable copied and permissions set"
        else
            log_error "❌ No executable found in app bundle"
            return 1
        fi
    else
        log_info "✅ Executable found: $executable_path"
    fi
    
    # Fix permissions on the executable
    if [ ! -x "$executable_path" ]; then
        log_info "🔧 Fixing executable permissions..."
        chmod +x "$executable_path"
        log_success "✅ Executable permissions fixed"
    fi
    
    # Fix permissions on the entire app bundle
    log_info "🔧 Fixing app bundle permissions..."
    chmod -R 755 "$app_bundle_path"
    log_success "✅ App bundle permissions fixed"
    
    # Ensure Info.plist has correct permissions
    chmod 644 "$info_plist"
    
    # Validate the fix
    if validate_app_bundle "$app_bundle_path" "$bundle_executable"; then
        log_success "✅ Bundle executable fix completed successfully"
        return 0
    else
        log_error "❌ Bundle executable fix failed validation"
        return 1
    fi
}

# Function to fix IPA bundle executable issues
fix_ipa_bundle_executable() {
    ipa_path="$1"
    bundle_name="${2:-Runner}"
    
    log_info "🔧 Fixing IPA bundle executable issues..."
    log_info "📦 IPA Path: $ipa_path"
    log_info "🏷️ Bundle Name: $bundle_name"
    
    # Create temporary directory for IPA extraction
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temporary directory: $temp_dir"
    
    # Extract IPA
    log_info "📦 Extracting IPA..."
    cd "$temp_dir"
    unzip -q "$ipa_path" || {
        log_error "❌ Failed to extract IPA"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Find the app bundle
    local app_bundle
    app_bundle=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in IPA"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "📱 Found app bundle: $app_bundle"
    
    # Fix the app bundle
    if ! fix_bundle_executable "$app_bundle" "$bundle_name"; then
        log_error "❌ Failed to fix app bundle"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Recreate IPA
    log_info "📦 Recreating IPA..."
    rm -f "$ipa_path"
    zip -qr "$ipa_path" Payload/ || {
        log_error "❌ Failed to recreate IPA"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Clean up
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_success "✅ IPA bundle executable fix completed successfully"
    return 0
}

# Function to fix archive bundle executable issues
fix_archive_bundle_executable() {
    archive_path="$1"
    bundle_name="${2:-Runner}"
    
    log_info "🔧 Fixing archive bundle executable issues..."
    log_info "📦 Archive Path: $archive_path"
    log_info "🏷️ Bundle Name: $bundle_name"
    
    # Find the app bundle in the archive
    local app_bundle
    app_bundle=$(find "$archive_path" -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in archive"
        return 1
    fi
    
    log_info "📱 Found app bundle: $app_bundle"
    
    # Fix the app bundle
    if ! fix_bundle_executable "$app_bundle" "$bundle_name"; then
        log_error "❌ Failed to fix app bundle"
        return 1
    fi
    
    log_success "✅ Archive bundle executable fix completed successfully"
    return 0
}

# Function to pre-validate bundle executable configuration
pre_validate_bundle_executable() {
    bundle_name="${1:-Runner}"
    
    log_info "🔍 Pre-validating bundle executable configuration..."
    log_info "🎯 Target: Prevent 409 error 'Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable'"
    
    # Check Xcode project configuration
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    if [ -f "$project_file" ]; then
        log_info "📋 Checking Xcode project configuration..."
        
        # Check for PRODUCT_NAME setting
        local product_name
        product_name=$(grep -A 1 "PRODUCT_NAME" "$project_file" | grep -o '"[^"]*"' | head -1 | tr -d '"')
        
        if [ -n "$product_name" ]; then
            log_info "✅ PRODUCT_NAME found: $product_name"
            if [ "$product_name" != "$bundle_name" ]; then
                log_warn "⚠️ PRODUCT_NAME mismatch: expected $bundle_name, found $product_name"
                log_info "🔧 This might cause bundle executable issues"
            fi
        else
            log_warn "⚠️ PRODUCT_NAME not found in project file"
        fi
        
        # Check for EXECUTABLE_NAME setting
        local executable_name
        executable_name=$(grep -A 1 "EXECUTABLE_NAME" "$project_file" | grep -o '"[^"]*"' | head -1 | tr -d '"')
        
        if [ -n "$executable_name" ]; then
            log_info "✅ EXECUTABLE_NAME found: $executable_name"
            if [ "$executable_name" != "$bundle_name" ]; then
                log_warn "⚠️ EXECUTABLE_NAME mismatch: expected $bundle_name, found $executable_name"
                log_info "🔧 This might cause bundle executable issues"
            fi
        else
            log_warn "⚠️ EXECUTABLE_NAME not found in project file"
        fi
    else
        log_warn "⚠️ Xcode project file not found: $project_file"
    fi
    
    # Check Info.plist configuration
    local info_plist="ios/Runner/Info.plist"
    if [ -f "$info_plist" ]; then
        log_info "📋 Checking Info.plist configuration..."
        
        # Check CFBundleExecutable
        local bundle_executable
        bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
        
        if [ -n "$bundle_executable" ]; then
            log_info "✅ CFBundleExecutable found: $bundle_executable"
            if [ "$bundle_executable" != "$bundle_name" ]; then
                log_warn "⚠️ CFBundleExecutable mismatch: expected $bundle_name, found $bundle_executable"
                log_info "🔧 This might cause bundle executable issues"
            fi
        else
            log_warn "⚠️ CFBundleExecutable not found in Info.plist"
        fi
    else
        log_warn "⚠️ Info.plist not found: $info_plist"
    fi
    
    log_success "✅ Pre-validation completed"
    return 0
}

# Function to post-build validate and fix bundle executable
post_build_validate_and_fix() {
    local build_dir="${1:-build/ios}"
    local bundle_name="${2:-Runner}"
    
    log_info "🔍 Post-build validating and fixing bundle executable..."
    log_info "📁 Build directory: $build_dir"
    log_info "🏷️ Bundle name: $bundle_name"
    
    # Find app bundles in build directory
    local app_bundles
    app_bundles=$(find "$build_dir" -name "*.app" -type d 2>/dev/null || true)
    
    if [ -z "$app_bundles" ]; then
        log_warn "⚠️ No app bundles found in build directory"
        return 0
    fi
    
    local fixed_count=0
    local total_count=0
    
    while IFS= read -r app_bundle; do
        total_count=$((total_count + 1))
        log_info "📱 Processing app bundle: $app_bundle"
        
        if validate_app_bundle "$app_bundle" "$bundle_name"; then
            log_success "✅ App bundle validation passed: $app_bundle"
        else
            log_warn "⚠️ App bundle validation failed, attempting fix: $app_bundle"
            if fix_bundle_executable "$app_bundle" "$bundle_name"; then
                log_success "✅ App bundle fix successful: $app_bundle"
                fixed_count=$((fixed_count + 1))
            else
                log_error "❌ App bundle fix failed: $app_bundle"
            fi
    fi
    done <<< "$app_bundles"
    
    log_info "📊 Bundle executable processing summary:"
    log_info "   Total app bundles: $total_count"
    log_info "   Fixed bundles: $fixed_count"
    
    if [ $fixed_count -gt 0 ]; then
        log_success "✅ Post-build validation and fix completed successfully"
        return 0
    else
        log_info "ℹ️ No bundle fixes were needed"
        return 0
    fi
}

# Function to handle 409 error specifically
handle_409_bundle_executable_error() {
    local ipa_path="$1"
    local bundle_name="${2:-Runner}"
    
    log_info "🚨 Handling 409 Bundle Executable Error..."
    log_info "🎯 Error: 'Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable'"
    log_info "📦 IPA Path: $ipa_path"
    
    # Step 1: Validate the IPA structure
    log_info "🔍 Step 1: Validating IPA structure..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Extract IPA
    log_info "📦 Extracting IPA for analysis..."
    if ! unzip -q "$ipa_path"; then
        log_error "❌ Failed to extract IPA for analysis"
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
    
    # Step 2: Comprehensive bundle analysis
    log_info "🔍 Step 2: Comprehensive bundle analysis..."
    
    # Check bundle structure
    local bundle_name_from_path
    bundle_name_from_path=$(basename "$app_bundle" .app)
    log_info "🏷️ Bundle name from path: $bundle_name_from_path"
    
    # Check Info.plist
    local info_plist="$app_bundle/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract CFBundleExecutable
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ -z "$bundle_executable" ]; then
        log_error "❌ CFBundleExecutable not found in Info.plist"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "🎯 CFBundleExecutable: $bundle_executable"
    
    # Step 3: Check for executable file
    local executable_path="$app_bundle/$bundle_executable"
    log_info "🔍 Step 3: Checking executable file..."
    log_info "📁 Expected executable path: $executable_path"
    
    if [ ! -f "$executable_path" ]; then
        log_error "❌ Executable file not found: $executable_path"
        
        # Step 4: Search for any executable in the bundle
        log_info "🔍 Step 4: Searching for any executable in bundle..."
        local found_executables
        found_executables=$(find "$app_bundle" -type f -perm +111 2>/dev/null || true)
        
        if [ -n "$found_executables" ]; then
            log_info "🔍 Found executables in bundle:"
            echo "$found_executables" | while read -r exec_file; do
                log_info "   - $exec_file"
            done
            
            # Use the first found executable
            local first_executable
            first_executable=$(echo "$found_executables" | head -1)
            
            log_info "📋 Using first found executable: $first_executable"
            
            # Copy to expected location
            log_info "📋 Copying executable to expected location..."
            cp "$first_executable" "$executable_path"
            
            # Set proper permissions
            chmod +x "$executable_path"
            log_success "✅ Executable copied and permissions set"
        else
            log_error "❌ No executable files found in app bundle"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_info "✅ Executable file found: $executable_path"
        
        # Check permissions
        if [ ! -x "$executable_path" ]; then
            log_warn "⚠️ Executable file not executable, fixing permissions..."
            chmod +x "$executable_path"
            log_success "✅ Executable permissions fixed"
        fi
    fi
    
    # Step 5: Fix bundle permissions
    log_info "🔧 Step 5: Fixing bundle permissions..."
    chmod -R 755 "$app_bundle"
    chmod 644 "$info_plist"
    log_success "✅ Bundle permissions fixed"
    
    # Step 6: Validate the fix
    log_info "🔍 Step 6: Validating the fix..."
    if validate_app_bundle "$app_bundle" "$bundle_executable"; then
        log_success "✅ Bundle validation passed after fix"
    else
        log_error "❌ Bundle validation failed after fix"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Step 7: Recreate IPA
    log_info "📦 Step 7: Recreating IPA..."
    cd - > /dev/null
    
    # Backup original IPA
    local backup_ipa="${ipa_path}.backup.$(date +%s)"
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
    
    log_success "✅ 409 Bundle Executable Error fixed successfully"
    log_info "📦 New IPA created: $ipa_path"
    log_info "📋 Backup available: $backup_ipa"
    
    return 0
}

# Function to handle App Store 409 error specifically
handle_app_store_409_error() {
    ipa_path="$1"
    bundle_name="${2:-Runner}"
    
    log_info "🛡️ Handling App Store 409 Error: Invalid Bundle Executable..."
    log_info "📦 IPA Path: $ipa_path"
    log_info "🏷️ Bundle Name: $bundle_name"
    
    # Validate input
    if [ ! -f "$ipa_path" ]; then
        log_error "❌ IPA file not found: $ipa_path"
        return 1
    fi
    
    # Create temporary directory for IPA extraction
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temporary directory: $temp_dir"
    
    # Extract IPA with better error handling
    log_info "📦 Extracting IPA for 409 error fix..."
    cd "$temp_dir"
    
    if ! unzip -q "$ipa_path"; then
        log_error "❌ Failed to extract IPA: $ipa_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find the app bundle
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
    
    # Comprehensive 409 error fix
    log_info "🔧 Applying comprehensive 409 error fix..."
    
    # 1. Fix Info.plist CFBundleExecutable
    local info_plist="$app_bundle/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "📋 Fixing Info.plist CFBundleExecutable..."
    
    # Get current CFBundleExecutable
    local current_executable
    current_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    log_info "🎯 Current CFBundleExecutable: $current_executable"
    
    # 2. Find the actual executable in the bundle
    log_info "🔍 Searching for executable in app bundle..."
    local found_executables
    found_executables=$(find "$app_bundle" -type f -perm +111 2>/dev/null || true)
    
    if [ -z "$found_executables" ]; then
        log_error "❌ No executable files found in app bundle"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "🔍 Found executables in bundle:"
    echo "$found_executables" | while read -r exec_file; do
        log_info "   - $exec_file"
    done
    
    # 3. Determine the correct executable name
    local correct_executable_name
    local executable_path
    
    # First, try to find an executable with the bundle name
    local bundle_executable
    bundle_executable=$(find "$app_bundle" -type f -perm +111 -name "$bundle_name" | head -1)
    
    if [ -n "$bundle_executable" ]; then
        correct_executable_name="$bundle_name"
        executable_path="$bundle_executable"
        log_info "✅ Found bundle executable: $executable_path"
    else
        # Try to find any executable with the bundle name from path
        bundle_executable=$(find "$app_bundle" -type f -perm +111 -name "$bundle_name_from_path" | head -1)
        
        if [ -n "$bundle_executable" ]; then
            correct_executable_name="$bundle_name_from_path"
            executable_path="$bundle_executable"
            log_info "✅ Found executable with bundle name: $executable_path"
        else
            # Use the first executable found
            local first_executable
            first_executable=$(echo "$found_executables" | head -1)
            correct_executable_name=$(basename "$first_executable")
            executable_path="$first_executable"
            log_info "⚠️ Using first found executable: $executable_path"
        fi
    fi
    
    # 4. Update Info.plist with correct executable name
    log_info "📋 Updating Info.plist CFBundleExecutable to: $correct_executable_name"
    if ! plutil -replace CFBundleExecutable -string "$correct_executable_name" "$info_plist"; then
        log_error "❌ Failed to update CFBundleExecutable in Info.plist"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ Updated CFBundleExecutable to: $correct_executable_name"
    
    # 5. Ensure executable is in the correct location
    local expected_executable_path="$app_bundle/$correct_executable_name"
    if [ "$executable_path" != "$expected_executable_path" ]; then
        log_info "📋 Moving executable to expected location..."
        cp "$executable_path" "$expected_executable_path"
        chmod +x "$expected_executable_path"
        log_success "✅ Executable moved to expected location"
    fi
    
    # 6. Fix executable permissions
    log_info "🔧 Fixing executable permissions..."
    chmod +x "$expected_executable_path"
    log_success "✅ Executable permissions fixed"
    
    # 7. Fix app bundle permissions
    log_info "🔧 Fixing app bundle permissions..."
    chmod -R 755 "$app_bundle"
    chmod 644 "$info_plist"
    log_success "✅ App bundle permissions fixed"
    
    # 8. Validate the fix
    log_info "🔍 Validating the fix..."
    
    # Check if executable exists and is executable
    if [ ! -f "$expected_executable_path" ]; then
        log_error "❌ Executable not found at expected path: $expected_executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ ! -x "$expected_executable_path" ]; then
        log_error "❌ Executable not executable: $expected_executable_path"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check Info.plist CFBundleExecutable
    local updated_executable
    updated_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
    
    if [ "$updated_executable" != "$correct_executable_name" ]; then
        log_error "❌ CFBundleExecutable mismatch: expected $correct_executable_name, found $updated_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ Bundle executable validation passed"
    
    # 9. Recreate IPA with fixed bundle
    log_info "📦 Recreating IPA with fixed bundle..."
    cd - > /dev/null
    
    # Backup original IPA
    local backup_ipa="${ipa_path}.backup.$(date +%s)"
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
    
    log_success "✅ App Store 409 error fix completed successfully"
    log_info "🛡️ IPA should now pass App Store validation"
    log_info "📦 Fixed IPA: $ipa_path"
    log_info "📋 Backup: $backup_ipa"
    
    return 0
}

# Main function
main() {
    local action="${1:-}"
    local target="${2:-}"
    local bundle_name="${3:-Runner}"
    
    case "$action" in
        "--validate-only")
            log_info "🔍 Running validation only..."
            if pre_validate_bundle_executable "$bundle_name"; then
                log_success "✅ Pre-validation completed successfully"
                exit 0
            else
                log_error "❌ Pre-validation failed"
                exit 1
            fi
            ;;
        "--fix-ipa")
            log_info "🔧 Fixing IPA bundle executable..."
            if [ -z "$target" ]; then
                log_error "❌ IPA path not provided"
                exit 1
            fi
            if fix_ipa_bundle_executable "$target" "$bundle_name"; then
                log_success "✅ IPA fix completed successfully"
                exit 0
            else
                log_error "❌ IPA fix failed"
                exit 1
            fi
            ;;
        "--fix-archive")
            log_info "🔧 Fixing archive bundle executable..."
            if [ -z "$target" ]; then
                log_error "❌ Archive path not provided"
                exit 1
            fi
            if fix_archive_bundle_executable "$target" "$bundle_name"; then
                log_success "✅ Archive fix completed successfully"
                exit 0
            else
                log_error "❌ Archive fix failed"
                exit 1
            fi
            ;;
        "--post-build")
            log_info "🔍 Running post-build validation and fix..."
            if post_build_validate_and_fix "$target" "$bundle_name"; then
                log_success "✅ Post-build validation and fix completed successfully"
                exit 0
            else
                log_error "❌ Post-build validation and fix failed"
                exit 1
            fi
            ;;
        "--handle-409")
            log_info "🚨 Handling 409 bundle executable error..."
            if [ -z "$target" ]; then
                log_error "❌ IPA path not provided"
                exit 1
            fi
            if handle_409_bundle_executable_error "$target" "$bundle_name"; then
                log_success "✅ 409 error handled successfully"
                exit 0
            else
                log_error "❌ 409 error handling failed"
                exit 1
            fi
            ;;
        "--handle-app-store-409")
            log_info "🛡️ Handling App Store 409 Error..."
            if [ -z "$target" ]; then
                log_error "❌ IPA path not provided"
                exit 1
            fi
            if handle_app_store_409_error "$target" "$bundle_name"; then
                log_success "✅ App Store 409 error handled successfully"
                exit 0
            else
                log_error "❌ App Store 409 error handling failed"
                exit 1
            fi
            ;;
        *)
            log_info "🔧 Bundle Executable Fix Script"
            log_info "Usage: $0 [OPTION] [TARGET] [BUNDLE_NAME]"
            log_info ""
            log_info "Options:"
            log_info "  --validate-only [BUNDLE_NAME]     Pre-validate bundle executable configuration"
            log_info "  --fix-ipa [IPA_PATH] [BUNDLE_NAME] Fix bundle executable in IPA"
            log_info "  --fix-archive [ARCHIVE_PATH] [BUNDLE_NAME] Fix bundle executable in archive"
            log_info "  --post-build [BUILD_DIR] [BUNDLE_NAME] Post-build validation and fix"
            log_info "  --handle-409 [IPA_PATH] [BUNDLE_NAME] Handle 409 bundle executable error"
            log_info "  --handle-app-store-409 [IPA_PATH] [BUNDLE_NAME] Handle App Store 409 error"
            log_info ""
            log_info "Examples:"
            log_info "  $0 --validate-only Runner"
            log_info "  $0 --fix-ipa output/ios/app.ipa Runner"
            log_info "  $0 --fix-archive build/ios/archive/Runner.xcarchive Runner"
            log_info "  $0 --post-build build/ios Runner"
            log_info "  $0 --handle-409 output/ios/app.ipa Runner"
            log_info "  $0 --handle-app-store-409 output/ios/app.ipa Runner"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 