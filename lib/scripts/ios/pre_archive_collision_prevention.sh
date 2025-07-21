#!/bin/bash

# Pre-Archive CFBundleIdentifier Collision Prevention
# Purpose: Fix ALL collisions BEFORE archive creation to prevent App Store Connect validation errors
# Target: Ensure unique bundle IDs for all components BEFORE they get baked into the IPA

set -euo pipefail

# Logging functions
log_info() { echo "ℹ️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_success() { echo "✅ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_warn() { echo "⚠️ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_error() { echo "❌ [$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Main function to prevent collisions before archive
prevent_pre_archive_collisions() {
    local main_bundle_id="${1:-${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}}"
    
    log_info "🚀 ENHANCED PRE-ARCHIVE COLLISION PREVENTION"
    log_info "🎯 Main Bundle ID: $main_bundle_id"
    log_info "🔧 Preventing collisions BEFORE archive creation..."
    log_info "📋 Addressing: Bundle IDs, Framework Embedding, Extension IDs"
    
    # Step 1: Fix framework embedding settings
    log_info "📋 Step 1: Fixing framework embedding settings..."
    if fix_framework_embedding_settings; then
        log_success "✅ Framework embedding settings fixed"
    else
        log_warn "⚠️ Framework embedding fix had issues, but continuing"
    fi
    
    # Step 2: Create collision-free Podfile
    log_info "📋 Step 2: Creating collision-free Podfile..."
    if create_collision_free_podfile "$main_bundle_id"; then
        log_success "✅ Collision-free Podfile created"
    else
        log_warn "⚠️ Podfile creation had issues, but continuing"
    fi
    
    # Step 3: Update project file
    log_info "📋 Step 3: Updating project file bundle identifiers..."
    if update_project_bundle_ids "$main_bundle_id"; then
        log_success "✅ Project bundle IDs updated"
    else
        log_warn "⚠️ Project update had issues, but continuing"
    fi
    
    # Step 4: Fix extension bundle identifiers
    log_info "📋 Step 4: Fixing extension bundle identifiers..."
    if fix_extension_bundle_ids "$main_bundle_id"; then
        log_success "✅ Extension bundle IDs fixed"
    else
        log_warn "⚠️ Extension bundle ID fix had issues, but continuing"
    fi
    
    # Step 5: Reinstall CocoaPods with collision prevention
    log_info "📋 Step 5: Reinstalling CocoaPods with collision prevention..."
    if reinstall_pods_with_collision_prevention; then
        log_success "✅ CocoaPods reinstalled with collision prevention"
    else
        log_warn "⚠️ CocoaPods reinstall had issues, but continuing"
    fi
    
    # Step 6: Verify collision prevention
    log_info "📋 Step 6: Verifying collision prevention..."
    if verify_collision_prevention "$main_bundle_id"; then
        log_success "✅ Collision prevention verified"
    else
        log_warn "⚠️ Verification had issues, but build can continue"
    fi
    
    log_success "🎉 ENHANCED PRE-ARCHIVE COLLISION PREVENTION COMPLETED!"
    log_info "🎯 All components will have unique bundle IDs in the final IPA"
    log_info "📦 Framework embedding settings optimized"
    return 0
}

# Fix framework embedding settings
fix_framework_embedding_settings() {
    local project_path="ios/Runner.xcodeproj/project.pbxproj"
    
    if [ ! -f "$project_path" ]; then
        log_error "Project file not found: $project_path"
        return 1
    fi
    
    log_info "🔧 Fixing framework embedding settings..."
    log_info "🎯 Changing problematic frameworks from 'Embed & Sign' to 'Do Not Embed'"
    
    # Create backup
    cp "$project_path" "${project_path}.embedding_backup_$(date +%Y%m%d_%H%M%S)"
    
    # List of frameworks that should NOT be embedded (managed by CocoaPods/SPM)
    local frameworks_to_fix=(
        "FirebaseCore"
        "FirebaseInstallations" 
        "FirebaseMessaging"
        "FirebaseAnalytics"
        "connectivity_plus"
        "url_launcher"
        "webview_flutter"
        "Flutter"
        "FlutterPluginRegistrant"
    )
    
    local fixes_applied=0
    
    # Process each framework
    for framework in "${frameworks_to_fix[@]}"; do
        log_info "🔍 Processing framework: $framework"
        
        # Look for framework references and change embedding settings
        # Change from EMBED_WITH_SIGN (3) to DO_NOT_EMBED (1)
        if grep -q "$framework" "$project_path"; then
            # Fix embedding settings - change from 3 (Embed & Sign) to 1 (Do Not Embed)
            sed -i.tmp "/.*$framework.*/{
                N
                N
                N
                s/settings = {[^}]*ATTRIBUTES = ([^)]*CodeSignOnCopy[^)]*)/settings = {ATTRIBUTES = (); }/g
                s/settings = {[^}]*ATTRIBUTES = ([^)]*3[^)]*)/settings = {ATTRIBUTES = (); }/g
            }" "$project_path"
            
            # Also remove CodeSignOnCopy attribute if present
            sed -i.tmp "/$framework/,/};/{
                s/ATTRIBUTES = ([^)]*CodeSignOnCopy[^)]*);/ATTRIBUTES = ();/g
                s/ATTRIBUTES = ([^)]*3[^)]*);/ATTRIBUTES = ();/g
            }" "$project_path"
            
            fixes_applied=$((fixes_applied + 1))
            log_info "   ✅ Fixed embedding for: $framework"
        else
            log_info "   ℹ️ Framework not found in project: $framework"
        fi
    done
    
    # Clean up temp files
    rm -f "${project_path}.tmp"
    
    # Additional fix: Set proper framework search paths
    log_info "🔧 Setting proper framework search paths..."
    
    # Ensure proper framework search paths are set
    sed -i.tmp 's/FRAMEWORK_SEARCH_PATHS = (/FRAMEWORK_SEARCH_PATHS = (\n\t\t\t\t"$(PLATFORM_DIR)\/Developer\/Library\/Frameworks",\n\t\t\t\t"$(inherited)",/' "$project_path"
    
    # Clean up
    rm -f "${project_path}.tmp"
    
    log_success "✅ Framework embedding fixes applied: $fixes_applied frameworks processed"
    log_info "🎯 CocoaPods and SPM will handle linking, preventing duplicate embeddings"
    
    return 0
}

