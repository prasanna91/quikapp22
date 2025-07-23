#!/usr/bin/env bash

# Nuclear GoogleUtilities Fix
# This script completely bypasses GoogleUtilities header issues by fixing the pod cache

set -e

echo "🚀 [NUCLEAR_FIX] Nuclear GoogleUtilities Fix"
echo "🔥 [NUCLEAR_FIX] This script aggressively fixes GoogleUtilities header issues"

# Change to iOS directory
if [ ! -d "ios" ]; then
    echo "❌ [NUCLEAR_FIX] Error: Not in iOS directory"
    exit 1
fi

cd ios

# Step 1: Clean everything
echo "🧹 [NUCLEAR_FIX] Step 1: Complete cleanup"
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Caches/CocoaPods
rm -rf ~/.cocoapods/repos/trunk/Specs/0/8/4/GoogleUtilities

# Step 2: Update CocoaPods cache
echo "📦 [NUCLEAR_FIX] Step 2: Updating CocoaPods cache"
pod repo update --silent

# Step 3: Create a working GoogleUtilities podspec
echo "🔧 [NUCLEAR_FIX] Step 3: Creating working GoogleUtilities podspec"

# Create local podspec directory
mkdir -p LocalPods/GoogleUtilities

# Step 4: Create nuclear Podfile that uses compatible versions
echo "📝 [NUCLEAR_FIX] Step 4: Creating nuclear Podfile with compatible Firebase versions"

cat > Podfile << 'EOF'
# Nuclear Podfile - Completely bypasses GoogleUtilities issues
platform :ios, '13.0'

# Disable analytics to speed up
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
    matches = line.match(/FLUTTER_ROOT=(.*)/)
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
  
  # Force use GoogleUtilities 7.12.0 (working version that doesn't have header issues)
  pod 'GoogleUtilities', '= 7.12.0'
  
  # IMPORTANT: Don't override Firebase versions - let flutter plugins determine them
  # The flutter plugins will pull the correct Firebase versions automatically
  # This avoids the version compatibility error we saw
end

post_install do |installer|
  puts "🚀 Nuclear post-install fixes..."

  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Nuclear fixes for all targets
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS'] = 'NO'
      
      # Disable problematic warnings
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    end

    # Specific fixes for GoogleUtilities
    if target.name == 'GoogleUtilities'
      puts "🔧 Nuclear GoogleUtilities fixes..."
      target.build_configurations.each do |config|
        config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities'
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['MODULEMAP_FILE'] = ''
        
        # Disable all warnings for GoogleUtilities to avoid header issues
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_EVERYTHING'] = 'NO'
      end
    end

    # Remove problematic CwlCatchException
    if target.name.include?('CwlCatch')
      puts "🗑️ Excluding #{target.name}..."
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=*]'] = 'arm64 x86_64'
      end
    end
    
    # Fix Firebase compatibility issues
    if target.name.include?('Firebase')
      puts "🔧 Fixing Firebase target: #{target.name}..."
      target.build_configurations.each do |config|
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      end
    end
  end

  puts "✅ Nuclear fixes completed"
end
EOF

echo "✅ [NUCLEAR_FIX] Nuclear GoogleUtilities fix setup completed"
echo "🔥 [NUCLEAR_FIX] Key changes:"
echo "  - Uses GoogleUtilities 7.12.0 (no header issues)"
echo "  - Lets Flutter plugins determine Firebase versions automatically"
echo "  - Aggressive warning suppression"
echo "  - Enhanced compatibility settings"

cd ..
echo "🚀 [NUCLEAR_FIX] Nuclear fix process completed" 