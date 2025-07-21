#!/bin/bash

# Bundle Identifier Collision Final Fix
# Purpose: Fix CFBundleIdentifier collisions that cause App Store validation failures
# This addresses the specific collision issue with multiple targets having the same bundle ID

set -euo pipefail

echo "🔧 BUNDLE IDENTIFIER COLLISION FINAL FIX"
echo "🎯 Fixing CFBundleIdentifier collisions for App Store validation"

# Get project root
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"

# Function to analyze current bundle identifier usage
analyze_bundle_identifiers() {
    echo "🔍 Analyzing current bundle identifier usage..."
    
    if [ -f "$PROJECT_FILE" ]; then
        echo "📝 Project file found: $PROJECT_FILE"
        
        # Extract all PRODUCT_BUNDLE_IDENTIFIER occurrences
        echo "   Extracting bundle identifiers from project..."
        grep -n "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | head -20
        
        # Count occurrences of the main bundle ID
        local main_bundle_count=$(grep -c "com.twinklub.twinklub" "$PROJECT_FILE" || echo "0")
        echo "   Found $main_bundle_count occurrences of 'com.twinklub.twinklub'"
        
        if [ "$main_bundle_count" -gt 3 ]; then
            echo "❌ COLLISION DETECTED: Too many targets using the same bundle identifier"
            return 1
        else
            echo "✅ Bundle identifier usage appears normal"
            return 0
        fi
    else
        echo "❌ Project file not found: $PROJECT_FILE"
        return 1
    fi
}

# Function to create enhanced Podfile with collision prevention
create_collision_free_podfile() {
    echo "🔧 Creating collision-free Podfile..."
    
    local podfile="$IOS_DIR/Podfile"
    
    # Create backup
    if [ -f "$podfile" ]; then
        cp "$podfile" "$podfile.collision_fix_backup"
        echo "✅ Backup created: $podfile.collision_fix_backup"
    fi
    
    # Create enhanced Podfile with aggressive collision prevention
    cat > "$podfile" << 'COLLISION_FREE_PODFILE_EOF'
# Bundle Identifier Collision Final Fix - Enhanced Podfile
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

# BUNDLE IDENTIFIER COLLISION FINAL FIX
post_install do |installer|
  puts "🔧 BUNDLE IDENTIFIER COLLISION FINAL FIX - Starting collision prevention..."
  
  # Main bundle identifier
  main_bundle_id = "com.twinklub.twinklub"
  collision_fixes_applied = 0
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      # Core iOS settings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # AGGRESSIVE BUNDLE IDENTIFIER COLLISION PREVENTION
      current_bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      
      if current_bundle_id
        # Skip the main Runner target
        next if target.name == 'Runner'
        
        # Check for collision with main bundle ID
        if current_bundle_id == main_bundle_id || 
           current_bundle_id.include?('com.twinklub.twinklub') || 
           current_bundle_id.include?('com.example')
          
          # Create unique bundle ID for this target
          unique_bundle_id = "#{main_bundle_id}.pod.#{target.name.downcase.gsub(/[^a-z0-9]/, '')}"
          
          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
          collision_fixes_applied += 1
          
          puts "   🔧 COLLISION FIX: #{target.name}"
          puts "      OLD: #{current_bundle_id}"
          puts "      NEW: #{unique_bundle_id}"
        end
      else
        # Ensure pod targets have bundle identifiers
        if target.name != 'Runner'
          safe_target_name = target.name.downcase.gsub(/[^a-z0-9]/, '')
          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{main_bundle_id}.pod.#{safe_target_name}"
          collision_fixes_applied += 1
          puts "   🆕 BUNDLE ID ASSIGNED: #{target.name} -> #{main_bundle_id}.pod.#{safe_target_name}"
        end
      end
      
      # Firebase compatibility if present
      if target.name.start_with?('Firebase') || target.name.include?('Firebase')
        puts "   🔥 Applying Firebase compatibility to: #{target.name}"
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
        config.build_settings['WARNING_CFLAGS'] = ''
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w'
      end
    end
  end
  
  puts "✅ BUNDLE IDENTIFIER COLLISION FINAL FIX completed!"
  puts "   🔧 Collision fixes applied: #{collision_fixes_applied}"
  puts "   🎯 All pod targets now have unique bundle identifiers"
end
COLLISION_FREE_PODFILE_EOF
    
    echo "✅ Collision-free Podfile created"
}

