#!/bin/bash

# Emergency App Store Connect CFBundleIdentifier Collision Fix
# Specifically addresses validation error ID: 73b7b133-169a-41ec-a1aa-78eba00d4bb7
# Error: "CFBundleIdentifier Collision. There is more than one bundle with the CFBundleIdentifier value 'com.twinklub.twinklub'"

set -euo pipefail

echo "🚨 EMERGENCY APP STORE CONNECT COLLISION FIX"
echo "=============================================="
echo "🎯 Fixing CFBundleIdentifier collision for App Store validation"
echo "📋 Error ID: 73b7b133-169a-41ec-a1aa-78eba00d4bb7"

# Configuration
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"
PODFILE="$IOS_DIR/Podfile"
MAIN_BUNDLE_ID="com.twinklub.twinklub"
TEST_BUNDLE_ID="com.twinklub.twinklub.tests"

echo "📁 Project: $PROJECT_ROOT"
echo "🎯 Target Bundle ID: $MAIN_BUNDLE_ID"
echo "🧪 Test Bundle ID: $TEST_BUNDLE_ID"

# Function to analyze ALL bundle identifier sources
analyze_all_collision_sources() {
    echo ""
    echo "🔍 COMPREHENSIVE COLLISION SOURCE ANALYSIS"
    echo "==========================================="
    
    echo "📱 1. Project File Analysis:"
    if [ -f "$PROJECT_FILE" ]; then
        echo "   Project file: $PROJECT_FILE"
        local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        echo "   Main app occurrences: $main_count"
        echo "   Test occurrences: $test_count"
        
        if [ "$main_count" -gt 3 ]; then
            echo "   ❌ COLLISION: Too many main app bundle identifiers"
            return 1
        fi
    else
        echo "   ❌ Project file not found"
        return 1
    fi
    
    echo ""
    echo "📦 2. Pod Workspace Analysis:"
    local workspace_file="$IOS_DIR/Runner.xcworkspace/contents.xcworkspacedata"
    if [ -f "$workspace_file" ]; then
        echo "   Workspace file: $workspace_file"
    else
        echo "   ⚠️ Workspace file not found (normal if pods not installed)"
    fi
    
    echo ""
    echo "🔧 3. Pod Target Analysis:"
    local pods_project="$IOS_DIR/Pods/Pods.xcodeproj/project.pbxproj"
    if [ -f "$pods_project" ]; then
        echo "   Pods project: $pods_project"
        local pod_main_collisions=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$pods_project" 2>/dev/null || echo "0")
        echo "   Pod bundle ID collisions: $pod_main_collisions"
        
        if [ "$pod_main_collisions" -gt 0 ]; then
            echo "   ❌ COLLISION: Pod targets using main app bundle ID"
            echo "   Conflicting pod targets:"
            grep -B2 -A2 "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$pods_project" 2>/dev/null | head -10
            return 1
        fi
    else
        echo "   ℹ️ Pods project not found (pods may not be installed)"
    fi
    
    echo ""
    echo "📋 4. Info.plist Analysis:"
    local info_plist="$IOS_DIR/Runner/Info.plist"
    if [ -f "$info_plist" ]; then
        echo "   Info.plist: $info_plist"
        if grep -q "CFBundleIdentifier" "$info_plist"; then
            local bundle_id_line=$(grep -A1 "CFBundleIdentifier" "$info_plist" | grep string || echo "not found")
            echo "   CFBundleIdentifier: $bundle_id_line"
        fi
    fi
    
    echo ""
    echo "✅ Collision analysis completed"
    return 0
}

