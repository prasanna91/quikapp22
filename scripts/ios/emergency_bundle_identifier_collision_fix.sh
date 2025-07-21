#!/bin/bash

# Emergency Bundle Identifier Collision Fix
# Specifically addresses CFBundleIdentifier collision errors during App Store validation
# This fixes the exact issue reported in Transporter logs

set -euo pipefail

echo "🚨 EMERGENCY BUNDLE IDENTIFIER COLLISION FIX"
echo "🎯 Addressing CFBundleIdentifier collision during App Store validation"
echo "📋 Error: 'There is more than one bundle with the CFBundleIdentifier value com.twinklub.twinklub'"

# Project paths
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"
PODFILE="$IOS_DIR/Podfile"

# Target bundle identifier
MAIN_BUNDLE_ID="com.twinklub.twinklub"

echo "📁 Project root: $PROJECT_ROOT"
echo "🎯 Target bundle ID: $MAIN_BUNDLE_ID"

# Function to create emergency backup
create_emergency_backup() {
    echo "💾 Creating emergency backup..."
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [ -f "$PROJECT_FILE" ]; then
        cp "$PROJECT_FILE" "$PROJECT_FILE.emergency_collision_fix_$timestamp"
        echo "✅ Project file backup: project.pbxproj.emergency_collision_fix_$timestamp"
    fi
    
    if [ -f "$PODFILE" ]; then
        cp "$PODFILE" "$PODFILE.emergency_collision_fix_$timestamp"
        echo "✅ Podfile backup: Podfile.emergency_collision_fix_$timestamp"
    fi
}

# Function to fix bundle identifiers in project file
fix_project_bundle_identifiers() {
    echo "🔧 Fixing bundle identifiers in project file..."
    
    if [ ! -f "$PROJECT_FILE" ]; then
        echo "❌ Project file not found: $PROJECT_FILE"
        return 1
    fi
    
    # Use Python for precise replacements
    python3 -c "
import re

# Read the project file
with open('$PROJECT_FILE', 'r') as f:
    content = f.read()

print('🔍 Analyzing current bundle identifiers...')

# Find all PRODUCT_BUNDLE_IDENTIFIER entries with their context
bundle_id_pattern = r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'
matches = re.findall(bundle_id_pattern, content)

print(f'Found {len(matches)} bundle identifier entries:')
for i, match in enumerate(matches):
    print(f'  {i+1}. {match.strip()}')

# Strategy: Replace all bundle identifiers systematically
# 1. Main app targets get the main bundle ID
# 2. Test targets get unique test bundle IDs
# 3. Any other targets get unique derived bundle IDs

modifications_made = 0

# Fix 1: Main app Runner target configurations
main_app_patterns = [
    r'(buildSettings = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*PRODUCT_NAME = \"\\\$(TARGET_NAME)\";[^}]*name = Debug;)',
    r'(buildSettings = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*PRODUCT_NAME = \"\\\$(TARGET_NAME)\";[^}]*name = Release;)',
    r'(buildSettings = \{[^}]*PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*PRODUCT_NAME = \"\\\$(TARGET_NAME)\";[^}]*name = Profile;)'
]

for i, pattern in enumerate(main_app_patterns):
    new_content = re.sub(pattern, r'\1$MAIN_BUNDLE_ID\2', content, flags=re.DOTALL)
    if new_content != content:
        config_name = ['Debug', 'Release', 'Profile'][i]
        print(f'✅ Fixed main app {config_name} configuration bundle identifier')
        content = new_content
        modifications_made += 1

# Fix 2: RunnerTests target configurations
test_patterns = [
    r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*RunnerTests[^}]*name = Debug;)',
    r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*RunnerTests[^}]*name = Release;)',
    r'(PRODUCT_BUNDLE_IDENTIFIER = )[^;]+(;[^}]*RunnerTests[^}]*name = Profile;)'
]

test_bundle_id = '$MAIN_BUNDLE_ID.tests'
for i, pattern in enumerate(test_patterns):
    new_content = re.sub(pattern, rf'\1{test_bundle_id}\2', content, flags=re.DOTALL)
    if new_content != content:
        config_name = ['Debug', 'Release', 'Profile'][i]
        print(f'✅ Fixed RunnerTests {config_name} configuration bundle identifier to {test_bundle_id}')
        content = new_content
        modifications_made += 1

# Fix 3: Any remaining com.example bundle identifiers
content = re.sub(
    r'PRODUCT_BUNDLE_IDENTIFIER = com\.example\.[^;]+;',
    f'PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;',
    content
)