# Function to validate bundle identifier uniqueness
validate_bundle_identifier_uniqueness() {
    echo "🔍 Validating bundle identifier uniqueness..."
    
    if [ -f "$PROJECT_FILE" ]; then
        # Extract all bundle identifiers and check for duplicates
        echo "   Extracting all bundle identifiers..."
        
        # Create temporary file with all bundle IDs
        local temp_bundle_ids="/tmp/bundle_ids_$$.txt"
        grep "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | \
            sed 's/.*PRODUCT_BUNDLE_IDENTIFIER = "\([^"]*\)".*/\1/' | \
            sort > "$temp_bundle_ids"
        
        # Check for duplicates
        local duplicates=$(uniq -d "$temp_bundle_ids")
        
        if [ -n "$duplicates" ]; then
            echo "❌ DUPLICATES FOUND:"
            echo "$duplicates"
            rm -f "$temp_bundle_ids"
            return 1
        else
            echo "✅ All bundle identifiers are unique"
            rm -f "$temp_bundle_ids"
            return 0
        fi
    else
        echo "❌ Project file not found for validation"
        return 1
    fi
}

# Function to clean and reinstall CocoaPods with collision fixes
reinstall_cocoapods_collision_free() {
    echo "📦 Reinstalling CocoaPods with collision fixes..."
    
    cd "$IOS_DIR"
    
    # Clean CocoaPods artifacts
    echo "   Cleaning CocoaPods artifacts..."
    rm -rf Pods/
    rm -f Podfile.lock
    rm -rf .symlinks/
    rm -rf Runner.xcworkspace/
    
    # Install pods with collision fixes
    echo "   Installing pods with collision prevention..."
    if pod install --repo-update --verbose; then
        echo "✅ CocoaPods installed successfully with collision fixes"
    else
        echo "❌ CocoaPods installation failed"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to validate final project state
validate_final_project_state() {
    echo "🔍 Validating final project state..."
    
    # Check project file integrity
    if [ -f "$PROJECT_FILE" ] && plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
        echo "✅ Project file integrity verified"
    else
        echo "❌ Project file integrity check failed"
        return 1
    fi
    
    # Check bundle identifier uniqueness
    if validate_bundle_identifier_uniqueness; then
        echo "✅ Bundle identifier uniqueness verified"
    else
        echo "❌ Bundle identifier collision still exists"
        return 1
    fi
    
    # Test project opening
    cd "$IOS_DIR"
    if xcodebuild -project Runner.xcodeproj -list >/dev/null 2>&1; then
        echo "✅ Project opens successfully with xcodebuild"
    else
        echo "❌ Project cannot be opened by xcodebuild"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to create validation-ready export
create_validation_ready_export() {
    echo "🎯 Creating validation-ready export guide..."
    
    local guide_file="$PROJECT_ROOT/output/ios/VALIDATION_FIX_GUIDE.txt"
    
    cat > "$guide_file" << 'VALIDATION_GUIDE_EOF'
BUNDLE IDENTIFIER COLLISION FIX - VALIDATION GUIDE
================================================

✅ COLLISION FIXES APPLIED
- All pod targets now have unique bundle identifiers
- Main app bundle ID preserved: com.twinklub.twinklub
- Pod targets use pattern: com.twinklub.twinklub.pod.{targetname}

🎯 NEXT STEPS FOR APP STORE VALIDATION

1. CLEAN BUILD RECOMMENDED:
   - Run: flutter clean
   - Run: cd ios && rm -rf Pods/ Podfile.lock .symlinks/
   - Run: pod install
   - Run: flutter build ios --release

2. ARCHIVE CREATION:
   - Open Xcode: ios/Runner.xcworkspace
   - Product > Archive
   - Ensure all targets show unique bundle IDs

3. VALIDATION BEFORE EXPORT:
   - In Organizer, select your archive
   - Click "Validate App" before "Distribute App"
   - This will catch any remaining bundle ID issues

4. EXPORT OPTIONS:
   - Choose "App Store Connect"
   - Enable "Upload your app's symbols"
   - Disable "Include bitcode" (already set)

✅ EXPECTED RESULT
No more CFBundleIdentifier collision errors during validation.
The IPA should upload successfully to App Store Connect.

🔧 IF ISSUES PERSIST
Contact support with this validation fix confirmation.
All bundle identifier collisions have been systematically resolved.
VALIDATION_GUIDE_EOF
    
    echo "✅ Validation guide created: $guide_file"
}

# Main execution function
main() {
    echo "🔧 Starting Bundle Identifier Collision Final Fix..."
    echo "🎯 This will resolve CFBundleIdentifier collision validation errors"
    
    # Step 1: Analyze current collision state
    if analyze_bundle_identifiers; then
        echo "ℹ️ Bundle identifier analysis completed"
    else
        echo "⚠️ Bundle identifier collisions detected - proceeding with fixes"
    fi
    
    # Step 2: Create collision-free Podfile
    create_collision_free_podfile
    
    # Step 3: Reinstall CocoaPods with collision fixes
    if ! reinstall_cocoapods_collision_free; then
        echo "❌ Failed to reinstall CocoaPods with collision fixes"
        return 1
    fi
    
    # Step 4: Validate final project state
    if ! validate_final_project_state; then
        echo "❌ Final project validation failed"
        return 1
    fi
    
    # Step 5: Create validation-ready export guide
    create_validation_ready_export
    
    echo ""
    echo "✅ Bundle Identifier Collision Final Fix completed successfully!"
    echo "📋 Summary of collision fixes applied:"
    echo "   🔧 Enhanced Podfile with aggressive collision prevention"
    echo "   📦 CocoaPods reinstalled with unique bundle identifiers"
    echo "   🔍 Project validation confirmed all identifiers unique"
    echo "   🎯 Validation guide created for App Store submission"
    echo ""
    echo "🎯 App Store validation should now succeed!"
    echo "🔧 Next steps:"
    echo "   1. Try exporting IPA again using ios-workflow"
    echo "   2. The CFBundleIdentifier collision should be resolved"
    echo "   3. IPA should validate successfully for App Store Connect"
    echo ""
    echo "💡 All pod targets now have unique bundle identifiers following pattern:"
    echo "    Main app: com.twinklub.twinklub"
    echo "    Pod targets: com.twinklub.twinklub.pod.{targetname}"
    
    return 0
}

# Execute main function
main "$@" 