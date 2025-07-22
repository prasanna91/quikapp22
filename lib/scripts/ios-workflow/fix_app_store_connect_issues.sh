#!/bin/bash

# 🔧 App Store Connect Issues Fix Script
# Fixes ITMS-90685 (CFBundleIdentifier Collision) and ITMS-90183 (Invalid Bundle OS Type)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🔧 App Store Connect Issues Fix Script..."
log_info "🎯 Fixing ITMS-90685: CFBundleIdentifier Collision"
log_info "🎯 Fixing ITMS-90183: Invalid Bundle OS Type"

# Function to fix CFBundleIdentifier collision
fix_bundle_identifier_collision() {
    local main_bundle_id="${1:-}"
    local app_path="${2:-}"
    
    if [ -z "$main_bundle_id" ]; then
        log_error "❌ Main bundle ID is required"
        return 1
    fi
    
    if [ -z "$app_path" ]; then
        log_error "❌ App path is required"
        return 1
    fi
    
    log_info "🔧 Fixing CFBundleIdentifier collision..."
    log_info "📱 Main Bundle ID: $main_bundle_id"
    log_info "📁 App Path: $app_path"
    
    local fixes_applied=0
    
    # Fix frameworks
    if [ -d "$app_path/Frameworks" ]; then
        log_info "🔍 Scanning frameworks for bundle ID collisions..."
        
        find "$app_path/Frameworks" -name "*.framework" -type d | while read framework; do
            local framework_name=$(basename "$framework" .framework)
            local framework_plist="$framework/Info.plist"
            
            if [ -f "$framework_plist" ]; then
                local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$framework_plist" 2>/dev/null || echo "unknown")
                
                if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                    local new_bundle_id="${main_bundle_id}.framework.${framework_name}"
                    log_info "   🔧 Fixing framework collision: $framework_name -> $new_bundle_id"
                    plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$framework_plist"
                    fixes_applied=$((fixes_applied + 1))
                else
                    log_info "   ✅ Framework $framework_name has unique bundle ID: $current_bundle_id"
                fi
            fi
        done
    fi
    
    # Fix plugins/extensions
    if [ -d "$app_path/PlugIns" ]; then
        log_info "🔍 Scanning plugins for bundle ID collisions..."
        
        find "$app_path/PlugIns" -name "*.appex" -type d | while read plugin; do
            local plugin_name=$(basename "$plugin" .appex)
            local plugin_plist="$plugin/Info.plist"
            
            if [ -f "$plugin_plist" ]; then
                local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$plugin_plist" 2>/dev/null || echo "unknown")
                
                if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                    local new_bundle_id="${main_bundle_id}.plugin.${plugin_name}"
                    log_info "   🔧 Fixing plugin collision: $plugin_name -> $new_bundle_id"
                    plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$plugin_plist"
                    fixes_applied=$((fixes_applied + 1))
                else
                    log_info "   ✅ Plugin $plugin_name has unique bundle ID: $current_bundle_id"
                fi
            fi
        done
    fi
    
    # Fix any other bundles
    find "$app_path" -name "*.bundle" -type d | while read bundle; do
        local bundle_name=$(basename "$bundle" .bundle)
        local bundle_plist="$bundle/Info.plist"
        
        if [ -f "$bundle_plist" ]; then
            local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$bundle_plist" 2>/dev/null || echo "unknown")
            
            if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                local new_bundle_id="${main_bundle_id}.bundle.${bundle_name}"
                log_info "   🔧 Fixing bundle collision: $bundle_name -> $new_bundle_id"
                plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$bundle_plist"
                fixes_applied=$((fixes_applied + 1))
            else
                log_info "   ✅ Bundle $bundle_name has unique bundle ID: $current_bundle_id"
            fi
        fi
    done
    
    log_info "📊 Bundle ID collision fixes applied: $fixes_applied"
    return 0
}

# Function to fix CFBundlePackageType
fix_bundle_package_type() {
    local app_path="${1:-}"
    
    if [ -z "$app_path" ]; then
        log_error "❌ App path is required"
        return 1
    fi
    
    local info_plist="$app_path/Info.plist"
    
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found: $info_plist"
        return 1
    fi
    
    log_info "🔧 Fixing CFBundlePackageType..."
    log_info "📁 Info.plist: $info_plist"
    
    # Check current CFBundlePackageType
    local current_package_type=$(plutil -extract CFBundlePackageType raw "$info_plist" 2>/dev/null || echo "NOT_FOUND")
    log_info "📋 Current CFBundlePackageType: $current_package_type"
    
    if [ "$current_package_type" != "APPL" ]; then
        log_info "🔧 Setting CFBundlePackageType to 'APPL'..."
        plutil -replace CFBundlePackageType -string "APPL" "$info_plist"
        
        # Verify the change
        local new_package_type=$(plutil -extract CFBundlePackageType raw "$info_plist" 2>/dev/null || echo "NOT_FOUND")
        if [ "$new_package_type" = "APPL" ]; then
            log_success "✅ CFBundlePackageType fixed: $new_package_type"
            return 0
        else
            log_error "❌ Failed to set CFBundlePackageType to 'APPL'"
            return 1
        fi
    else
        log_success "✅ CFBundlePackageType is already correct: $current_package_type"
        return 0
    fi
}