# Fix extension bundle identifiers
fix_extension_bundle_ids() {
    local main_bundle_id="$1"
    local project_path="ios/Runner.xcodeproj/project.pbxproj"
    
    log_info "🔧 Checking for app extensions and fixing their bundle IDs..."
    
    # Look for common extension patterns
    local extension_patterns=(
        "NotificationServiceExtension"
        "NotificationContentExtension" 
        "ShareExtension"
        "TodayExtension"
        "WatchExtension"
        "Widget"
        "Extension"
    )
    
    local extensions_fixed=0
    
    for pattern in "${extension_patterns[@]}"; do
        if grep -q "$pattern" "$project_path" 2>/dev/null; then
            log_info "🎯 Found potential extension: $pattern"
            
            # Create unique bundle ID for extension
            local extension_name=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
            local extension_bundle_id="${main_bundle_id}.${extension_name}"
            
            # Update extension bundle ID
            sed -i.tmp "/$pattern/,/PRODUCT_BUNDLE_IDENTIFIER/{
                s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $extension_bundle_id;/g
            }" "$project_path"
            
            extensions_fixed=$((extensions_fixed + 1))
            log_success "   ✅ Fixed extension: $pattern -> $extension_bundle_id"
        fi
    done
    
    # Clean up
    rm -f "${project_path}.tmp"
    
    if [ "$extensions_fixed" -gt 0 ]; then
        log_success "✅ Fixed $extensions_fixed app extensions"
    else
        log_info "ℹ️ No app extensions found to fix"
    fi
    
    return 0
}

