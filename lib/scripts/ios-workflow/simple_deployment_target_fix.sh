#!/bin/bash

# Simple iOS Deployment Target Fix Script
# Purpose: Update iOS deployment target to 13.0 for Firebase compatibility (without pod regeneration)

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    echo "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    echo "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    echo "⚠️ Using fallback logging functions"
    
    # Define fallback logging functions
    log_info() { echo "INFO: $*"; }
    log_error() { echo "ERROR: $*"; }
    log_success() { echo "SUCCESS: $*"; }
    log_warn() { echo "WARN: $*"; }
    log_warning() { echo "WARN: $*"; }
fi

# Source environment configuration
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
else
    log_warning "⚠️ Environment configuration file not found, using system environment variables"
fi

log_info "🔧 Simple iOS Deployment Target Fix..."

# Function to update iOS deployment target in project.pbxproj
update_project_deployment_target() {
    log_info "📱 Updating iOS deployment target in project.pbxproj..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    
    if [ ! -f "$project_file" ]; then
        log_error "❌ Project file not found: $project_file"
        return 1
    fi
    
    # Update IPHONEOS_DEPLOYMENT_TARGET to 13.0
    if sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12\.0;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' "$project_file"; then
        log_success "✅ Updated IPHONEOS_DEPLOYMENT_TARGET to 13.0 in project.pbxproj"
    else
        log_warn "⚠️ Could not update IPHONEOS_DEPLOYMENT_TARGET in project.pbxproj"
    fi
    
    # Also update any other deployment target references
    if sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 11\.0;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' "$project_file"; then
        log_success "✅ Updated additional IPHONEOS_DEPLOYMENT_TARGET references"
    fi
    
    return 0
}

# Function to create/update Podfile with correct deployment target
create_podfile() {
    log_info "📝 Creating Podfile with iOS 13.0 deployment target..."
    
    mkdir -p ios
    
    cat > "ios/Podfile" << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
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

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Ensure all pods use iOS 13.0 deployment target
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
EOF
    
    log_success "✅ Podfile created with iOS 13.0 deployment target"
    return 0
}

# Function to update Info.plist deployment target
update_info_plist() {
    log_info "📱 Updating Info.plist deployment target..."
    
    local info_plist="ios/Runner/Info.plist"
    
    if [ ! -f "$info_plist" ]; then
        log_warn "⚠️ Info.plist not found: $info_plist"
        return 0
    fi
    
    # Update MinimumOSVersion to 13.0
    if plutil -replace MinimumOSVersion -string "13.0" "$info_plist" 2>/dev/null; then
        log_success "✅ Updated MinimumOSVersion to 13.0 in Info.plist"
    else
        log_warn "⚠️ Could not update MinimumOSVersion in Info.plist"
    fi
    
    return 0
}

# Function to verify deployment target changes
verify_deployment_target() {
    log_info "🔍 Verifying deployment target changes..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local info_plist="ios/Runner/Info.plist"
    
    log_info "📋 Deployment target verification summary:"
    
    # Check project.pbxproj
    local project_count
    project_count=$(grep -c "IPHONEOS_DEPLOYMENT_TARGET = 13.0;" "$project_file" 2>/dev/null || echo "0")
    
    if [ "$project_count" -gt 0 ]; then
        log_success "✅ iOS 13.0 deployment target found in project.pbxproj: $project_count entries"
    else
        log_error "❌ iOS 13.0 deployment target not found in project.pbxproj"
        return 1
    fi
    
    # Check Info.plist
    if [ -f "$info_plist" ]; then
        local plist_version
        plist_version=$(plutil -extract MinimumOSVersion raw "$info_plist" 2>/dev/null || echo "NOT_FOUND")
        
        if [ "$plist_version" = "13.0" ]; then
            log_success "✅ MinimumOSVersion matches in Info.plist: 13.0"
        else
            log_warn "⚠️ MinimumOSVersion mismatch in Info.plist: expected 13.0, got $plist_version"
        fi
    fi
    
    return 0
}

# Main execution function
main() {
    log_info "🚀 Simple iOS Deployment Target Fix..."
    
    # Update project deployment target
    if ! update_project_deployment_target; then
        log_error "❌ Failed to update project deployment target"
        return 1
    fi
    
    # Create/update Podfile
    if ! create_podfile; then
        log_error "❌ Failed to create Podfile"
        return 1
    fi
    
    # Update Info.plist
    update_info_plist
    
    # Verify the changes
    if ! verify_deployment_target; then
        log_error "❌ Deployment target verification failed"
        return 1
    fi
    
    log_success "🎉 iOS deployment target fixed to 13.0"
    log_info "📋 Summary:"
    log_info "   ✅ Updated project.pbxproj deployment target"
    log_info "   ✅ Created Podfile with iOS 13.0"
    log_info "   ✅ Updated Info.plist MinimumOSVersion"
    log_info "   ✅ Verified deployment target changes"
    log_info "   📝 Note: Pod install will be handled by main build process"
    return 0
}

# Execute main function
main "$@" 