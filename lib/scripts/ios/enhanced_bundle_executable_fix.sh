#!/bin/bash

# 🛡️ Enhanced Bundle Executable Fix Script
# Comprehensive fix for "Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable" error
# This script addresses both the build process and the final IPA structure

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

# Ensure all logging functions are available
if ! command -v log_info >/dev/null 2>&1; then
    log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
fi
if ! command -v log_success >/dev/null 2>&1; then
    log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
fi
if ! command -v log_warning >/dev/null 2>&1; then
    log_warning() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
fi
if ! command -v log_error >/dev/null 2>&1; then
    log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }
fi

log_info "🛡️ Enhanced Bundle Executable Fix Script Starting..."

# Function to check and fix Xcode project configuration
check_and_fix_xcode_project() {
    log_info "🔍 Checking Xcode project configuration..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    if [ ! -f "$project_file" ]; then
        log_error "❌ Xcode project file not found: $project_file"
        return 1
    fi
    
    # Check PRODUCT_NAME
    local product_name
    product_name=$(grep -A 1 "PRODUCT_NAME" "$project_file" 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
    
    if [ -n "$product_name" ]; then
        log_info "📋 PRODUCT_NAME found: $product_name"
        if echo "$product_name" | grep -q '\$(' || echo "$product_name" | grep -q 'TARGET_NAME'; then
            log_info "ℹ️ PRODUCT_NAME uses Xcode variable (normal): $product_name"
        elif [ "$product_name" != "Runner" ]; then
            log_warning "⚠️ PRODUCT_NAME mismatch: expected Runner, found $product_name"
            log_info "🔧 This might cause bundle executable issues"
        fi
    else
        log_warning "⚠️ PRODUCT_NAME not found in project file"
    fi
    
    # Check EXECUTABLE_NAME
    local executable_name
    executable_name=$(grep -A 1 "EXECUTABLE_NAME" "$project_file" 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
    
    if [ -n "$executable_name" ]; then
        log_info "📋 EXECUTABLE_NAME found: $executable_name"
        if echo "$executable_name" | grep -q '\$(' || echo "$executable_name" | grep -q 'TARGET_NAME'; then
            log_info "ℹ️ EXECUTABLE_NAME uses Xcode variable (normal): $executable_name"
        elif [ "$executable_name" != "Runner" ]; then
            log_warning "⚠️ EXECUTABLE_NAME mismatch: expected Runner, found $executable_name"
            log_info "🔧 This might cause bundle executable issues"
        fi
    else
        log_warning "⚠️ EXECUTABLE_NAME not found in project file"
    fi
    
    log_success "✅ Xcode project configuration checked"
}

# Function to check and fix Info.plist
check_and_fix_info_plist() {
    log_info "🔍 Checking Info.plist configuration..."
    
    local info_plist="ios/Runner/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found: $info_plist"
        return 1
    fi
    
    # Check CFBundleExecutable
    local bundle_executable
    bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - "$info_plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1 || echo "")
    
    if [ -n "$bundle_executable" ]; then
        log_info "📋 CFBundleExecutable found: $bundle_executable"
        if [ "$bundle_executable" != "Runner" ]; then
            log_warning "⚠️ CFBundleExecutable mismatch: expected Runner, found $bundle_executable"
            log_info "🔧 Fixing CFBundleExecutable..."
            if plutil -replace CFBundleExecutable -string "Runner" "$info_plist"; then
                log_success "✅ CFBundleExecutable fixed to Runner"
            else
                log_error "❌ Failed to fix CFBundleExecutable"
                return 1
            fi
        fi
    else
        log_warning "⚠️ CFBundleExecutable not found in Info.plist"
        log_info "🔧 Adding CFBundleExecutable..."
        if plutil -insert CFBundleExecutable -string "Runner" "$info_plist"; then
            log_success "✅ CFBundleExecutable added as Runner"
        else
            log_error "❌ Failed to add CFBundleExecutable"
            return 1
        fi
    fi
    
    log_success "✅ Info.plist configuration checked and fixed"
}

# Function to check and fix build output
check_and_fix_build_output() {
    log_info "🔍 Checking build output..."
    
    # Look for .app bundles in build directories
    local app_bundles
    app_bundles=$(find . -name "*.app" -type d 2>/dev/null || true)
    
    if [ -z "$app_bundles" ]; then
        log_warning "⚠️ No .app bundles found in current directory"
        return 0
    fi
    
    echo "$app_bundles" | while read -r app_bundle; do
        log_info "📱 Checking app bundle: $app_bundle"
        
        # Check if bundle has executable
        local bundle_name
        bundle_name=$(basename "$app_bundle" .app)
        local expected_executable="$app_bundle/$bundle_name"
        
        if [ ! -f "$expected_executable" ]; then
            log_warning "⚠️ Expected executable not found: $expected_executable"
            
            # Look for any executable in the bundle
            local found_executables
            found_executables=$(find "$app_bundle" -type f -perm +111 2>/dev/null || true)
            
            if [ -n "$found_executables" ]; then
                log_info "🔍 Found executables in bundle:"
                echo "$found_executables" | while read -r exec_file; do
                    log_info "   - $exec_file"
                done
                
                # Use the first executable found
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
                local bundle_info_plist="$app_bundle/Info.plist"
                if [ -f "$bundle_info_plist" ]; then
                    if plutil -replace CFBundleExecutable -string "$bundle_name" "$bundle_info_plist"; then
                        log_success "✅ Info.plist updated with correct executable name"
                    else
                        log_warning "⚠️ Failed to update Info.plist"
                    fi
                fi
            else
                log_error "❌ No executable files found in bundle: $app_bundle"
            fi
        else
            log_success "✅ Expected executable found: $expected_executable"
        fi
    done
    
    log_success "✅ Build output checked and fixed"
}

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
    local backup_ipa="${ipa_path}.enhanced.backup.$(date +%s)"
    cp "$ipa_path" "$backup_ipa"
    log_info "📋 Original IPA backed up to: $backup_ipa"
    
    # Remove original IPA
    rm -f "$ipa_path"
    
    # Create new IPA
    cd "$temp_dir"
    if zip -r "$ipa_path" . >/dev/null 2>&1; then
        log_success "✅ New IPA created successfully"
    else
        log_error "❌ Failed to create new IPA"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_success "✅ IPA rebuild completed successfully"
    return 0
}

# Function to validate IPA structure
validate_ipa_structure() {
    local ipa_path="$1"
    
    log_info "🔍 Validating IPA structure..."
    log_info "📦 IPA Path: $ipa_path"
    
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
    log_info "📦 Extracting IPA for validation..."
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
    
    # Get bundle name
    local bundle_name
    bundle_name=$(basename "$app_bundle" .app)
    log_info "🏷️ Bundle name: $bundle_name"
    
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
    
    log_info "📋 CFBundleExecutable: $bundle_executable"
    
    # Check if executable exists
    local expected_executable="$app_bundle/$bundle_executable"
    if [ ! -f "$expected_executable" ]; then
        log_error "❌ Executable not found at expected path: $expected_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ ! -x "$expected_executable" ]; then
        log_error "❌ Executable not executable: $expected_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ IPA structure validation passed"
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
        "--check-build")
            log_info "🔍 Checking build configuration..."
            check_and_fix_xcode_project
            check_and_fix_info_plist
            check_and_fix_build_output
            log_success "✅ Build configuration check completed"
            ;;
        "--rebuild-ipa")
            if [ -z "${2:-}" ]; then
                log_error "❌ IPA path required for --rebuild-ipa"
                exit 1
            fi
            rebuild_ipa_with_correct_structure "$2" "${3:-Runner}"
            ;;
        "--validate-ipa")
            if [ -z "${2:-}" ]; then
                log_error "❌ IPA path required for --validate-ipa"
                exit 1
            fi
            validate_ipa_structure "$2"
            ;;
        "--help"|"-h"|"")
            echo "🛡️ Enhanced Bundle Executable Fix Script"
            echo "Usage: $0 [OPTION] [TARGET] [BUNDLE_NAME]"
            echo ""
            echo "Options:"
            echo "  --check-build                    Check and fix build configuration"
            echo "  --rebuild-ipa [IPA_PATH] [BUNDLE_NAME]  Rebuild IPA with correct structure"
            echo "  --validate-ipa [IPA_PATH]               Validate IPA structure"
            echo "  --help, -h                              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --check-build"
            echo "  $0 --rebuild-ipa output/ios/app.ipa Runner"
            echo "  $0 --validate-ipa output/ios/app.ipa"
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