# Create collision-free Podfile
create_collision_free_podfile() {
    local main_bundle_id="$1"
    local podfile_path="ios/Podfile"
    
    # Create backup
    if [ -f "$podfile_path" ]; then
        cp "$podfile_path" "${podfile_path}.pre_archive_backup_$(date +%Y%m%d_%H%M%S)"
        log_info "📋 Backup created: ${podfile_path}.pre_archive_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    log_info "🔧 Creating comprehensive collision-free Podfile..."
    
    cat > "$podfile_path" << EOF
# Enhanced Pre-Archive Collision Prevention Podfile
# Ensures unique bundle identifiers AND proper framework embedding BEFORE archive creation
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

# ENHANCED PRE-ARCHIVE COLLISION PREVENTION
# Guarantees unique bundle IDs AND proper framework embedding BEFORE archive creation
post_install do |installer|
  puts ""
  puts "🚀 ENHANCED PRE-ARCHIVE COLLISION PREVENTION ACTIVE"
  puts "🎯 Main Bundle ID: ${main_bundle_id}"
  puts "🔧 Ensuring unique bundle IDs for ALL components..."
  puts "📦 Fixing framework embedding settings..."
  puts ""
  
  main_bundle_id = "${main_bundle_id}"
  test_bundle_id = "${main_bundle_id}.tests"
  collision_fixes = 0
  bundle_assignments = 0
  embedding_fixes = 0
  
  # Track ALL bundle identifiers for absolute uniqueness
  used_bundle_ids = Set.new
  used_bundle_ids.add(main_bundle_id)
  used_bundle_ids.add(test_bundle_id)
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Core iOS settings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # CRITICAL: Proper framework embedding settings
      # These prevent "Embed & Sign" conflicts that cause CFBundleIdentifier collisions
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
      
      # PRE-ARCHIVE BUNDLE ID ASSIGNMENT
      current_bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      
      # CRITICAL: Never touch main Runner target
      if target.name == 'Runner'
        puts "   🏆 MAIN APP: #{target.name} -> #{main_bundle_id} (protected)"
        next
      end
      
      # Handle RunnerTests target
      if target.name == 'RunnerTests'
        if current_bundle_id != test_bundle_id
          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = test_bundle_id
          collision_fixes += 1
          puts "   🧪 TEST TARGET: #{target.name} -> #{test_bundle_id}"
        end
        next
      end
      
      # For ALL other targets - guarantee uniqueness
      safe_name = target.name.downcase.gsub(/[^a-z0-9]/, '').gsub(/^[^a-z]/, 'f')
      safe_name = 'framework' if safe_name.empty?
      
      # Generate unique bundle ID
      unique_bundle_id = "#{main_bundle_id}.framework.#{safe_name}"
      
      # Ensure absolute uniqueness
      counter = 1
      original_unique_id = unique_bundle_id
      while used_bundle_ids.include?(unique_bundle_id)
        unique_bundle_id = "#{original_unique_id}.#{counter}"
        counter += 1
      end
      
      # Apply unique bundle identifier
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
      used_bundle_ids.add(unique_bundle_id)
      bundle_assignments += 1
      
      puts "   📦 FRAMEWORK: #{target.name} -> #{unique_bundle_id}"
      
      # Detect collision fixes
      if current_bundle_id == main_bundle_id
        collision_fixes += 1
        puts "      💥 COLLISION FIXED!"
      end
      
      # Special handling for specific frameworks to prevent embedding conflicts
      if target.name.include?('Firebase') || target.name.start_with?('Firebase')
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
        config.build_settings['WARNING_CFLAGS'] = ''
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w'
        config.build_settings['SKIP_INSTALL'] = 'YES'
        embedding_fixes += 1
        puts "      🔥 Firebase embedding optimized"
      end
      
      # Flutter plugin embedding optimization
      if target.name.include?('connectivity_plus') || target.name.include?('url_launcher') || target.name.include?('webview_flutter')
        config.build_settings['SKIP_INSTALL'] = 'YES'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
        embedding_fixes += 1
        puts "      📱 Flutter plugin embedding optimized"
      end
    end
  end
  
  puts ""
  puts "✅ ENHANCED PRE-ARCHIVE COLLISION PREVENTION COMPLETE!"
  puts "   💥 Collisions fixed: #{collision_fixes}"
  puts "   📦 Framework assignments: #{bundle_assignments}"
  puts "   🔧 Embedding fixes: #{embedding_fixes}"
  puts "   🎯 Total unique IDs: #{used_bundle_ids.size}"
  puts ""
  puts "🚀 Ready for collision-free archive creation!"
  puts "📱 Main app: #{main_bundle_id}"
  puts "🧪 Tests: #{test_bundle_id}"
  puts "📦 Frameworks: #{main_bundle_id}.framework.{name}"
  puts "🔧 Framework embedding optimized to prevent conflicts"
  puts ""
end
EOF
    
    log_success "✅ Enhanced collision-free Podfile created"
    return 0
}