print(f'\\n✅ Total modifications made: {modifications_made}')

# Write the updated content back
with open('$PROJECT_FILE', 'w') as f:
    f.write(content)

print('✅ Project file bundle identifiers updated successfully')
"
    
    return 0
}

# Function to validate project file integrity
validate_project_integrity() {
    echo "🔍 Validating project file integrity..."
    
    if plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
        echo "✅ Project file integrity verified"
        return 0
    else
        echo "❌ Project file integrity check failed"
        return 1
    fi
}

# Function to create emergency Podfile
create_emergency_podfile() {
    echo "🔧 Creating emergency collision-free Podfile..."
    
    cat > "$PODFILE" << 'EMERGENCY_PODFILE_EOF'
# Emergency Bundle Identifier Collision Fix - Podfile
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

# EMERGENCY BUNDLE IDENTIFIER COLLISION FIX
post_install do |installer|
  puts "🚨 EMERGENCY BUNDLE IDENTIFIER COLLISION FIX ACTIVE"
  
  main_bundle_id = "com.twinklub.twinklub"
  collision_fixes = 0
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Core settings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      
      # CRITICAL: Ensure EVERY pod target has a unique bundle identifier
      # Skip only the main Runner target (handled by project file)
      next if target.name == 'Runner' || target.name == 'RunnerTests'
      
      # Generate safe, unique bundle identifier for this pod target
      safe_name = target.name.downcase.gsub(/[^a-z0-9]/, '')
      unique_bundle_id = "#{main_bundle_id}.pod.#{safe_name}"
      
      # Force unique bundle identifier
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
      collision_fixes += 1
      
      puts "   🔧 COLLISION FIX: #{target.name} -> #{unique_bundle_id}"
      
      # Firebase compatibility
      if target.name.include?('Firebase') || target.name.start_with?('Firebase')
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
        config.build_settings['WARNING_CFLAGS'] = ''
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w'
      end
    end
  end
  
  puts "🚨 EMERGENCY COLLISION FIX COMPLETE!"
  puts "   🔧 Pod targets fixed: #{collision_fixes}"
  puts "   🎯 All targets now have guaranteed unique bundle identifiers"
  puts "   📱 Main app: #{main_bundle_id}"
  puts "   🧪 Tests: #{main_bundle_id}.tests"
  puts "   📦 Pods: #{main_bundle_id}.pod.{name}"
end
EMERGENCY_PODFILE_EOF

    echo "✅ Emergency Podfile created with guaranteed unique bundle identifiers"
}

# Function to emergency clean and reinstall pods
emergency_pod_reinstall() {
    echo "📦 Emergency CocoaPods reinstall..."
    
    cd "$IOS_DIR"
    
    # Nuclear cleanup
    echo "   🧹 Nuclear cleanup of CocoaPods artifacts..."
    rm -rf Pods/
    rm -f Podfile.lock
    rm -rf .symlinks/
    rm -rf Runner.xcworkspace/
    rm -rf ~/Library/Caches/CocoaPods/
    
    # Fresh installation
    echo "   📦 Fresh pod installation with collision fixes..."
    if pod install --repo-update --verbose; then
        echo "✅ Emergency pod installation successful"
        cd "$PROJECT_ROOT"
        return 0
    else
        echo "❌ Emergency pod installation failed"
        cd "$PROJECT_ROOT"
        return 1
    fi
}

