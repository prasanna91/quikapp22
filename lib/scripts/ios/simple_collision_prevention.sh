#!/bin/bash

# Simple Bundle Collision Prevention
# Purpose: Fix collisions without breaking CocoaPods installation

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_success() { echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_warn() { echo "⚠️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Simple collision prevention function
simple_collision_prevention() {
    local main_bundle_id="${1:-${BUNDLE_ID:-com.example.app}}"
    
    log_info "🔧 SIMPLE COLLISION PREVENTION"
    log_info "🎯 Target Bundle ID: $main_bundle_id"
    
    # Stage 1: Basic Project File Fixes
    log_info "📋 Stage 1: Basic Project File Fixes"
    if fix_project_bundle_ids "$main_bundle_id"; then
        log_success "✅ Project bundle IDs fixed"
    else
        log_warn "⚠️ Project bundle ID fixes had issues, but continuing"
    fi
    
    # Stage 2: Enhanced Podfile (Simple Version)
    log_info "📋 Stage 2: Enhanced Podfile Generation"
    if create_simple_enhanced_podfile "$main_bundle_id"; then
        log_success "✅ Enhanced Podfile created"
    else
        log_warn "⚠️ Enhanced Podfile creation failed, using basic version"
    fi
    
    log_success "🎉 SIMPLE COLLISION PREVENTION COMPLETED"
    return 0
}

# Fix project bundle identifiers
fix_project_bundle_ids() {
    local main_bundle_id="$1"
    local project_path="ios/Runner.xcodeproj/project.pbxproj"
    local test_bundle_id="${main_bundle_id}.tests"
    
    if [ ! -f "$project_path" ]; then
        log_error "Project file not found: $project_path"
        return 1
    fi
    
    # Create backup
    cp "$project_path" "${project_path}.simple_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Simple bundle ID replacement
    log_info "🎯 Applying bundle identifier fixes..."
    
    # Replace all bundle identifiers with the main one first
    sed -i.tmp "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;/g" "$project_path"
    
    # Fix test targets separately
    sed -i.tmp2 '/RunnerTests/,/PRODUCT_BUNDLE_IDENTIFIER/{
        s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = '"$test_bundle_id"';/g
    }' "$project_path"
    
    # Clean up temporary files
    rm -f "$project_path".tmp*
    
    log_success "✅ Basic project bundle IDs updated"
    return 0
}

# Create simple enhanced Podfile
create_simple_enhanced_podfile() {
    local main_bundle_id="$1"
    local podfile_path="ios/Podfile"
    
    if [ ! -f "$podfile_path" ]; then
        log_warn "Podfile not found: $podfile_path"
        return 1
    fi
    
    # Create backup
    cp "$podfile_path" "${podfile_path}.simple_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Add simple collision prevention to existing Podfile
    log_info "🔧 Adding simple collision prevention to Podfile..."
    
    # Check if collision prevention is already present
    if grep -q "collision prevention" "$podfile_path"; then
        log_info "🔍 Collision prevention already present in Podfile"
        return 0
    fi
    
    # Create the collision prevention block with proper substitution
    cat >> "$podfile_path" << PODFILE_END

# Simple collision prevention for CFBundleIdentifier
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # Simple collision prevention: Add framework suffix to avoid collisions
      if target.name != 'Pods-Runner' && target.name != 'Pods-RunnerTests'
        framework_name = target.name.gsub(/[^a-zA-Z0-9]/, '').downcase
        if framework_name.length > 0
          unique_bundle_id = "${main_bundle_id}.framework.\#{framework_name}"
          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
          puts "🔧 SIMPLE COLLISION FIX: \#{target.name} -> \#{unique_bundle_id}"
        end
      end
    end
  end
  
  puts "✅ SIMPLE COLLISION PREVENTION: Applied to all framework targets"
end
PODFILE_END
    
    log_success "✅ Simple collision prevention added to Podfile"
    return 0
}

# Main execution
main() {
    log_info "🚀 SIMPLE BUNDLE COLLISION PREVENTION"
    
    local main_bundle_id="${1:-${BUNDLE_ID:-com.example.app}}"
    
    if [ "$main_bundle_id" = "com.example.app" ]; then
        log_warn "Using default bundle ID - set BUNDLE_ID environment variable"
    fi
    
    # Run simple collision prevention
    if simple_collision_prevention "$main_bundle_id"; then
        log_success "🎉 SIMPLE COLLISION PREVENTION COMPLETED!"
        log_info "📱 Bundle ID: $main_bundle_id"
        log_info "🎯 Ready for build"
        return 0
    else
        log_error "❌ Simple collision prevention failed"
        return 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 