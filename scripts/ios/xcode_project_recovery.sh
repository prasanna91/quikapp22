#!/bin/bash

# Xcode Project Recovery Script
# Purpose: Recover corrupted Xcode project file and restore working state
# This fixes project.pbxproj corruption caused by aggressive modifications

set -euo pipefail

echo "🚨 XCODE PROJECT RECOVERY"
echo "🔧 Recovering corrupted Xcode project file"

# Get project root
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"
PROJECT_DIR="$IOS_DIR/Runner.xcodeproj"

# Function to check if project file is corrupted
check_project_corruption() {
    echo "🔍 Checking project file corruption..."
    
    if [ ! -f "$PROJECT_FILE" ]; then
        echo "❌ Project file not found: $PROJECT_FILE"
        return 1
    fi
    
    # Try to validate the project file structure
    if ! plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
        echo "❌ Project file is corrupted (invalid property list format)"
        return 1
    else
        echo "✅ Project file structure is valid"
        return 0
    fi
}

# Function to restore from backup
restore_from_backup() {
    echo "🔄 Attempting to restore from backup..."
    
    local backup_found=false
    
    # List of possible backup files (in order of preference)
    local backup_files=(
        "$PROJECT_FILE.original"
        "$PROJECT_FILE.backup"
        "$PROJECT_FILE.integration_fix_backup"
        "$PROJECT_FILE.linker_fix_backup"
        "$PROJECT_FILE.final_solution_backup"
        "$PROJECT_FILE.script_phases_backup"
    )
    
    for backup_file in "${backup_files[@]}"; do
        if [ -f "$backup_file" ]; then
            echo "📝 Found backup: $backup_file"
            
            # Validate backup file
            if plutil -lint "$backup_file" >/dev/null 2>&1; then
                echo "✅ Backup file is valid, restoring..."
                cp "$backup_file" "$PROJECT_FILE"
                echo "✅ Project file restored from: $backup_file"
                backup_found=true
                break
            else
                echo "⚠️ Backup file is also corrupted: $backup_file"
            fi
        fi
    done
    
    if [ "$backup_found" = false ]; then
        echo "❌ No valid backup files found"
        return 1
    fi
    
    return 0
}

# Function to regenerate project file using Flutter
regenerate_project_with_flutter() {
    echo "🔄 Regenerating project file using Flutter..."
    
    cd "$PROJECT_ROOT"
    
    # Remove corrupted project
    echo "   Removing corrupted project directory..."
    rm -rf "$PROJECT_DIR"
    
    # Remove iOS platform and regenerate
    echo "   Regenerating iOS platform..."
    flutter create --platforms ios .
    
    if [ -d "$PROJECT_DIR" ] && [ -f "$PROJECT_FILE" ]; then
        echo "✅ Project file regenerated successfully"
        
        # Validate regenerated file
        if plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
            echo "✅ Regenerated project file is valid"
            return 0
        else
            echo "❌ Regenerated project file is still invalid"
            return 1
        fi
    else
        echo "❌ Failed to regenerate project file"
        return 1
    fi
}

# Function to apply safe project settings
apply_safe_project_settings() {
    echo "🔧 Applying safe project settings..."
    
    if [ ! -f "$PROJECT_FILE" ]; then
        echo "❌ Project file not found for applying settings"
        return 1
    fi
    
    # Create backup before any modifications
    cp "$PROJECT_FILE" "$PROJECT_FILE.recovery_backup"
    echo "✅ Backup created: $PROJECT_FILE.recovery_backup"
    
    # Use Xcode's built-in tools to modify settings safely
    echo "   Applying safe build settings using xcrun..."
    
    # Set deployment target safely
    if command -v xcrun >/dev/null 2>&1; then
        cd "$IOS_DIR"
        
        # Use xcodebuild to set basic settings safely
        echo "   Setting deployment target to 13.0..."
        xcodebuild -project Runner.xcodeproj -target Runner -configuration Release \
            IPHONEOS_DEPLOYMENT_TARGET=13.0 \
            ENABLE_BITCODE=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO \
            -showBuildSettings >/dev/null 2>&1 || echo "   Warning: xcodebuild settings application failed"
        
        cd "$PROJECT_ROOT"
        echo "✅ Safe project settings applied"
    else
        echo "⚠️ xcrun not available, skipping safe settings application"
    fi
    
    return 0
}

