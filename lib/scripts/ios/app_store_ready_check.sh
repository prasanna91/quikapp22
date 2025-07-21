#!/bin/bash

# App Store Ready Check Script
# Purpose: Validate and fix IPA files for App Store submission

set -euo pipefail

# Source utilities
SCRIPT_DIR=$(dirname "$0")
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
else
    # Fallback logging functions if utils.sh is not available
    log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
    log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
    log_warning() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
    log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }
fi

log_info "🛡️ App Store Ready Check Script Starting..."

# Function to validate IPA file structure
validate_ipa_file() {
    local ipa_path="$1"
    
    log_info "📦 Validating IPA file structure..."
    
    if [ ! -f "$ipa_path" ]; then
        log_error "❌ IPA file not found: $ipa_path"
        return 1
    fi
    
    local file_size=$(stat -f%z "$ipa_path" 2>/dev/null || stat -c%s "$ipa_path" 2>/dev/null || echo "0")
    log_info "📋 IPA file size: $file_size bytes"
    if [ "$file_size" -eq 0 ]; then
        log_error "❌ IPA file is empty"
        return 1
    fi
    
    # Check if it's a valid ZIP file
    if ! unzip -t "$ipa_path" >/dev/null 2>&1; then
        log_error "❌ IPA file is not a valid ZIP archive"
        return 1
    fi
    
    # Check for Payload directory
    if ! unzip -l "$ipa_path" | grep -q "Payload/"; then
        log_error "❌ IPA file does not contain Payload directory"
        return 1
    fi
    
    log_success "✅ IPA structure validation passed"
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
    
    # Check for Info.plist
    if [ ! -f "$app_bundle/Info.plist" ]; then
        log_error "❌ Info.plist not found in app bundle"
        return 1
    fi
    
    # Check for executable
    local executable_name
    executable_name=$(plutil -extract CFBundleExecutable raw "$app_bundle/Info.plist" 2>/dev/null || echo "")
    
    if [ -z "$executable_name" ]; then
        log_error "❌ CFBundleExecutable not found in Info.plist"
        return 1
    fi
    
    if [ ! -f "$app_bundle/$executable_name" ]; then
        log_error "❌ Bundle executable not found: $app_bundle/$executable_name"
        return 1
    fi
    
    log_success "✅ App bundle validation passed"
    return 0
}

# Function to validate code signing
validate_code_signing() {
    local ipa_path="$1"
    
    log_info "🔐 Validating code signing..."
    
    # Check if IPA is code signed
    if codesign -dv "$ipa_path" >/dev/null 2>&1; then
        log_success "✅ IPA is code signed"
        return 0
    else
        log_warning "⚠️ IPA is not code signed"
        return 1
    fi
}

# Function to validate provisioning profile
validate_provisioning_profile() {
    local ipa_path="$1"
    
    log_info "📋 Validating provisioning profile..."
    
    # Extract and check for embedded.mobileprovision
    local temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/ipa_validation_$$")
    trap 'rm -rf "$temp_dir"' EXIT
    
    if unzip -q "$ipa_path" -d "$temp_dir" 2>/dev/null; then
        local app_bundle
        app_bundle=$(find "$temp_dir/Payload" -name "*.app" -type d 2>/dev/null | head -1)
        
        if [ -n "$app_bundle" ] && [ -f "$app_bundle/embedded.mobileprovision" ]; then
            log_success "✅ Provisioning profile found"
            return 0
        fi
    fi
    
    log_error "❌ Provisioning profile not found"
    return 1
}

# Function to validate bundle identifier
validate_bundle_identifier() {
    local expected_bundle_id="$1"
    local ipa_path="$2"
    
    log_info "🏷️ Validating bundle identifier: $expected_bundle_id"
    
    local temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/bundle_validation_$$")
    trap 'rm -rf "$temp_dir"' EXIT
    
    if unzip -q "$ipa_path" -d "$temp_dir" 2>/dev/null; then
        local app_bundle
        app_bundle=$(find "$temp_dir/Payload" -name "*.app" -type d 2>/dev/null | head -1)
        
        if [ -n "$app_bundle" ] && [ -f "$app_bundle/Info.plist" ]; then
            local actual_bundle_id
            actual_bundle_id=$(plutil -extract CFBundleIdentifier raw "$app_bundle/Info.plist" 2>/dev/null || echo "")
            if [ "$actual_bundle_id" = "$expected_bundle_id" ]; then
                log_success "✅ Bundle identifier matches: $actual_bundle_id"
                return 0
            else
                log_error "❌ Bundle identifier mismatch. Expected: $expected_bundle_id, Actual: $actual_bundle_id"
                return 1
            fi
        fi
    fi
    
    log_error "❌ Could not validate bundle identifier"
    return 1
}

# Function to validate version information
validate_version_info() {
    local expected_version="$1"
    local expected_build="$2"
    local ipa_path="$3"
    
    log_info "📱 Validating version information..."
    
    # Extract Info.plist and check version
    local temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/version_validation_$$")
    trap 'rm -rf "$temp_dir"' EXIT
    
    if unzip -q "$ipa_path" -d "$temp_dir" 2>/dev/null; then
        local app_bundle
        app_bundle=$(find "$temp_dir/Payload" -name "*.app" -type d 2>/dev/null | head -1)
        
        if [ -n "$app_bundle" ] && [ -f "$app_bundle/Info.plist" ]; then
            local actual_version
            actual_version=$(plutil -extract CFBundleShortVersionString raw "$app_bundle/Info.plist" 2>/dev/null || echo "")
            local actual_build
            actual_build=$(plutil -extract CFBundleVersion raw "$app_bundle/Info.plist" 2>/dev/null || echo "")
            if [ "$actual_version" = "$expected_version" ] && [ "$actual_build" = "$expected_build" ]; then
                log_success "✅ Version information matches. Version: $actual_version, Build: $actual_build"
                return 0
            else
                log_warning "⚠️ Version information mismatch. Expected: $expected_version/$expected_build, Actual: $actual_version/$actual_build"
                return 1
            fi
        fi
    fi
    
    log_warning "⚠️ Could not validate version information"
    return 1
}

