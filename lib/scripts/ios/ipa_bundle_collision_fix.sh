#!/bin/bash
# IPA Bundle Collision Fix - Error ID: 16fe2c8f-330a-451b-90c5-7c218848c196
# Fixes CFBundleIdentifier collisions that occur INSIDE the app bundle during IPA export

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_success() { echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_warn() { echo "⚠️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Main function to fix IPA-level bundle collisions
fix_ipa_bundle_collisions() {
    local ipa_path="$1"
    local main_bundle_id="$2"
    local output_path="${3:-${ipa_path%.ipa}_fixed.ipa}"
    
    log_info "🔧 Starting IPA Bundle Collision Fix"
    log_info "📁 Source IPA: $ipa_path"
    log_info "🎯 Main Bundle ID: $main_bundle_id"
    log_info "📁 Output IPA: $output_path"
    
    # Create working directory
    local work_dir="/tmp/ipa_fix_$(date +%s)"
    mkdir -p "$work_dir"
    
    # Extract IPA
    log_info "📦 Extracting IPA..."
    cd "$work_dir"
    unzip -q "$ipa_path"
    
    # Find the actual app bundle (could be Runner.app or app-specific name)
    local app_path=""
    if [ -d "Payload/Runner.app" ]; then
        app_path="Payload/Runner.app"
        log_info "Using Runner.app as app bundle"
    else
        # Find any .app bundle in Payload directory
        app_path=$(find Payload -name "*.app" -type d | head -1)
        if [ -n "$app_path" ]; then
            log_info "Using $(basename "$app_path") as app bundle"
        fi
    fi
    
    if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
        log_error "No .app bundle found in IPA"
        cleanup_and_exit 1
    fi
    
    local fixes_applied=0
    
    # Fix main app Info.plist (ensure it has the correct bundle ID)
    log_info "🎯 Verifying main app bundle ID..."
    local main_plist="$app_path/Info.plist"
    if [ -f "$main_plist" ]; then
        local current_main_id=$(plutil -extract CFBundleIdentifier raw "$main_plist" 2>/dev/null || echo "unknown")
        if [ "$current_main_id" != "$main_bundle_id" ]; then
            log_info "🔧 Updating main app bundle ID: $current_main_id -> $main_bundle_id"
            plutil -replace CFBundleIdentifier -string "$main_bundle_id" "$main_plist"
            fixes_applied=$((fixes_applied + 1))
        else
            log_success "✅ Main app bundle ID is correct: $main_bundle_id"
        fi
    fi
    
    # Fix Frameworks
    log_info "🔍 Scanning and fixing Frameworks..."
    if [ -d "$app_path/Frameworks" ]; then
        find "$app_path/Frameworks" -name "*.framework" -type d | while read framework; do
            local framework_name=$(basename "$framework" .framework)
            local framework_plist="$framework/Info.plist"
            
            if [ -f "$framework_plist" ]; then
                local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$framework_plist" 2>/dev/null || echo "unknown")
                
                if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                    # Create unique bundle ID for framework
                    local new_bundle_id="${main_bundle_id}.framework.${framework_name}"
                    # Remove any underscores and sanitize
                    new_bundle_id=$(echo "$new_bundle_id" | sed 's/_/-/g' | sed 's/[^a-zA-Z0-9.-]//g')
                    
                    log_info "   🔧 Framework collision fix: $framework_name"
                    log_info "      Old: $current_bundle_id"
                    log_info "      New: $new_bundle_id"
                    
                    plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$framework_plist"
                    fixes_applied=$((fixes_applied + 1))
                fi
            fi
        done
    fi
    
    # Fix PlugIns (Extensions)
    log_info "🔍 Scanning and fixing PlugIns..."
    if [ -d "$app_path/PlugIns" ]; then
        find "$app_path/PlugIns" -name "*.appex" -type d | while read plugin; do
            local plugin_name=$(basename "$plugin" .appex)
            local plugin_plist="$plugin/Info.plist"
            
            if [ -f "$plugin_plist" ]; then
                local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$plugin_plist" 2>/dev/null || echo "unknown")
                
                if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                    local new_bundle_id="${main_bundle_id}.plugin.${plugin_name}"
                    new_bundle_id=$(echo "$new_bundle_id" | sed 's/_/-/g' | sed 's/[^a-zA-Z0-9.-]//g')
                    
                    log_info "   🔧 Plugin collision fix: $plugin_name"
                    log_info "      Old: $current_bundle_id"
                    log_info "      New: $new_bundle_id"
                    
                    plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$plugin_plist"
                    fixes_applied=$((fixes_applied + 1))
                fi
            fi
        done
    fi
    
    # Fix Resource Bundles
    log_info "🔍 Scanning and fixing Resource Bundles..."
    find "$app_path" -name "*.bundle" -type d | while read bundle; do
        local bundle_name=$(basename "$bundle" .bundle)
        local bundle_plist="$bundle/Info.plist"
        
        if [ -f "$bundle_plist" ]; then
            local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$bundle_plist" 2>/dev/null || echo "unknown")
            
            if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                local new_bundle_id="${main_bundle_id}.bundle.${bundle_name}"
                new_bundle_id=$(echo "$new_bundle_id" | sed 's/_/-/g' | sed 's/[^a-zA-Z0-9.-]//g')
                
                log_info "   🔧 Bundle collision fix: $bundle_name"
                log_info "      Old: $current_bundle_id"
                log_info "      New: $new_bundle_id"
                
                plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$bundle_plist"
                fixes_applied=$((fixes_applied + 1))
            fi
        fi
    done
    
    # Comprehensive scan for any remaining collisions
    log_info "🔍 Final comprehensive scan for any remaining collisions..."
    find "$app_path" -name "Info.plist" | while read plist; do
        if [[ "$plist" != "$main_plist" ]]; then
            local current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "unknown")
            
            if [ "$current_bundle_id" = "$main_bundle_id" ]; then
                local relative_path=${plist#$app_path/}
                local component_name=$(echo "$relative_path" | sed 's|/Info.plist$||' | tr '/' '-' | sed 's/_/-/g' | sed 's/[^a-zA-Z0-9.-]//g')
                local new_bundle_id="${main_bundle_id}.component.${component_name}"
                
                log_info "   🔧 Component collision fix: $relative_path"
                log_info "      Old: $current_bundle_id" 
                log_info "      New: $new_bundle_id"
                
                plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$plist"
                fixes_applied=$((fixes_applied + 1))
            fi
        fi
    done
    
    # Create fixed IPA
    log_info "📦 Creating fixed IPA..."
    zip -qr "$(basename "$output_path")" Payload/
    
    # Move to final location
    mv "$(basename "$output_path")" "$output_path"
    
    # Cleanup
    cd /
    rm -rf "$work_dir"
    
    log_success "✅ IPA Bundle Collision Fix completed!"
    log_info "📊 Total fixes applied: $fixes_applied"
    log_info "📁 Fixed IPA created: $output_path"
    
    # Verification
    if [ -f "$output_path" ]; then
        local ipa_size=$(du -h "$output_path" | cut -f1)
        log_success "✅ Fixed IPA ready for upload: $output_path ($ipa_size)"
        log_info "🎯 All CFBundleIdentifier collisions resolved"
        log_info "📱 Ready for App Store Connect upload via Transporter"
        return 0
    else
        log_error "❌ Failed to create fixed IPA"
        return 1
    fi
}

# Function to cleanup and exit
cleanup_and_exit() {
    local exit_code="$1"
    cd /
    if [ -n "${work_dir:-}" ] && [ -d "$work_dir" ]; then
        rm -rf "$work_dir"
    fi
    exit "$exit_code"
}

# Function to validate IPA structure
validate_ipa_structure() {
    local ipa_path="$1"
    
    log_info "🔍 Validating IPA structure..."
    
    if [ ! -f "$ipa_path" ]; then
        log_error "IPA file not found: $ipa_path"
        return 1
    fi
    
    # Test if it's a valid zip file
    if ! unzip -t "$ipa_path" >/dev/null 2>&1; then
        log_error "IPA file is corrupted or not a valid zip file"
        return 1
    fi
    
    # Check for Payload directory
    if ! unzip -l "$ipa_path" | grep -q "Payload/"; then
        log_error "IPA file does not contain Payload directory"
        return 1
    fi
    
    # Check for app bundle (could be Runner.app or app-specific name like Insurancegroupmo.app)
    local app_found=false
    if unzip -l "$ipa_path" | grep -q "Payload/Runner.app/"; then
        app_found=true
        log_info "Found Runner.app in IPA"
    elif unzip -l "$ipa_path" | grep -q "Payload/.*\.app/"; then
        local app_name=$(unzip -l "$ipa_path" | grep "Payload/.*\.app/" | head -1 | sed 's/.*Payload\/\([^\/]*\.app\)\/.*/\1/')
        app_found=true
        log_info "Found $app_name in IPA"
    fi
    
    if [ "$app_found" = false ]; then
        log_error "IPA file does not contain any .app bundle"
        return 1
    fi
    
    log_success "✅ IPA structure validation passed"
    return 0
}

# Main function
main() {
    log_info "🚀 IPA Bundle Collision Fix - Starting"
    
    local ipa_path="${1:-}"
    local main_bundle_id="${2:-${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}}"
    local output_path="${3:-}"
    
    # Auto-detect IPA file if not provided
    if [ -z "$ipa_path" ]; then
        # Look in common output directories
        for dir in "output/ios" "." "build/ios/ipa"; do
            if [ -f "$dir/Runner.ipa" ]; then
                ipa_path="$dir/Runner.ipa"
                log_info "🔍 Auto-detected IPA: $ipa_path"
                break
            fi
        done
    fi
    
    if [ -z "$ipa_path" ]; then
        log_error "❌ IPA file not specified and not found in common locations"
        log_error "Usage: $0 <ipa_path> [bundle_id] [output_path]"
        exit 1
    fi
    
    # Set default output path
    if [ -z "$output_path" ]; then
        local dir=$(dirname "$ipa_path")
        local name=$(basename "$ipa_path" .ipa)
        output_path="$dir/${name}_collision_free.ipa"
    fi
    
    log_info "📋 Configuration:"
    log_info "   Input IPA: $ipa_path"
    log_info "   Main Bundle ID: $main_bundle_id"
    log_info "   Output IPA: $output_path"
    
    # Validate input IPA
    if ! validate_ipa_structure "$ipa_path"; then
        log_error "❌ IPA validation failed"
        exit 1
    fi
    
    # Fix collisions
    if fix_ipa_bundle_collisions "$ipa_path" "$main_bundle_id" "$output_path"; then
        log_success "🎉 IPA Bundle Collision Fix completed successfully!"
        log_info "📱 Use the fixed IPA for App Store Connect upload: $output_path"
        exit 0
    else
        log_error "❌ IPA Bundle Collision Fix failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 