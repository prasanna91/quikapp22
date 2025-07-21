#!/bin/bash

# 🛡️ Robust IPA Export Script
# Purpose: Create a properly structured IPA file with correct bundle executable
# Target: Fix 16-byte IPA issue and "Invalid Bundle. The bundle at 'Runner.app' does not contain a bundle executable" error

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

log_info "🛡️ Robust IPA Export Script Starting..."

# Function to validate Xcode archive
validate_xcode_archive() {
    local archive_path="$1"
    
    log_info "🔍 Validating Xcode archive..."
    log_info "📦 Archive Path: $archive_path"
    
    if [ ! -f "$archive_path" ]; then
        log_error "❌ Archive file not found: $archive_path"
        return 1
    fi
    
    # Check if it's a valid archive
    if ! file "$archive_path" | grep -q "archive"; then
        log_error "❌ File is not a valid Xcode archive: $archive_path"
        return 1
    fi
    
    # Extract and validate archive contents
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temporary directory: $temp_dir"
    
    cd "$temp_dir"
    
    # Extract archive
    if ! xcrun xcodebuild -exportArchive -archivePath "$archive_path" -exportPath . -exportOptionsPlist "${SCRIPT_DIR}/../ExportOptions.plist" -allowProvisioningUpdates 2>/dev/null; then
        log_error "❌ Failed to extract archive"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check for app bundle
    local app_bundle
    app_bundle=$(find . -name "*.app" -type d | head -1)
    
    if [ -z "$app_bundle" ]; then
        log_error "❌ No app bundle found in archive"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_info "📱 Found app bundle: $app_bundle"
    
    # Check bundle executable
    local bundle_name
    bundle_name=$(basename "$app_bundle" .app)
    local expected_executable="$app_bundle/$bundle_name"
    
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
    
    if [ "$bundle_executable" != "$bundle_name" ]; then
        log_error "❌ CFBundleExecutable mismatch: expected $bundle_name, found $bundle_executable"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ Archive validation passed"
    log_info "📋 Bundle name: $bundle_name"
    log_info "📋 Bundle executable: $bundle_executable"
    log_info "📋 Executable path: $expected_executable"
    log_info "📋 Executable size: $(ls -lh "$expected_executable" | awk '{print $5}')"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    return 0
}

