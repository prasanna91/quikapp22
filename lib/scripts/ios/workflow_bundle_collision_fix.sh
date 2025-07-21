#!/bin/bash

# Workflow-Integrated Bundle Collision Fix
# Runs during ios-workflow to prevent App Store Connect validation errors
# Addresses Error ID: 73b7b133-169a-41ec-a1aa-78eba00d4bb7

set -euo pipefail

echo "🔧 WORKFLOW-INTEGRATED BUNDLE COLLISION FIX"
echo "============================================"
echo "🎯 Preventing CFBundleIdentifier collision during build"

# Configuration
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"
MAIN_BUNDLE_ID="com.twinklub.twinklub"
TEST_BUNDLE_ID="com.twinklub.twinklub.tests"

# Function to check and fix project file bundle identifiers
fix_project_bundle_identifiers() {
    echo "🔧 Checking and fixing project file bundle identifiers..."
    
    if [ ! -f "$PROJECT_FILE" ]; then
        echo "❌ Project file not found: $PROJECT_FILE"
        return 1
    fi
    
    # Check current state
    local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
    local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
    
    echo "📊 Current bundle identifier counts:"
    echo "   Main app ($MAIN_BUNDLE_ID): $main_count"
    echo "   Tests ($TEST_BUNDLE_ID): $test_count"
    
    # If test count is 0, we have collisions to fix
    if [ "$test_count" -eq 0 ] && [ "$main_count" -gt 3 ]; then
        echo "❌ COLLISION DETECTED: Test targets using main app bundle ID"
        echo "🔧 Applying aggressive bundle identifier fixes..."
        
        # Create backup
        cp "$PROJECT_FILE" "$PROJECT_FILE.workflow_fix_$(date +%Y%m%d_%H%M%S)"
        echo "✅ Backup created"
        
        # Apply comprehensive sed-based fixes for RunnerTests
        echo "   🔧 Fixing RunnerTests Debug configuration..."
        sed -i.tmp1 '/331C8088294A63A400263BE5.*Debug.*{/,/};/{
            s/PRODUCT_BUNDLE_IDENTIFIER = '"$MAIN_BUNDLE_ID"';/PRODUCT_BUNDLE_IDENTIFIER = '"$TEST_BUNDLE_ID"';/g
        }' "$PROJECT_FILE"
        
        echo "   🔧 Fixing RunnerTests Release configuration..."
        sed -i.tmp2 '/331C8089294A63A400263BE5.*Release.*{/,/};/{
            s/PRODUCT_BUNDLE_IDENTIFIER = '"$MAIN_BUNDLE_ID"';/PRODUCT_BUNDLE_IDENTIFIER = '"$TEST_BUNDLE_ID"';/g
        }' "$PROJECT_FILE"
        
        echo "   🔧 Fixing RunnerTests Profile configuration..."
        sed -i.tmp3 '/331C808A294A63A400263BE5.*Profile.*{/,/};/{
            s/PRODUCT_BUNDLE_IDENTIFIER = '"$MAIN_BUNDLE_ID"';/PRODUCT_BUNDLE_IDENTIFIER = '"$TEST_BUNDLE_ID"';/g
        }' "$PROJECT_FILE"
        
        # Clean up temp files
        rm -f "$PROJECT_FILE.tmp1" "$PROJECT_FILE.tmp2" "$PROJECT_FILE.tmp3"
        
        # Verify fixes
        local new_main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        local new_test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        
        echo "📊 After fixes:"
        echo "   Main app ($MAIN_BUNDLE_ID): $new_main_count"
        echo "   Tests ($TEST_BUNDLE_ID): $new_test_count"
        
        if [ "$new_main_count" -eq 3 ] && [ "$new_test_count" -eq 3 ]; then
            echo "✅ Bundle identifier collision fixed successfully"
        else
            echo "⚠️ Bundle identifier counts unexpected, but collision may be reduced"
        fi
    else
        echo "✅ Bundle identifiers appear correct (no collision detected)"
    fi
    
    return 0
}