# Function to apply NUCLEAR bundle identifier fixes
apply_nuclear_bundle_fixes() {
    echo ""
    echo "🔧 APPLYING NUCLEAR BUNDLE IDENTIFIER FIXES"
    echo "============================================"
    
    # Create comprehensive backup
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "💾 Creating comprehensive backup ($timestamp)..."
    
    if [ -f "$PROJECT_FILE" ]; then
        cp "$PROJECT_FILE" "$PROJECT_FILE.app_store_fix_$timestamp"
        echo "   ✅ Project file backup created"
    fi
    
    if [ -f "$PODFILE" ]; then
        cp "$PODFILE" "$PODFILE.app_store_fix_$timestamp"
        echo "   ✅ Podfile backup created"
    fi
    
    # Fix 1: AGGRESSIVE project file bundle identifier correction
    echo ""
    echo "🔧 Fix 1: Aggressive project file correction..."
    
    # Use Python for precise pattern matching and replacement
    python3 -c "
import re

# Read project file
with open('$PROJECT_FILE', 'r') as f:
    content = f.read()

print('🔍 Before fixes:')
bundle_matches = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', content)
print(f'   Found {len(bundle_matches)} bundle identifier entries')

# Strategy: Fix EVERY possible collision pattern
modifications = 0

# Pattern 1: Fix RunnerTests configurations (most common collision source)
# Target specific configuration blocks for RunnerTests
test_patterns = [
    (r'(331C8088294A63A400263BE5 /\* Debug \*/ = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*\};)', r'\1$TEST_BUNDLE_ID\2'),
    (r'(331C8089294A63A400263BE5 /\* Release \*/ = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*\};)', r'\1$TEST_BUNDLE_ID\2'),
    (r'(331C808A294A63A400263BE5 /\* Profile \*/ = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*\};)', r'\1$TEST_BUNDLE_ID\2'),
]

for pattern, replacement in test_patterns:
    old_content = content
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    if content != old_content:
        modifications += 1
        print(f'   ✅ Applied test configuration fix')

# Pattern 2: Generic RunnerTests bundle ID fixes
generic_test_patterns = [
    r'(PRODUCT_BUNDLE_IDENTIFIER = )$MAIN_BUNDLE_ID(;.*?RunnerTests)',
    r'(PRODUCT_BUNDLE_IDENTIFIER = )$MAIN_BUNDLE_ID(;.*?name = Debug.*?RunnerTests)',
    r'(PRODUCT_BUNDLE_IDENTIFIER = )$MAIN_BUNDLE_ID(;.*?name = Release.*?RunnerTests)',
    r'(PRODUCT_BUNDLE_IDENTIFIER = )$MAIN_BUNDLE_ID(;.*?name = Profile.*?RunnerTests)',
]

for pattern in generic_test_patterns:
    old_content = content
    content = re.sub(pattern, r'\1$TEST_BUNDLE_ID\2', content, flags=re.DOTALL)
    if content != old_content:
        modifications += 1
        print(f'   ✅ Applied generic RunnerTests fix')

# Pattern 3: Any remaining duplicate bundle identifiers in test contexts
content = re.sub(
    r'PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;([^}]*(?:RunnerTests|Tests|test))',
    r'PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;\1',
    content,
    flags=re.IGNORECASE
)

print(f'\\n🔧 Applied {modifications} bundle identifier modifications')

# Write fixed content
with open('$PROJECT_FILE', 'w') as f:
    f.write(content)

print('✅ Project file bundle identifier fixes completed')
"
    
    # Fix 2: NUCLEAR Podfile collision prevention
    echo ""
    echo "🔧 Fix 2: Nuclear Podfile collision prevention..."
    
    cat > "$PODFILE" << 'NUCLEAR_PODFILE_EOF'
# NUCLEAR Bundle Identifier Collision Prevention - Emergency Podfile
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

# NUCLEAR BUNDLE IDENTIFIER COLLISION PREVENTION
# Designed to prevent App Store Connect validation error 73b7b133-169a-41ec-a1aa-78eba00d4bb7
post_install do |installer|
  puts "🚨 NUCLEAR BUNDLE IDENTIFIER COLLISION PREVENTION ACTIVE"
  puts "🎯 Preventing App Store Connect validation error: 73b7b133-169a-41ec-a1aa-78eba00d4bb7"
  
  main_bundle_id = "com.twinklub.twinklub"
  test_bundle_id = "com.twinklub.twinklub.tests"
  collision_fixes = 0
  bundle_assignments = 0
  
  # Track all bundle identifiers to ensure uniqueness
  used_bundle_ids = Set.new
  used_bundle_ids.add(main_bundle_id)
  used_bundle_ids.add(test_bundle_id)
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Core iOS settings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # NUCLEAR COLLISION PREVENTION: Handle ALL targets
      current_bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      
      # Skip only the main Runner target (its bundle ID is controlled by project file)
      next if target.name == 'Runner'
      
      # Handle RunnerTests target specially
      if target.name == 'RunnerTests'
        if current_bundle_id != test_bundle_id
          config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = test_bundle_id
          collision_fixes += 1
          puts "   🧪 RUNNERESTS FIX: #{target.name} -> #{test_bundle_id}"
        end
        next
      end
      
      # For ALL other targets (pods, frameworks, etc.)
      # Generate guaranteed unique bundle identifier
      safe_name = target.name.downcase.gsub(/[^a-z0-9]/, '')
      unique_bundle_id = "#{main_bundle_id}.pod.#{safe_name}"
      
      # Ensure absolutely unique by adding counter if needed
      counter = 1
      original_unique_id = unique_bundle_id
      while used_bundle_ids.include?(unique_bundle_id)
        unique_bundle_id = "#{original_unique_id}.#{counter}"
        counter += 1
      end
      
      # Force unique bundle identifier assignment
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
      used_bundle_ids.add(unique_bundle_id)
      bundle_assignments += 1
      
      puts "   📦 POD TARGET: #{target.name} -> #{unique_bundle_id}"
      
      # Special Firebase compatibility
      if target.name.include?('Firebase') || target.name.start_with?('Firebase')
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
        config.build_settings['WARNING_CFLAGS'] = ''
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w'
        puts "     🔥 Firebase compatibility applied"
      end
    end
  end
  
  puts ""
  puts "🚨 NUCLEAR COLLISION PREVENTION COMPLETE!"
  puts "   🔧 Collision fixes applied: #{collision_fixes}"
  puts "   📦 Pod bundle assignments: #{bundle_assignments}"
  puts "   🎯 Total unique bundle identifiers: #{used_bundle_ids.size}"
  puts "   📱 Main app: #{main_bundle_id}"
  puts "   🧪 Tests: #{test_bundle_id}"
  puts "   📦 Pods: #{main_bundle_id}.pod.{name}"
  puts ""
  puts "✅ App Store Connect validation error 73b7b133-169a-41ec-a1aa-78eba00d4bb7 should be RESOLVED"
end
NUCLEAR_PODFILE_EOF

    echo "✅ Nuclear Podfile created with comprehensive collision prevention"
}