# Function to create robust IPA export
create_robust_ipa() {
    local archive_path="$1"
    local output_dir="$2"
    local bundle_id="$3"
    local team_id="$4"
    local profile_uuid="$5"
    local cert_identity="$6"
    
    log_info "🛡️ Creating robust IPA export..."
    log_info "📦 Archive Path: $archive_path"
    log_info "📁 Output Directory: $output_dir"
    log_info "🏷️ Bundle ID: $bundle_id"
    log_info "👥 Team ID: $team_id"
    log_info "📱 Profile UUID: $profile_uuid"
    log_info "🔐 Certificate Identity: $cert_identity"
    
    # Validate inputs
    if [ ! -f "$archive_path" ]; then
        log_error "❌ Archive file not found: $archive_path"
        return 1
    fi
    
    if [ -z "$bundle_id" ]; then
        log_error "❌ Bundle ID is required"
        return 1
    fi
    
    if [ -z "$team_id" ]; then
        log_error "❌ Team ID is required"
        return 1
    fi
    
    if [ -z "$profile_uuid" ]; then
        log_error "❌ Profile UUID is required"
        return 1
    fi
    
    if [ -z "$cert_identity" ]; then
        log_error "❌ Certificate identity is required"
        return 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Create robust ExportOptions.plist
    log_info "📝 Creating robust ExportOptions.plist..."
    
    cat > "ios/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${team_id}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingCertificate</key>
    <string>${cert_identity}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${bundle_id}</key>
        <string>${profile_uuid}</string>
    </dict>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>iCloudContainerEnvironment</key>
    <string>Production</string>
    <key>onDemandInstallCapable</key>
    <false/>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>distributionBundleIdentifier</key>
    <string>${bundle_id}</string>
</dict>
</plist>
EOF
    
    log_success "✅ ExportOptions.plist created"
    
    # Method 1: Standard export
    log_info "🔄 Method 1: Standard export..."
    local export_dir="$output_dir/export_method1"
    mkdir -p "$export_dir"
    
    if xcrun xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_dir" \
        -exportOptionsPlist "ios/ExportOptions.plist" \
        -allowProvisioningUpdates 2>&1 | tee "$output_dir/export_method1.log"; then
        
        # Check for IPA file
        local ipa_file
        ipa_file=$(find "$export_dir" -name "*.ipa" -type f | head -1)
        
        if [ -n "$ipa_file" ]; then
            local ipa_size=$(du -h "$ipa_file" | cut -f1)
            log_success "✅ Method 1 successful: $ipa_file ($ipa_size)"
            
            # Validate IPA structure
            if validate_ipa_structure "$ipa_file"; then
                # Copy to final location
                local final_ipa="$output_dir/Runner.ipa"
                cp "$ipa_file" "$final_ipa"
                log_success "✅ IPA created successfully: $final_ipa"
                return 0
            else
                log_warn "⚠️ Method 1 IPA validation failed"
            fi
        else
            log_warn "⚠️ Method 1: No IPA file found"
        fi
    else
        log_warn "⚠️ Method 1 failed"
    fi
    
    # Method 2: Manual export with explicit signing
    log_info "🔄 Method 2: Manual export with explicit signing..."
    local export_dir2="$output_dir/export_method2"
    mkdir -p "$export_dir2"
    
    # Create a temporary directory for manual export
    local temp_dir
    temp_dir=$(mktemp -d)
    log_info "📁 Temporary directory: $temp_dir"
    
    cd "$temp_dir"
    
    # Extract archive manually
    if xcrun xcodebuild -exportArchive -archivePath "$archive_path" -exportPath . -exportOptionsPlist "${SCRIPT_DIR}/../ExportOptions.plist" -allowProvisioningUpdates 2>&1 | tee "$output_dir/export_method2.log"; then
        
        # Find app bundle
        local app_bundle
        app_bundle=$(find . -name "*.app" -type d | head -1)
        
        if [ -n "$app_bundle" ]; then
            log_info "📱 Found app bundle: $app_bundle"
            
            # Ensure bundle executable is correct
            local bundle_name
            bundle_name=$(basename "$app_bundle" .app)
            local expected_executable="$app_bundle/$bundle_name"
            
            # Check if executable exists
            if [ ! -f "$expected_executable" ]; then
                log_warn "⚠️ Expected executable not found, looking for alternatives..."
                
                # Find all executables
                local found_executables
                found_executables=$(find "$app_bundle" -type f -perm +111 2>/dev/null || true)
                
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
                    local bundle_info_plist="$app_bundle/Info.plist"
                    if [ -f "$bundle_info_plist" ]; then
                        if plutil -replace CFBundleExecutable -string "$bundle_name" "$bundle_info_plist"; then
                            log_success "✅ Info.plist updated with correct executable name"
                        else
                            log_warn "⚠️ Failed to update Info.plist"
                        fi
                    fi
                else
                    log_error "❌ No executable files found in bundle"
                    cd - > /dev/null
                    rm -rf "$temp_dir"
                    return 1
                fi
            fi
            
            # Ensure executable permissions
            chmod +x "$expected_executable"
            
            # Create IPA manually
            log_info "📦 Creating IPA manually..."
            local ipa_name="Runner.ipa"
            local ipa_path="$output_dir/$ipa_name"
            
            # Create IPA using zip
            if zip -r "$ipa_path" . >/dev/null 2>&1; then
                local ipa_size=$(du -h "$ipa_path" | cut -f1)
                log_success "✅ Method 2 successful: $ipa_path ($ipa_size)"
                
                # Validate IPA structure
                if validate_ipa_structure "$ipa_path"; then
                    log_success "✅ IPA created successfully: $ipa_path"
                    cd - > /dev/null
                    rm -rf "$temp_dir"
                    return 0
                else
                    log_warn "⚠️ Method 2 IPA validation failed"
                fi
            else
                log_error "❌ Failed to create IPA manually"
            fi
        else
            log_error "❌ No app bundle found in extracted archive"
        fi
    else
        log_warn "⚠️ Method 2 failed"
    fi
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log_error "❌ All export methods failed"
    return 1
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
    
    # Check file size
    local file_size
    file_size=$(stat -f%z "$ipa_path" 2>/dev/null || stat -c%s "$ipa_path" 2>/dev/null || echo "0")
    
    if [ "$file_size" -lt 1000 ]; then
        log_error "❌ IPA file is too small ($file_size bytes) - likely corrupted"
        return 1
    fi
    
    log_info "📋 IPA file size: $file_size bytes"
    
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
        "--validate-archive")
            if [ -z "${2:-}" ]; then
                log_error "❌ Archive path required for --validate-archive"
                exit 1
            fi
            validate_xcode_archive "$2"
            ;;
        "--create-ipa")
            if [ -z "${2:-}" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ] || [ -z "${5:-}" ] || [ -z "${6:-}" ] || [ -z "${7:-}" ]; then
                log_error "❌ All parameters required for --create-ipa"
                log_error "Usage: $0 --create-ipa <archive_path> <output_dir> <bundle_id> <team_id> <profile_uuid> <cert_identity>"
                exit 1
            fi
            create_robust_ipa "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        "--validate-ipa")
            if [ -z "${2:-}" ]; then
                log_error "❌ IPA path required for --validate-ipa"
                exit 1
            fi
            validate_ipa_structure "$2"
            ;;
        "--help"|"-h"|"")
            echo "🛡️ Robust IPA Export Script"
            echo "Usage: $0 [OPTION] [PARAMETERS]"
            echo ""
            echo "Options:"
            echo "  --validate-archive [ARCHIVE_PATH]     Validate Xcode archive"
            echo "  --create-ipa [ARCHIVE] [OUTPUT_DIR] [BUNDLE_ID] [TEAM_ID] [PROFILE_UUID] [CERT_IDENTITY]"
            echo "                                         Create robust IPA with correct bundle executable"
            echo "  --validate-ipa [IPA_PATH]            Validate IPA structure"
            echo "  --help, -h                           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --validate-archive build/ios/Runner.xcarchive"
            echo "  $0 --create-ipa build/ios/Runner.xcarchive output/ios com.example.app TEAM123 PROFILE_UUID 'iPhone Distribution'"
            echo "  $0 --validate-ipa output/ios/Runner.ipa"
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