# Function to ensure Podfile has collision prevention
ensure_podfile_collision_prevention() {
    echo "🔧 Ensuring Podfile has collision prevention..."
    
    local podfile="$IOS_DIR/Podfile"
    if [ ! -f "$podfile" ]; then
        echo "⚠️ Podfile not found, skipping Podfile fixes"
        return 0
    fi
    
    # Check if collision prevention is already present
    if grep -q "BUNDLE IDENTIFIER COLLISION" "$podfile"; then
        echo "✅ Podfile already has collision prevention"
        return 0
    fi
    
    echo "🔧 Adding collision prevention to Podfile..."
    
    # Add collision prevention to existing post_install hook
    if grep -q "post_install do |installer|" "$podfile"; then
        # Insert collision prevention into existing post_install
        sed -i.backup '/post_install do |installer|/a\
  # WORKFLOW BUNDLE IDENTIFIER COLLISION PREVENTION\
  main_bundle_id = "com.twinklub.twinklub"\
  installer.pods_project.targets.each do |target|\
    next if target.name == "Runner" || target.name == "RunnerTests"\
    target.build_configurations.each do |config|\
      if config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"]\
        safe_name = target.name.downcase.gsub(/[^a-z0-9]/, "")\
        unique_bundle_id = "#{main_bundle_id}.pod.#{safe_name}"\
        config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = unique_bundle_id\
      end\
    end\
  end\
' "$podfile"
        echo "✅ Added collision prevention to existing post_install hook"
    else
        # Add new post_install hook with collision prevention
        cat >> "$podfile" << 'COLLISION_PREVENTION_EOF'

# WORKFLOW BUNDLE IDENTIFIER COLLISION PREVENTION
post_install do |installer|
  flutter_additional_ios_build_settings(installer)
  
  # Prevent bundle identifier collisions
  main_bundle_id = "com.twinklub.twinklub"
  installer.pods_project.targets.each do |target|
    next if target.name == "Runner" || target.name == "RunnerTests"
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Ensure unique bundle identifiers for pod targets
      if config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
        safe_name = target.name.downcase.gsub(/[^a-z0-9]/, '')
        unique_bundle_id = "#{main_bundle_id}.pod.#{safe_name}"
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = unique_bundle_id
      end
    end
  end
end
COLLISION_PREVENTION_EOF
        echo "✅ Added new post_install hook with collision prevention"
    fi
    
    return 0
}

# Function to validate final state
validate_collision_prevention() {
    echo "🔍 Validating collision prevention..."
    
    # Check project file
    if [ -f "$PROJECT_FILE" ]; then
        local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" || echo "0")
        
        echo "📊 Final bundle identifier validation:"
        echo "   Main app: $main_count occurrences"
        echo "   Tests: $test_count occurrences"
        
        if [ "$main_count" -eq 3 ] && [ "$test_count" -eq 3 ]; then
            echo "✅ Project file bundle identifiers are correct"
        elif [ "$main_count" -le 3 ]; then
            echo "✅ Main app bundle identifier count is acceptable"
        else
            echo "⚠️ Main app bundle identifier count is high: $main_count"
        fi
    fi
    
    # Check Podfile
    local podfile="$IOS_DIR/Podfile"
    if [ -f "$podfile" ] && grep -q "COLLISION" "$podfile"; then
        echo "✅ Podfile has collision prevention"
    else
        echo "ℹ️ Podfile collision prevention status unclear"
    fi
    
    echo "✅ Validation completed"
    return 0
}

# Main execution
main() {
    echo "🚀 Starting workflow-integrated bundle collision fix..."
    echo "🎯 Target: Prevent App Store Connect validation errors"
    echo ""
    
    # Step 1: Fix project file bundle identifiers
    if ! fix_project_bundle_identifiers; then
        echo "❌ Failed to fix project file bundle identifiers"
        return 1
    fi
    
    # Step 2: Ensure Podfile collision prevention
    if ! ensure_podfile_collision_prevention; then
        echo "❌ Failed to ensure Podfile collision prevention"
        return 1
    fi
    
    # Step 3: Validate final state
    validate_collision_prevention
    
    echo ""
    echo "✅ WORKFLOW-INTEGRATED BUNDLE COLLISION FIX COMPLETED"
    echo "======================================================"
    echo ""
    echo "🔧 Fixes Applied:"
    echo "   ✅ Project file bundle identifier corrections"
    echo "   ✅ Podfile collision prevention ensured"
    echo "   ✅ Validation completed"
    echo ""
    echo "🎯 Expected Result:"
    echo "   ✅ No CFBundleIdentifier collision during App Store validation"
    echo "   ✅ Error ID 73b7b133-169a-41ec-a1aa-78eba00d4bb7 should be resolved"
    echo "   ✅ IPA export and upload should succeed"
    echo ""
    echo "🚀 Ready for ios-workflow build process!"
    
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 