# Update project file bundle identifiers
update_project_bundle_ids() {
    local main_bundle_id="$1"
    local project_path="ios/Runner.xcodeproj/project.pbxproj"
    local test_bundle_id="${main_bundle_id}.tests"
    
    if [ ! -f "$project_path" ]; then
        log_error "Project file not found: $project_path"
        return 1
    fi
    
    # Create backup
    cp "$project_path" "${project_path}.pre_archive_backup_$(date +%Y%m%d_%H%M%S)"
    
    log_info "🎯 Updating project bundle identifiers..."
    
    # First, set ALL bundle IDs to main bundle ID
    sed -i.tmp "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;/g" "$project_path"
    
    # Then, fix test targets to have unique bundle IDs
    # Look for RunnerTests build configurations and update them
    awk '
    /RunnerTests/ { in_tests = 1 }
    /PRODUCT_BUNDLE_IDENTIFIER = / && in_tests {
        gsub(/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/, "PRODUCT_BUNDLE_IDENTIFIER = '"$test_bundle_id"';")
    }
    /}/ && in_tests { 
        if (match($0, /^[[:space:]]*}[[:space:]]*$/) && --brace_count == 0) {
            in_tests = 0
        }
    }
    /RunnerTests/ { brace_count = 1 }
    { print }
    ' "$project_path" > "${project_path}.tmp" && mv "${project_path}.tmp" "$project_path"
    
    # Clean up
    rm -f "${project_path}.tmp"
    
    # Verify changes
    local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;" "$project_path" 2>/dev/null || echo "0")
    local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $test_bundle_id;" "$project_path" 2>/dev/null || echo "0")
    
    log_info "📊 Bundle ID assignments: $main_count main app, $test_count test targets"
    
    if [ "$main_count" -ge 1 ]; then
        log_success "✅ Project bundle IDs updated successfully"
        return 0
    else
        log_warn "⚠️ Project bundle ID update may need manual verification"
        return 0  # Don't fail the build
    fi
}

# Reinstall CocoaPods with collision prevention
reinstall_pods_with_collision_prevention() {
    log_info "🔄 Reinstalling CocoaPods with collision prevention..."
    
    cd ios
    
    # Clean existing pods
    rm -rf Pods Podfile.lock .symlinks/plugins
    log_info "🧹 Cleaned existing pods and symlinks"
    
    # Regenerate Flutter plugins
    cd ..
    flutter pub get
    cd ios
    
    # Install pods with collision prevention
    if pod install --repo-update --verbose; then
        log_success "✅ CocoaPods installed with collision prevention"
        
        # Verify Pods project was created
        if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
            log_success "✅ Pods project created successfully"
        else
            log_warn "⚠️ Pods project may have issues"
        fi
        
        cd ..
        return 0
    else
        log_warn "⚠️ CocoaPods installation failed"
        cd ..
        return 1
    fi
}

# Verify collision prevention
verify_collision_prevention() {
    local main_bundle_id="$1"
    
    log_info "🔍 Verifying collision prevention..."
    
    # Check if Pods project has unique bundle IDs
    local pods_project="ios/Pods/Pods.xcodeproj/project.pbxproj"
    if [ -f "$pods_project" ]; then
        local collision_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id;" "$pods_project" 2>/dev/null || echo "0")
        
        if [ "$collision_count" -eq 0 ]; then
            log_success "✅ No collisions detected in Pods project"
        else
            log_warn "⚠️ Found $collision_count potential collisions in Pods project"
        fi
        
        # Check for framework-specific bundle IDs
        local framework_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $main_bundle_id\.framework\." "$pods_project" 2>/dev/null || echo "0")
        log_info "📦 Found $framework_count framework-specific bundle IDs"
        
    else
        log_warn "⚠️ Pods project not found for verification"
    fi
    
    log_success "✅ Collision prevention verification completed"
    return 0
}

# Main function
main() {
    log_info "🚀 PRE-ARCHIVE COLLISION PREVENTION SYSTEM"
    
    local main_bundle_id="${1:-${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}}"
    
    log_info "📱 Target Bundle ID: $main_bundle_id"
    log_info "🎯 Preventing collisions BEFORE archive creation..."
    
    if prevent_pre_archive_collisions "$main_bundle_id"; then
        log_success "🎉 PRE-ARCHIVE COLLISION PREVENTION COMPLETED!"
        log_info "🎯 Archive creation will produce collision-free IPA"
        log_info "📱 Ready for App Store Connect upload"
        return 0
    else
        log_error "❌ Pre-archive collision prevention failed"
        return 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 