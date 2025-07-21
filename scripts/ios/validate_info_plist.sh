#!/bin/bash

# 🛡️ Info.plist Validation Script
# Purpose: Validate and fix Info.plist for App Store submission
# Target: Fix 409 errors related to missing Info.plist keys

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

log_info "🛡️ Info.plist Validation Script Starting..."

# Function to validate Info.plist
validate_info_plist() {
    local info_plist_path="$1"
    
    if [ ! -f "$info_plist_path" ]; then
        log_error "❌ Info.plist not found: $info_plist_path"
        return 1
    fi
    
    log_info "🔍 Validating Info.plist: $info_plist_path"
    
    # Check for required keys
    local missing_keys=()
    
    # Required keys for App Store submission
    local required_keys=(
        "CFBundleDisplayName"
        "CFBundleExecutable"
        "CFBundleIdentifier"
        "CFBundleName"
        "CFBundleShortVersionString"
        "CFBundleVersion"
        "UISupportedInterfaceOrientations"
        "UISupportedInterfaceOrientations~ipad"
    )
    
    for key in "${required_keys[@]}"; do
        if ! plutil -extract "$key" raw "$info_plist_path" >/dev/null 2>&1; then
            missing_keys+=("$key")
        fi
    done
    
    if [ ${#missing_keys[@]} -eq 0 ]; then
        log_success "✅ All required keys present in Info.plist"
        return 0
    else
        log_warning "⚠️ Missing keys in Info.plist: ${missing_keys[*]}"
        return 1
    fi
}

# Function to fix Info.plist
fix_info_plist() {
    local info_plist_path="$1"
    local app_name="${2:-Runner}"
    local bundle_id="${3:-com.example.app}"
    local version="${4:-1.0.0}"
    local build_number="${5:-1}"
    
    log_info "🔧 Fixing Info.plist: $info_plist_path"
    
    # Create backup
    local backup_path="${info_plist_path}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$info_plist_path" "$backup_path"
    log_info "📋 Backup created: $backup_path"
    
    # Add missing keys
    local temp_plist=$(mktemp)
    
    # Start with existing plist
    cp "$info_plist_path" "$temp_plist"
    
    # Add UISupportedInterfaceOrientations if missing
    if ! plutil -extract "UISupportedInterfaceOrientations" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding UISupportedInterfaceOrientations..."
        plutil -insert UISupportedInterfaceOrientations -array "$temp_plist"
        plutil -insert UISupportedInterfaceOrientations.0 -string "UIInterfaceOrientationPortrait" "$temp_plist"
        plutil -insert UISupportedInterfaceOrientations.1 -string "UIInterfaceOrientationPortraitUpsideDown" "$temp_plist"
        plutil -insert UISupportedInterfaceOrientations.2 -string "UIInterfaceOrientationLandscapeLeft" "$temp_plist"
        plutil -insert UISupportedInterfaceOrientations.3 -string "UIInterfaceOrientationLandscapeRight" "$temp_plist"
    fi
    
    # Add UISupportedInterfaceOrientations~ipad if missing
    if ! plutil -extract "UISupportedInterfaceOrientations~ipad" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding UISupportedInterfaceOrientations~ipad..."
        plutil -insert "UISupportedInterfaceOrientations~ipad" -array "$temp_plist"
        plutil -insert "UISupportedInterfaceOrientations~ipad.0" -string "UIInterfaceOrientationPortrait" "$temp_plist"
        plutil -insert "UISupportedInterfaceOrientations~ipad.1" -string "UIInterfaceOrientationPortraitUpsideDown" "$temp_plist"
        plutil -insert "UISupportedInterfaceOrientations~ipad.2" -string "UIInterfaceOrientationLandscapeLeft" "$temp_plist"
        plutil -insert "UISupportedInterfaceOrientations~ipad.3" -string "UIInterfaceOrientationLandscapeRight" "$temp_plist"
    fi
    
    # Update other required keys if needed
    if ! plutil -extract "CFBundleDisplayName" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleDisplayName..."
        plutil -insert CFBundleDisplayName -string "$app_name" "$temp_plist"
    fi
    
    if ! plutil -extract "CFBundleExecutable" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleExecutable..."
        plutil -insert CFBundleExecutable -string "Runner" "$temp_plist"
    fi
    
    if ! plutil -extract "CFBundleIdentifier" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleIdentifier..."
        plutil -insert CFBundleIdentifier -string "$bundle_id" "$temp_plist"
    fi
    
    if ! plutil -extract "CFBundleName" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleName..."
        plutil -insert CFBundleName -string "$app_name" "$temp_plist"
    fi
    
    if ! plutil -extract "CFBundleShortVersionString" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleShortVersionString..."
        plutil -insert CFBundleShortVersionString -string "$version" "$temp_plist"
    fi
    
    if ! plutil -extract "CFBundleVersion" raw "$temp_plist" >/dev/null 2>&1; then
        log_info "➕ Adding CFBundleVersion..."
        plutil -insert CFBundleVersion -string "$build_number" "$temp_plist"
    fi
    
    # Replace original with fixed version
    mv "$temp_plist" "$info_plist_path"
    
    log_success "✅ Info.plist fixed successfully"
    
    # Validate the fix
    if validate_info_plist "$info_plist_path"; then
        log_success "✅ Info.plist validation passed after fix"
        return 0
    else
        log_error "❌ Info.plist validation failed after fix"
        return 1
    fi
}

# Function to validate all Info.plist files in project
validate_all_info_plists() {
    local project_root="${1:-.}"
    
    log_info "🔍 Validating all Info.plist files in project..."
    
    local info_plists=$(find "$project_root" -name "Info.plist" -type f 2>/dev/null || true)
    local failed_count=0
    
    if [ -z "$info_plists" ]; then
        log_warning "⚠️ No Info.plist files found in project"
        return 1
    fi
    
    echo "$info_plists" | while read -r info_plist; do
        log_info "🔍 Validating: $info_plist"
        
        if validate_info_plist "$info_plist"; then
            log_success "✅ Valid: $info_plist"
        else
            log_warning "⚠️ Invalid: $info_plist"
            failed_count=$((failed_count + 1))
        fi
    done
    
    if [ "$failed_count" -eq 0 ]; then
        log_success "✅ All Info.plist files are valid"
        return 0
    else
        log_warning "⚠️ $failed_count Info.plist files need fixing"
        return 1
    fi
}

# Main function
main() {
    case "${1:-}" in
        --validate)
            local info_plist_path="${2:-ios/Runner/Info.plist}"
            validate_info_plist "$info_plist_path"
            ;;
        --fix)
            local info_plist_path="${2:-ios/Runner/Info.plist}"
            local app_name="${3:-Runner}"
            local bundle_id="${4:-com.example.app}"
            local version="${5:-1.0.0}"
            local build_number="${6:-1}"
            fix_info_plist "$info_plist_path" "$app_name" "$bundle_id" "$version" "$build_number"
            ;;
        --validate-all)
            local project_root="${2:-.}"
            validate_all_info_plists "$project_root"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTION] [ARGS]"
            echo ""
            echo "Options:"
            echo "  --validate [PATH]     Validate Info.plist file"
            echo "  --fix [PATH] [ARGS]   Fix Info.plist file"
            echo "  --validate-all [PATH]  Validate all Info.plist files in project"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --validate ios/Runner/Info.plist"
            echo "  $0 --fix ios/Runner/Info.plist 'My App' com.example.app 1.0.0 1"
            echo "  $0 --validate-all ."
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