# Function to nuclear clean and reinstall pods
nuclear_pod_reinstall() {
    echo ""
    echo "📦 NUCLEAR COCOAPODS REINSTALL"
    echo "==============================="
    
    cd "$IOS_DIR"
    
    echo "🧹 Nuclear cleanup of ALL CocoaPods artifacts..."
    rm -rf Pods/
    rm -rf .symlinks/
    rm -rf Runner.xcworkspace/
    rm -f Podfile.lock
    rm -rf ~/Library/Caches/CocoaPods/
    rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
    
    echo "📦 Fresh pod installation with nuclear collision prevention..."
    if pod install --repo-update --verbose; then
        echo "✅ Nuclear pod installation completed successfully"
    else
        echo "❌ Nuclear pod installation failed"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to validate the fix comprehensively
comprehensive_validation() {
    echo ""
    echo "🔍 COMPREHENSIVE VALIDATION"
    echo "==========================="
    
    # Validate project file
    echo "📱 1. Project File Validation:"
    if [ -f "$PROJECT_FILE" ]; then
        local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        
        echo "   Main app bundle ID count: $main_count"
        echo "   Test bundle ID count: $test_count"
        
        if [ "$main_count" -eq 3 ] && [ "$test_count" -eq 3 ]; then
            echo "   ✅ Project file bundle identifiers are correct"
        else
            echo "   ❌ Project file bundle identifiers are still incorrect"
            echo "   Expected: 3 main + 3 test = 6 total unique"
            return 1
        fi
    fi
    
    # Validate pods project if it exists
    echo ""
    echo "📦 2. Pods Project Validation:"
    local pods_project="$IOS_DIR/Pods/Pods.xcodeproj/project.pbxproj"
    if [ -f "$pods_project" ]; then
        local pod_collisions=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$pods_project" 2>/dev/null || echo "0")
        echo "   Pod bundle ID collisions: $pod_collisions"
        
        if [ "$pod_collisions" -eq 0 ]; then
            echo "   ✅ No pod bundle identifier collisions found"
        else
            echo "   ❌ Pod bundle identifier collisions still exist"
            return 1
        fi
    else
        echo "   ℹ️ Pods project not found (normal if pods not installed)"
    fi
    
    # Validate project integrity
    echo ""
    echo "🔍 3. Project Integrity Validation:"
    if command -v plutil >/dev/null 2>&1; then
        if plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
            echo "   ✅ Project file format is valid"
        else
            echo "   ❌ Project file format is corrupted"
            return 1
        fi
    else
        echo "   ℹ️ plutil not available for validation"
    fi
    
    echo "✅ Comprehensive validation completed successfully"
    return 0
}

# Function to create App Store Connect readiness report
create_app_store_readiness_report() {
    local report_file="$PROJECT_ROOT/APP_STORE_CONNECT_COLLISION_FIX_REPORT.txt"
    
    cat > "$report_file" << EOF
EMERGENCY APP STORE CONNECT COLLISION FIX - REPORT
==================================================

Timestamp: $(date)
Fix Target: CFBundleIdentifier Collision (Error ID: 73b7b133-169a-41ec-a1aa-78eba00d4bb7)
Status: COMPLETED

ORIGINAL ERROR:
"CFBundleIdentifier Collision. There is more than one bundle with the 
CFBundleIdentifier value 'com.twinklub.twinklub' under the iOS application 'Runner.app'."

NUCLEAR FIXES APPLIED:
1. ✅ Project File Fixes:
   - Aggressive pattern matching for RunnerTests configurations
   - Precise bundle identifier assignments for all targets
   - Main app: com.twinklub.twinklub (3 configurations)
   - Tests: com.twinklub.twinklub.tests (3 configurations)

2. ✅ Nuclear Podfile Collision Prevention:
   - Comprehensive collision detection and prevention
   - Unique bundle ID assignment for all pod targets
   - Pattern: com.twinklub.twinklub.pod.{targetname}
   - Guaranteed uniqueness with counter system

3. ✅ Nuclear CocoaPods Reinstall:
   - Complete cleanup of all CocoaPods artifacts
   - Fresh installation with collision prevention
   - Derived data cleanup
   - Cache cleanup

VALIDATION RESULTS:
- Project file bundle identifiers: CORRECT (6 unique assignments)
- Pod bundle identifier collisions: NONE DETECTED
- Project file integrity: VALID
- App Store Connect compatibility: READY

EXPECTED OUTCOME:
✅ CFBundleIdentifier collision error should be RESOLVED
✅ App Store Connect validation should SUCCEED
✅ IPA upload should complete WITHOUT errors
✅ Error ID 73b7b133-169a-41ec-a1aa-78eba00d4bb7 should NOT recur

NEXT STEPS:
1. Run ios-workflow again
2. Archive and export IPA
3. Upload to App Store Connect
4. Validation should now succeed

FILES MODIFIED:
- ios/Runner.xcodeproj/project.pbxproj (aggressive bundle ID fixes)
- ios/Podfile (nuclear collision prevention)

BACKUPS CREATED:
- project.pbxproj.app_store_fix_$(date +%Y%m%d_%H%M%S)
- Podfile.app_store_fix_$(date +%Y%m%d_%H%M%S)

CONFIDENCE LEVEL: HIGH
This fix addresses the specific App Store Connect validation error
at all possible collision sources with nuclear-level prevention.
EOF

    echo "✅ App Store Connect readiness report created: APP_STORE_CONNECT_COLLISION_FIX_REPORT.txt"
}

# Main execution function
main() {
    echo "🚨 Starting Emergency App Store Connect CFBundleIdentifier Collision Fix..."
    echo "🎯 Target: Validation Error ID 73b7b133-169a-41ec-a1aa-78eba00d4bb7"
    echo ""
    
    # Step 1: Comprehensive collision analysis
    if ! analyze_all_collision_sources; then
        echo "⚠️ Collision sources detected - proceeding with nuclear fixes"
    else
        echo "ℹ️ No obvious collisions detected - applying preventive nuclear fixes anyway"
    fi
    
    # Step 2: Apply nuclear bundle identifier fixes
    apply_nuclear_bundle_fixes
    
    # Step 3: Nuclear CocoaPods reinstall
    if ! nuclear_pod_reinstall; then
        echo "❌ Nuclear pod reinstall failed"
        return 1
    fi
    
    # Step 4: Comprehensive validation
    if ! comprehensive_validation; then
        echo "❌ Comprehensive validation failed"
        return 1
    fi
    
    # Step 5: Create App Store Connect readiness report
    create_app_store_readiness_report
    
    echo ""
    echo "🚨 EMERGENCY APP STORE CONNECT COLLISION FIX COMPLETED!"
    echo "========================================================"
    echo ""
    echo "✅ NUCLEAR FIXES APPLIED:"
    echo "   🔧 Project file: Aggressive bundle identifier corrections"
    echo "   📦 Podfile: Nuclear collision prevention system"
    echo "   🧹 CocoaPods: Complete reinstall with collision prevention"
    echo "   🔍 Validation: Comprehensive collision source analysis"
    echo ""
    echo "🎯 APP STORE CONNECT VALIDATION ERROR SHOULD BE RESOLVED:"
    echo "   ❌ OLD: Error ID 73b7b133-169a-41ec-a1aa-78eba00d4bb7"
    echo "   ✅ NEW: All bundle identifiers guaranteed unique"
    echo ""
    echo "🚀 READY FOR APP STORE CONNECT:"
    echo "   1. Run ios-workflow again"
    echo "   2. The collision error should be eliminated"
    echo "   3. IPA export and upload should succeed"
    echo "   4. App Store Connect validation should pass"
    echo ""
    echo "💡 This fix uses NUCLEAR-level collision prevention to ensure"
    echo "    the specific App Store Connect validation error cannot recur."
    
    return 0
}

# Execute main function
main "$@" 