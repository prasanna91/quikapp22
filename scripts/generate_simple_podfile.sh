#!/usr/bin/env bash

# Simple Podfile Generator for iOS Build
# This generates a minimal Podfile that avoids GoogleUtilities header reference issues

set -e

echo "🔧 [SIMPLE_PODFILE] Generating Simple Podfile"

# Check if we're in the correct directory
if [ ! -d "ios" ]; then
    echo "❌ [SIMPLE_PODFILE] Error: Not in the correct directory (ios folder not found)"
    exit 1
fi

# Create backup of original Podfile
if [ -f "ios/Podfile" ]; then
    echo "🔍 [SIMPLE_PODFILE] Creating backup of original Podfile"
    cp ios/Podfile ios/Podfile.original
fi

# Generate the simple Podfile
echo "🔍 [SIMPLE_PODFILE] Generating simple Podfile with GoogleUtilities workaround"

cat > ios/Podfile << 'EOF'
# Simple Podfile for iOS Build
# This Podfile avoids GoogleUtilities header reference issues

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
  
  # Override GoogleUtilities to use a specific version that works
  pod 'GoogleUtilities', '~> 7.12.0'
end

post_install do |installer|
  puts "🔧 Applying simple post-install fixes..."

  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # Set minimum deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end

    # Fix GoogleUtilities with minimal configuration
    if target.name == 'GoogleUtilities'
      puts "🔧 Applying minimal GoogleUtilities fixes..."
      target.build_configurations.each do |config|
        config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_WARN_STRICT_PROTOTYPES'] = 'NO'
      end
    end

    # Remove CwlCatchException if present
    if target.name == 'CwlCatchException' || target.name == 'CwlCatchExceptionSupport'
      puts "🔧 Excluding #{target.name} to prevent Swift compiler errors"
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphoneos*]'] = 'arm64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end

    # Fix module configuration for other pods
    if ['url_launcher_ios', 'flutter_inappwebview_ios', 'firebase_messaging', 'firebase_core'].include?(target.name)
      puts "🔧 Fixing module configuration for #{target.name}..."
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
  end

  puts "✅ Simple post-install fixes completed successfully"
end
EOF

echo "✅ [SIMPLE_PODFILE] Simple Podfile generated successfully"
echo "🔍 [SIMPLE_PODFILE] Key features:"
echo "  - Uses GoogleUtilities 7.12.0 (known working version)"
echo "  - Minimal header configuration"
echo "  - Basic module fixes"
echo "  - iOS 13.0 deployment target"

# Display the generated Podfile contents
echo ""
echo "🔍 [SIMPLE_PODFILE] Generated Podfile contents:"
echo "=========================================="
cat ios/Podfile
echo "=========================================="
echo ""

echo "✅ [SIMPLE_PODFILE] Simple Podfile ready for use" 