# Function to perform comprehensive App Store validation
perform_app_store_validation() {
    local ipa_path="$1"
    local bundle_id="$2"
    local version="$3"
    local build="$4"
    
    log_info "🔍 Performing comprehensive App Store validation..."
    
    local validation_errors=0
    
    # Validate IPA file
    if ! validate_ipa_file "$ipa_path"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    # Extract and validate app bundle
    local temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/app_store_validation_$$")
    trap 'rm -rf "$temp_dir"' EXIT
    
    if unzip -q "$ipa_path" -d "$temp_dir" 2>/dev/null; then
        local app_bundle
        app_bundle=$(find "$temp_dir/Payload" -name "*.app" -type d 2>/dev/null | head -1)
        
        if [ -n "$app_bundle" ]; then
            if ! validate_app_bundle "$app_bundle"; then
                validation_errors=$((validation_errors + 1))
            fi
        else
            log_error "❌ No app bundle found for validation"
            validation_errors=$((validation_errors + 1))
        fi
    else
        log_error "❌ Failed to extract IPA for validation"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Validate code signing
    if ! validate_code_signing "$ipa_path"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    # Validate provisioning profile
    if ! validate_provisioning_profile "$ipa_path"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    # Validate bundle identifier
    if ! validate_bundle_identifier "$bundle_id" "$ipa_path"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    # Validate version information
    if ! validate_version_info "$version" "$build" "$ipa_path"; then
        validation_errors=$((validation_errors + 1))
    fi
    
    if [ $validation_errors -eq 0 ]; then
        log_success "✅ App Store validation passed - IPA is ready for submission"
        return 0
    else
        log_error "❌ App Store validation failed with $validation_errors errors"
        return 1
    fi
}

# Function to fix common App Store issues
fix_app_store_issues() {
    local ipa_path="$1"
    local bundle_id="$2"
    local version="$3"
    local build="$4"
    
    log_info "🔧 Attempting to fix App Store issues..."
    
    # Try to fix Info.plist issues
    if [ -f "lib/scripts/ios/validate_info_plist.sh" ]; then
        chmod +x "lib/scripts/ios/validate_info_plist.sh"
        
        # Extract app bundle and fix Info.plist
        local temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/fix_app_store_$$")
        trap 'rm -rf "$temp_dir"' EXIT
        
        if unzip -q "$ipa_path" -d "$temp_dir" 2>/dev/null; then
            local app_bundle
            app_bundle=$(find "$temp_dir/Payload" -name "*.app" -type d 2>/dev/null | head -1)
            
            if [ -n "$app_bundle" ]; then
                local info_plist="$app_bundle/Info.plist"
                
                if [ -f "$info_plist" ]; then
                    log_info "🔧 Fixing Info.plist in app bundle..."
                    
                    if ./lib/scripts/ios/validate_info_plist.sh --fix "$info_plist" "${APP_NAME:-Runner}" "$bundle_id" "$version" "$build"; then
                        log_success "✅ Info.plist fixed successfully"
                        
                        # Recreate IPA with fixed Info.plist
                        cd "$temp_dir" || exit 1
                        
                        if zip -r "$ipa_path" Payload/ >/dev/null 2>&1; then
                            log_success "✅ IPA recreated with fixed Info.plist"
                            return 0
                        else
                            log_error "❌ Failed to recreate IPA with fixed Info.plist"
                            return 1
                        fi
                    else
                        log_error "❌ Failed to fix Info.plist"
                        return 1
                    fi
                fi
            fi
        fi
    fi
    
    log_error "❌ Could not fix App Store issues"
    return 1
}

# Main function
main() {
    case "${1:-}" in
        --validate)
            local ipa_path="${2:-}"
            local bundle_id="${3:-com.example.app}"
            local version="${4:-1.0.0}"
            local build="${5:-1}"
            
            if [ -z "$ipa_path" ]; then
                log_error "❌ IPA path required for validation"
                exit 1
            fi
            
            perform_app_store_validation "$ipa_path" "$bundle_id" "$version" "$build"
            ;;
        --fix)
            local ipa_path="${2:-}"
            local bundle_id="${3:-com.example.app}"
            local version="${4:-1.0.0}"
            local build="${5:-1}"
            
            if [ -z "$ipa_path" ]; then
                log_error "❌ IPA path required for fixing"
                exit 1
            fi
            
            fix_app_store_issues "$ipa_path" "$bundle_id" "$version" "$build"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTION] [ARGS]"
            echo ""
            echo "Options:"
            echo "  --validate [IPA] [BUNDLE_ID] [VERSION] [BUILD]  Validate IPA for App Store"
            echo "  --fix [IPA] [BUNDLE_ID] [VERSION] [BUILD]       Fix common App Store issues"
            echo "  --help, -h                                       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --validate output/ios/Runner.ipa com.example.app 1.0.0 1"
            echo "  $0 --fix output/ios/Runner.ipa com.example.app 1.0.0 1"
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