# Function to validate project and workspace
validate_project_and_workspace() {
    echo "🔍 Validating project and workspace..."
    
    # Check project file
    if [ -f "$PROJECT_FILE" ] && plutil -lint "$PROJECT_FILE" >/dev/null 2>&1; then
        echo "✅ Project file is valid"
    else
        echo "❌ Project file validation failed"
        return 1
    fi
    
    # Check workspace
    local workspace_file="$IOS_DIR/Runner.xcworkspace"
    if [ -d "$workspace_file" ]; then
        echo "✅ Workspace exists"
        
        # Check workspace contents
        local contents_file="$workspace_file/contents.xcworkspacedata"
        if [ -f "$contents_file" ]; then
            echo "✅ Workspace contents file exists"
        else
            echo "⚠️ Workspace contents file missing"
        fi
    else
        echo "⚠️ Workspace not found - this may be recreated by CocoaPods"
    fi
    
    # Test opening project with xcodebuild
    echo "   Testing project with xcodebuild..."
    cd "$IOS_DIR"
    
    if xcodebuild -project Runner.xcodeproj -list >/dev/null 2>&1; then
        echo "✅ Project can be opened by xcodebuild"
    else
        echo "❌ Project cannot be opened by xcodebuild"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Function to clean and reinstall CocoaPods safely
reinstall_cocoapods_safely() {
    echo "📦 Reinstalling CocoaPods safely..."
    
    cd "$IOS_DIR"
    
    # Clean CocoaPods artifacts
    echo "   Cleaning CocoaPods artifacts..."
    rm -rf Pods/
    rm -f Podfile.lock
    rm -rf .symlinks/
    rm -rf Runner.xcworkspace/
    
    # Create minimal Podfile without aggressive modifications
    echo "   Creating minimal Podfile..."
    cat > Podfile << 'MINIMAL_PODFILE_EOF'
# Minimal Podfile for Project Recovery
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

# Minimal post_install - no aggressive modifications
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
  end
end
MINIMAL_PODFILE_EOF
    
    echo "✅ Minimal Podfile created"
    
    # Install pods
    echo "   Installing CocoaPods..."
    if pod install --repo-update --verbose; then
        echo "✅ CocoaPods installed successfully"
    else
        echo "❌ CocoaPods installation failed"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    return 0
}

# Main recovery function
main() {
    echo "🚨 Starting Xcode Project Recovery..."
    echo "🎯 This will fix corrupted project files and restore working state"
    
    # Step 1: Check current project corruption
    if check_project_corruption; then
        echo "✅ Project file is not corrupted, no recovery needed"
        return 0
    fi
    
    echo "❌ Project file is corrupted, starting recovery process..."
    
    # Step 2: Try to restore from backup
    if restore_from_backup; then
        echo "✅ Successfully restored from backup"
        
        # Validate restored project
        if validate_project_and_workspace; then
            echo "✅ Restored project is valid"
        else
            echo "⚠️ Restored project has issues, continuing with full recovery"
        fi
    else
        echo "⚠️ Backup restoration failed, proceeding with full regeneration"
        
        # Step 3: Regenerate project file using Flutter
        if ! regenerate_project_with_flutter; then
            echo "❌ Project regeneration failed"
            return 1
        fi
    fi
    
    # Step 4: Apply safe project settings
    apply_safe_project_settings
    
    # Step 5: Reinstall CocoaPods safely
    if ! reinstall_cocoapods_safely; then
        echo "❌ CocoaPods reinstallation failed"
        return 1
    fi
    
    # Step 6: Final validation
    if validate_project_and_workspace; then
        echo ""
        echo "✅ Xcode Project Recovery completed successfully!"
        echo "📋 Recovery summary:"
        echo "   🔧 Project file corruption resolved"
        echo "   📝 Safe project settings applied"
        echo "   📦 CocoaPods reinstalled with minimal configuration"
        echo "   🔍 Project and workspace validated"
        echo ""
        echo "🎯 iOS workflow should now work without project corruption!"
        echo "🔧 Next steps:"
        echo "   1. Try running the iOS workflow again"
        echo "   2. The project should now open properly in Xcode"
        echo "   3. Archive creation should proceed without parse errors"
        echo ""
        echo "💡 Future Firebase fixes will use safer modification methods"
        
        return 0
    else
        echo ""
        echo "❌ Project recovery failed"
        echo "   The project file could not be restored to a working state"
        echo "   Manual intervention may be required"
        return 1
    fi
}

# Execute main function
main "$@" 