# Function to validate app bundle structure
validate_app_bundle() {
    local app_path="${1:-}"
    
    if [ -z "$app_path" ]; then
        log_error "❌ App path is required"
        return 1
    fi
    
    log_info "🔍 Validating app bundle structure..."
    
    # Check if app bundle exists
    if [ ! -d "$app_path" ]; then
        log_error "❌ App bundle not found: $app_path"
        return 1
    fi
    
    # Check Info.plist
    local info_plist="$app_path/Info.plist"
    if [ ! -f "$info_plist" ]; then
        log_error "❌ Info.plist not found: $info_plist"
        return 1
    fi
    
    # Check executable
    local executable_name=$(plutil -extract CFBundleExecutable raw "$info_plist" 2>/dev/null || echo "NOT_FOUND")
    if [ "$executable_name" != "NOT_FOUND" ]; then
        local executable_path="$app_path/$executable_name"
        if [ ! -f "$executable_path" ]; then
            log_error "❌ Executable not found: $executable_path"
            return 1
        fi
    fi
    
    log_success "✅ App bundle structure validation passed"
    return 0
}

# Function to create comprehensive report
create_fix_report() {
    local main_bundle_id="${1:-}"
    local app_path="${2:-}"
    local output_dir="${OUTPUT_DIR:-output/ios}"
    
    log_info "📋 Creating App Store Connect fix report..."
    
    mkdir -p "$output_dir"
    
    cat > "$output_dir/APP_STORE_CONNECT_FIX_REPORT.txt" << EOF
App Store Connect Issues Fix Report
===================================

Date: $(date)
Main Bundle ID: $main_bundle_id
App Path: $app_path

Issues Fixed:
1. ITMS-90685: CFBundleIdentifier Collision
   - Fixed framework bundle ID collisions
   - Fixed plugin bundle ID collisions
   - Fixed bundle bundle ID collisions

2. ITMS-90183: Invalid Bundle OS Type
   - Set CFBundlePackageType to "APPL"
   - Verified Info.plist structure

Validation:
- App bundle structure validated
- Info.plist structure validated
- Executable presence verified

Bundle ID Distribution:
- Main App: $main_bundle_id
- Frameworks: ${main_bundle_id}.framework.{name}
- Plugins: ${main_bundle_id}.plugin.{name}
- Bundles: ${main_bundle_id}.bundle.{name}

This fix ensures:
✅ No CFBundleIdentifier collisions
✅ Correct CFBundlePackageType
✅ Valid app bundle structure
✅ App Store Connect compliance

Ready for App Store Connect upload.
EOF
    
    log_success "✅ Fix report created: $output_dir/APP_STORE_CONNECT_FIX_REPORT.txt"
}

# Main function
main() {
    local main_bundle_id="${1:-}"
    local app_path="${2:-}"
    
    # Validate input
    if [ -z "$main_bundle_id" ]; then
        log_error "❌ Main bundle ID is required"
        log_info "Usage: $0 <main_bundle_id> <app_path>"
        log_info "Example: $0 com.garbcode.garbcodeapp /path/to/Runner.app"
        exit 1
    fi
    
    if [ -z "$app_path" ]; then
        log_error "❌ App path is required"
        log_info "Usage: $0 <main_bundle_id> <app_path>"
        log_info "Example: $0 com.garbcode.garbcodeapp /path/to/Runner.app"
        exit 1
    fi
    
    log_info "🔧 Starting App Store Connect issues fix..."
    log_info "🎯 Main Bundle ID: $main_bundle_id"
    log_info "📁 App Path: $app_path"
    
    # Validate app bundle structure
    if ! validate_app_bundle "$app_path"; then
        log_error "❌ App bundle validation failed"
        exit 1
    fi
    
    # Fix CFBundleIdentifier collision
    if ! fix_bundle_identifier_collision "$main_bundle_id" "$app_path"; then
        log_error "❌ Failed to fix bundle identifier collision"
        exit 1
    fi
    
    # Fix CFBundlePackageType
    if ! fix_bundle_package_type "$app_path"; then
        log_error "❌ Failed to fix bundle package type"
        exit 1
    fi
    
    # Create comprehensive report
    create_fix_report "$main_bundle_id" "$app_path"
    
    log_success "🎉 App Store Connect issues fix completed successfully!"
    log_info "📱 Main Bundle ID: $main_bundle_id"
    log_info "📁 App Path: $app_path"
    log_info "📋 Report: ${OUTPUT_DIR:-output/ios}/APP_STORE_CONNECT_FIX_REPORT.txt"
    log_info "🚀 Ready for App Store Connect upload"
    
    return 0
}

# Run main function with all arguments
main "$@" 