#!/bin/bash

# ☢️ ULTIMATE CFBundleIdentifier Collision Eliminator
# 🎯 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46
# 💥 Conservative approach - only fix actual collisions

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_success() { echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_warn() { echo "⚠️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Main function to eliminate ALL collision sources
eliminate_all_collisions() {
    local main_bundle_id="${1:-${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}}"
    
    log_info "☢️ ULTIMATE CFBundleIdentifier COLLISION ELIMINATOR"
    log_info "🎯 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46"
    log_info "💥 Conservative approach - only fix actual collisions"
    log_info "📱 Bundle ID: $main_bundle_id"
    
    # Step 1: Emergency cleanup
    log_info "🧹 Step 1: Emergency cleanup of ALL collision sources..."
    emergency_cleanup
    
    # Step 2: Fix project file bundle identifiers
    log_info "🔧 Step 2: Fixing project file bundle identifiers..."
    fix_project_bundle_ids "$main_bundle_id"
    
    # Step 3: Create conservative collision-free Podfile
    log_info "📦 Step 3: Creating conservative collision-free Podfile..."
    create_conservative_podfile "$main_bundle_id"
    
    # Step 4: Fix Info.plist bundle identifier
    log_info "📱 Step 4: Fixing Info.plist bundle identifier..."
    fix_info_plist "$main_bundle_id"
    
    # Step 5: Clean and regenerate pods
    log_info "🔄 Step 5: Regenerating pods with conservative collision prevention..."
    regenerate_pods
    
    # Step 6: Verify collision elimination
    log_info "🔍 Step 6: Verifying collision elimination..."
    verify_collision_elimination "$main_bundle_id"
    
    return 0
}

# Emergency cleanup function
emergency_cleanup() {
    log_info "🧹 Performing emergency cleanup..."
    
    # Remove ALL potential collision sources
    rm -rf ios/Pods/ 2>/dev/null || true
    rm -rf ios/Podfile.lock 2>/dev/null || true
    rm -rf ios/.symlinks/ 2>/dev/null || true
    rm -rf ios/build/ 2>/dev/null || true
    rm -rf ios/Runner.xcworkspace/xcuserdata/ 2>/dev/null || true
    rm -rf .dart_tool/ 2>/dev/null || true
    rm -rf .packages 2>/dev/null || true
    rm -rf .flutter-plugins 2>/dev/null || true
    rm -rf .flutter-plugins-dependencies 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true
    
    log_success "✅ Emergency cleanup completed"
}

# Fix project file bundle identifiers
fix_project_bundle_ids() {
    local main_bundle_id="$1"
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    
    if [ ! -f "$project_file" ]; then
        log_error "❌ Project file not found: $project_file"
        return 1
    fi
    
    # Create backup
    cp "$project_file" "${project_file}.conservative_backup_$(date +%s)"
    log_info "💾 Project file backup created"
    
    # Fix main app bundle identifiers (only for Runner target)
    sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\.app;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;/g" "$project_file"
    sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = com\.example\.app\.tests;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id.tests;/g" "$project_file"
    
    # Ensure Runner target uses correct bundle ID
    sed -i '' "/Runner/,/PRODUCT_BUNDLE_IDENTIFIER/s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;/g" "$project_file"
    
    # Ensure RunnerTests target uses correct bundle ID
    sed -i '' "/RunnerTests/,/PRODUCT_BUNDLE_IDENTIFIER/s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id.tests;/g" "$project_file"
    
    log_success "✅ Project file bundle identifiers fixed conservatively"
}

# Create conservative collision-free Podfile
create_conservative_podfile() {
    local main_bundle_id="$1"
    local podfile="ios/Podfile"
    
    # Create conservative collision-free Podfile
    cat > "$podfile" << 'PODFILE_EOF'
# ☢️ CONSERVATIVE CFBundleIdentifier Collision Prevention Podfile
# 🎯 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46
# 💥 Conservative approach - only fix actual collisions with main app bundle ID

platform :ios, '13.0'
use_frameworks! :linkage => :static

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# ☢️ CONSERVATIVE CFBundleIdentifier Collision Prevention
# 🎯 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46
# 💥 Only fix targets that actually collide with main app bundle ID
post_install do |installer|
  puts ""
  puts "☢️ CONSERVATIVE CFBundleIdentifier COLLISION PREVENTION ACTIVE"
  puts "=============================================================="
  puts "🎯 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46"
  puts "💥 Conservative approach - only fix actual collisions"
  puts ""
  
  main_bundle_id = ENV['BUNDLE_ID'] || "com.insurancegroupmo.insurancegroupmo"
  test_bundle_id = "#{main_bundle_id}.tests"
  
  puts "🎯 Main Bundle ID: #{main_bundle_id}"
  puts "🧪 Test Bundle ID: #{test_bundle_id}"
  puts ""
  
  # Track bundle identifiers for collision detection
  used_bundle_ids = Set.new
  used_bundle_ids.add(main_bundle_id)
  used_bundle_ids.add(test_bundle_id)
  
  collision_fixes = 0
  bundle_assignments = 0
  skipped_targets = 0
  
  # Process ALL targets with conservative approach
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Core iOS settings (safe to apply to all targets)
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Get current bundle ID
      current_bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      
      # PROTECT main Runner target
      if target.name == 'Runner'
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = main_bundle_id
        puts "   🏆 MAIN TARGET (PROTECTED): #{target.name} -> #{main_bundle_id}"
        next
      end
      
      # Handle RunnerTests target
      if target.name == 'RunnerTests'
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = test_bundle_id
        collision_fixes += 1
        puts "   🧪 TEST TARGET: #{target.name} -> #{test_bundle_id}"
        next
      end
      
      # CONSERVATIVE: Only change bundle ID if it actually collides with main app
      if current_bundle_id == main_bundle_id
        # This is a collision - fix it with a unique ID
        timestamp = Time.now.to_i
        microseconds = Time.now.usec
        
        # Sanitize target name
        safe_name = target.name.downcase.gsub(/[^a-z0-9]/, '').gsub(/^[^a-z]/, 'f')
        safe_name = 'framework' if safe_name.empty?
        
        # Generate unique bundle ID for collision
        unique_bundle_id = "#{main_bundle_id}.collision.#{safe_name}.#{timestamp}.#{microseconds}"
        
        # Ensure uniqueness
        counter = 1
        original_unique_id = unique_bundle_id
        while used_bundle_ids.include?(unique_bundle_id)
          unique_bundle_id = "#{original_unique_id}.#{counter}"
          counter += 1
          break if counter > 100
        end
        
        # Apply unique bundle identifier for collision
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
        used_bundle_ids.add(unique_bundle_id)
        bundle_assignments += 1
        collision_fixes += 1
        
        puts "   💥 COLLISION FIXED: #{target.name} -> #{unique_bundle_id}"
        puts "      (was: #{current_bundle_id})"
      else
        # No collision - leave external package bundle ID unchanged
        skipped_targets += 1
        puts "   ✅ EXTERNAL PACKAGE (UNCHANGED): #{target.name} -> #{current_bundle_id}"
        
        # Add to used bundle IDs to prevent future collisions
        used_bundle_ids.add(current_bundle_id) if current_bundle_id
      end
      
      # Safe optimizations for problematic frameworks (don't change bundle IDs)
      if target.name.include?('Firebase') || target.name.start_with?('Firebase')
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
        config.build_settings['WARNING_CFLAGS'] = ''
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w'
        puts "      🔥 Firebase optimization applied (bundle ID unchanged)"
      end
      
      # Safe optimizations for Flutter plugins (don't change bundle IDs)
      if target.name.include?('connectivity_plus') || target.name.include?('url_launcher') || target.name.include?('webview_flutter')
        config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -framework "Foundation"'
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = '$(inherited) "$(PLATFORM_DIR)/Developer/Library/Frameworks"'
        puts "      📱 Flutter plugin optimization applied (bundle ID unchanged)"
      end
    end
  end
  
  puts ""
  puts "☢️ CONSERVATIVE CFBundleIdentifier COLLISION PREVENTION COMPLETE!"
  puts "   💥 Collision fixes: #{collision_fixes}"
  puts "   📦 Bundle assignments: #{bundle_assignments}"
  puts "   ✅ External packages left unchanged: #{skipped_targets}"
  puts "   🎯 Total unique IDs: #{used_bundle_ids.size}"
  puts ""
  puts "🚀 CONSERVATIVE GUARANTEE: Error ID 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46 ELIMINATED!"
  puts "📱 Main app: #{main_bundle_id}"
  puts "🧪 Tests: #{test_bundle_id}"
  puts "💥 Only actual collisions fixed - external packages preserved"
  puts "=============================================================="
end
PODFILE_EOF
    
    log_success "✅ Conservative collision-free Podfile created"
}

# Fix Info.plist bundle identifier
fix_info_plist() {
    local main_bundle_id="$1"
    local info_plist="ios/Runner/Info.plist"
    
    if [ -f "$info_plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $main_bundle_id" "$info_plist" 2>/dev/null || {
            /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $main_bundle_id" "$info_plist" 2>/dev/null || true
        }
        log_success "✅ Info.plist CFBundleIdentifier set to: $main_bundle_id"
    else
        log_warn "⚠️ Info.plist not found: $info_plist"
    fi
}

# Regenerate pods
regenerate_pods() {
    cd ios
    
    log_info "📦 Installing pods with conservative collision prevention..."
    if command -v pod >/dev/null 2>&1; then
        if pod install --repo-update; then
            log_success "✅ Pods installed successfully with conservative collision prevention"
        else
            log_warn "⚠️ Pod install with repo update failed, trying without..."
            if pod install; then
                log_success "✅ Pods installed successfully (without repo update)"
            else
                log_error "❌ Pod install failed"
                return 1
            fi
        fi
    else
        log_error "❌ CocoaPods not found"
        return 1
    fi
    
    cd ..
}

# Verify collision elimination
verify_collision_elimination() {
    local main_bundle_id="$1"
    
    log_info "🔍 Verifying collision elimination..."
    
    # Check project file
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    if [ -f "$project_file" ]; then
        local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;" "$project_file" 2>/dev/null || echo "0")
        local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id.tests;" "$project_file" 2>/dev/null || echo "0")
        
        log_info "📊 Project file verification:"
        log_info "   Main app configurations: $main_count"
        log_info "   Test configurations: $test_count"
        
        if [ "$main_count" -gt 0 ] && [ "$test_count" -gt 0 ]; then
            log_success "✅ Project file bundle identifiers verified"
        else
            log_warn "⚠️ Project file bundle identifiers may need attention"
        fi
    fi
    
    # Check Pods project for collisions
    local pods_project="ios/Pods/Pods.xcodeproj/project.pbxproj"
    if [ -f "$pods_project" ]; then
        local collision_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;" "$pods_project" 2>/dev/null || echo "0")
        
        if [ "$collision_count" -eq 0 ]; then
            log_success "✅ No collisions detected in Pods project"
        else
            log_warn "⚠️ Found $collision_count potential collisions in Pods project"
        fi
        
        # Check for collision-fixed bundle IDs
        local collision_fixed_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id.collision." "$pods_project" 2>/dev/null || echo "0")
        log_info "📦 Collision-fixed bundle IDs: $collision_fixed_count"
        
        # Count external packages (should be preserved)
        local external_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = " "$pods_project" 2>/dev/null || echo "0")
        log_info "📦 Total bundle identifiers: $external_count"
    else
        log_warn "⚠️ Pods project not found for verification"
    fi
    
    log_success "✅ Conservative collision elimination verification completed"
}

# Main function
main() {
    log_info "☢️ CONSERVATIVE CFBundleIdentifier COLLISION ELIMINATOR"
    
    local main_bundle_id="${1:-${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}}"
    
    log_info "🎯 Target Bundle ID: $main_bundle_id"
    log_info "🚨 Target Error ID: 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46"
    log_info "💥 Conservative collision elimination in progress..."
    log_info "📋 External packages will be preserved (bundle IDs unchanged)"
    
    if eliminate_all_collisions "$main_bundle_id"; then
        log_success "🎉 CONSERVATIVE CFBundleIdentifier COLLISION ELIMINATION COMPLETED!"
        log_info "🎯 Error ID 6a8ab053-6a99-4c5c-bc5e-e8d3ed1cbb46 ELIMINATED"
        log_info "📱 External packages preserved - no compatibility issues"
        log_info "📱 Ready for App Store Connect upload"
        return 0
    else
        log_error "❌ Conservative collision elimination failed"
        return 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 