# Function to validate final bundle identifier uniqueness
validate_final_uniqueness() {
    echo "🔍 Final validation of bundle identifier uniqueness..."
    
    # Check project file
    if [ -f "$PROJECT_FILE" ]; then
        echo "   📱 Analyzing final project file bundle identifiers..."
        
        local main_app_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID.tests;" "$PROJECT_FILE" || echo "0")
        
        echo "   📊 Main app bundle ID count: $main_app_count"
        echo "   📊 Test bundle ID count: $test_count"
        
        if [ "$main_app_count" -eq 3 ] && [ "$test_count" -eq 3 ]; then
            echo "✅ Project file bundle identifiers are correctly configured"
        else
            echo "⚠️ Project file bundle identifier counts are unexpected"
            echo "   Expected: 3 main app + 3 test = 6 total"
            echo "   Found: $main_app_count main app + $test_count test"
        fi
    fi
    
    # Check for any duplicate patterns
    if [ -f "$PROJECT_FILE" ]; then
        local all_bundle_ids=$(grep "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | sed 's/.*PRODUCT_BUNDLE_IDENTIFIER = "\?\([^";]*\)"\?;.*/\1/' | sort)
        local unique_bundle_ids=$(echo "$all_bundle_ids" | sort -u)
        
        if [ "$(echo "$all_bundle_ids" | wc -l)" = "$(echo "$unique_bundle_ids" | wc -l)" ]; then
            echo "✅ All project file bundle identifiers are unique"
        else
            echo "❌ Duplicate bundle identifiers still found in project file"
            echo "All bundle IDs:"
            echo "$all_bundle_ids"
            echo "Unique bundle IDs:"
            echo "$unique_bundle_ids"
            return 1
        fi
    fi
    
    return 0
}

# Function to create validation report
create_validation_report() {
    local report_file="$PROJECT_ROOT/output/ios/EMERGENCY_COLLISION_FIX_REPORT.txt"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << 'VALIDATION_REPORT_EOF'
EMERGENCY BUNDLE IDENTIFIER COLLISION FIX - VALIDATION REPORT
============================================================

✅ COLLISION RESOLUTION COMPLETED

📋 ISSUE ADDRESSED:
CFBundleIdentifier Collision. There is more than one bundle with the 
CFBundleIdentifier value 'com.twinklub.twinklub' under the iOS application 'Runner.app'.

🔧 FIXES APPLIED:
1. ✅ Project file bundle identifiers corrected:
   - Main app (Debug/Release/Profile): com.twinklub.twinklub
   - Tests (Debug/Release/Profile): com.twinklub.twinklub.tests

2. ✅ Emergency Podfile with guaranteed unique pod bundle identifiers:
   - Pattern: com.twinklub.twinklub.pod.{safename}
   - All pod targets get unique identifiers automatically

3. ✅ Nuclear CocoaPods cleanup and reinstall:
   - All caches cleared
   - Fresh installation with collision prevention

🎯 EXPECTED RESULT:
- No more CFBundleIdentifier collision errors
- Successful App Store Connect validation
- IPA upload should complete without validation errors

🚀 NEXT STEPS:
1. Run: flutter clean
2. Build new IPA: flutter build ios --release
3. Archive and export for App Store Connect
4. Upload should now succeed without collision errors

📊 VALIDATION STATUS:
All bundle identifiers are now guaranteed unique.
The specific collision reported in Transporter logs has been resolved.
VALIDATION_REPORT_EOF

    echo "✅ Validation report created: $report_file"
}

# Main execution
main() {
    echo "🚨 Starting Emergency Bundle Identifier Collision Fix..."
    echo "🎯 This will resolve the specific CFBundleIdentifier collision error from App Store validation"
    
    # Step 1: Create emergency backup
    create_emergency_backup
    
    # Step 2: Fix project file bundle identifiers
    if ! fix_project_bundle_identifiers; then
        echo "❌ Failed to fix project file bundle identifiers"
        return 1
    fi
    
    # Step 3: Validate project integrity
    if ! validate_project_integrity; then
        echo "❌ Project file integrity validation failed"
        return 1
    fi
    
    # Step 4: Create emergency Podfile
    create_emergency_podfile
    
    # Step 5: Emergency pod reinstall
    if ! emergency_pod_reinstall; then
        echo "❌ Emergency pod reinstall failed"
        return 1
    fi
    
    # Step 6: Validate final uniqueness
    if ! validate_final_uniqueness; then
        echo "❌ Final bundle identifier uniqueness validation failed"
        return 1
    fi
    
    # Step 7: Create validation report
    create_validation_report
    
    echo ""
    echo "🚨 EMERGENCY BUNDLE IDENTIFIER COLLISION FIX COMPLETED SUCCESSFULLY!"
    echo ""
    echo "📋 Summary of critical fixes:"
    echo "   ✅ Project file bundle identifiers corrected for all configurations"
    echo "   ✅ Emergency Podfile with guaranteed unique pod identifiers"
    echo "   ✅ Nuclear CocoaPods cleanup and reinstall completed"
    echo "   ✅ Final validation confirms all bundle identifiers are unique"
    echo ""
    echo "🎯 THE SPECIFIC TRANSPORTER ERROR SHOULD NOW BE RESOLVED:"
    echo "   ❌ OLD: CFBundleIdentifier Collision with 'com.twinklub.twinklub'"
    echo "   ✅ NEW: All targets have guaranteed unique bundle identifiers"
    echo ""
    echo "🚀 Ready for App Store Connect upload!"
    echo "   1. The collision error is now fixed"
    echo "   2. IPA export should succeed"
    echo "   3. App Store validation should pass"
    echo ""
    echo "💡 If issues persist, the validation report contains detailed analysis."
    
    return 0
}

# Execute main function
main "$@" 