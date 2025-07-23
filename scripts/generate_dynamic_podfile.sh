#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_GEN] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_GEN] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_GEN] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_GEN] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [PODFILE_GEN] ❌ $1"; }

log "🔧 Generating Dynamic Podfile"

# Check if we're in the ios directory or need to navigate there
if [ -d "ios" ]; then
    cd ios
fi

# Create backup of original Podfile if it exists
if [ -f "Podfile" ]; then
    log_info "Creating backup of original Podfile"
    cp Podfile Podfile.original
fi

# Generate dynamic Podfile with all fixes
log_info "Generating dynamic Podfile with comprehensive fixes"

cat > Podfile << 'EOF'
# Dynamically Generated Podfile for iOS Build
# Generated on: $(date)
# This Podfile includes all necessary fixes for iOS build issues

# Uncomment this line to define a global platform for your project
platform :ios, '13.0' # Updated to 13.0 for Firebase compatibility

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
end

post_install do |installer|
  puts "🔧 Applying comprehensive post-install fixes..."
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set minimum deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0' # Updated to 13.0
      
      # Fix for CocoaPods configuration warning
      if config.base_configuration_reference
        config.base_configuration_reference = nil
      end
    end
    
    # Fix GoogleUtilities header file issues
    if target.name == 'GoogleUtilities'
      puts "🔧 Fixing GoogleUtilities header paths..."
      target.build_configurations.each do |config|
        # Add comprehensive header search paths for GoogleUtilities
        config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Internal'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/Common'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/Environment'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/Logger'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/Network'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/Reachability'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/GoogleUtilities/UserDefaults'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/third_party/IsAppEncrypted'
        config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/GoogleUtilities/third_party/IsAppEncrypted/Public'
      end
    end
    
    # Remove CwlCatchException if present (prevents Swift compiler errors)
    if target.name == 'CwlCatchException' || target.name == 'CwlCatchExceptionSupport'
      puts "🔧 Removing #{target.name} from build to prevent Swift compiler errors"
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphoneos*]'] = 'arm64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        config.build_settings['SWIFT_VERSION'] = '5.0'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'NO'
        config.build_settings['DEFINES_MODULE'] = 'NO'
      end
    end
    
    # Fix for url_launcher_ios module issues
    if target.name == 'url_launcher_ios'
      puts "🔧 Fixing url_launcher_ios module configuration..."
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
    
    # Fix for flutter_inappwebview_ios module issues
    if target.name == 'flutter_inappwebview_ios'
      puts "🔧 Fixing flutter_inappwebview_ios module configuration..."
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
    
    # Fix for firebase_messaging module issues
    if target.name == 'firebase_messaging'
      puts "🔧 Fixing firebase_messaging module configuration..."
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
    
    # Fix for firebase_core module issues
    if target.name == 'firebase_core'
      puts "🔧 Fixing firebase_core module configuration..."
      target.build_configurations.each do |config|
        config.build_settings['DEFINES_MODULE'] = 'YES'
        config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      end
    end
  end
  
  # Fix GoogleUtilities header files after installation
  google_utilities_path = File.join(installer.sandbox.root, 'GoogleUtilities')
  if Dir.exist?(google_utilities_path)
    puts "🔧 Fixing GoogleUtilities header files..."
    
    # Define the problematic headers and their expected locations
    header_mappings = {
      'IsAppEncrypted.h' => [
        'third_party/IsAppEncrypted/IsAppEncrypted.h',
        'third_party/IsAppEncrypted/Public/IsAppEncrypted.h'
      ],
      'GULUserDefaults.h' => [
        'GoogleUtilities/UserDefaults/GULUserDefaults.h',
        'GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h'
      ],
      'GULSceneDelegateSwizzler.h' => [
        'GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h',
        'GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h'
      ],
      'GULReachabilityChecker.h' => [
        'GoogleUtilities/Reachability/GULReachabilityChecker.h',
        'GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h'
      ],
      'GULNetworkURLSession.h' => [
        'GoogleUtilities/Network/GULNetworkURLSession.h',
        'GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h'
      ]
    }
    
    # Copy headers to all expected locations
    header_mappings.each do |header_name, expected_paths|
      # Find the actual header file
      actual_header = nil
      Dir.glob(File.join(google_utilities_path, '**', header_name)).each do |found_header|
        actual_header = found_header
        break
      end
      
      if actual_header
        puts "  ✅ Found #{header_name} at: #{actual_header}"
        
        # Copy to all expected locations
        expected_paths.each do |expected_path|
          target_dir = File.join(google_utilities_path, File.dirname(expected_path))
          target_file = File.join(target_dir, header_name)
          
          unless Dir.exist?(target_dir)
            FileUtils.mkdir_p(target_dir)
            puts "    ✅ Created directory: #{target_dir}"
          end
          
          unless File.exist?(target_file)
            begin
              FileUtils.cp(actual_header, target_file)
              puts "    ✅ Copied #{header_name} to: #{target_file}"
            rescue => e
              puts "    ⚠️ Could not copy #{header_name}: #{e.message}"
              # Try symbolic link as fallback
              begin
                FileUtils.ln_sf(actual_header, target_file)
                puts "    ✅ Created symbolic link for #{header_name} to: #{target_file}"
              rescue => e2
                puts "    ❌ Could not create symbolic link for #{header_name}: #{e2.message}"
              end
            end
          end
        end
      else
        puts "  ⚠️ Could not find #{header_name}"
      end
    end
    
    # Also copy all .h files to their Public directories for broader coverage
    Dir.glob(File.join(google_utilities_path, '**', '*.h')).each do |header_file|
      relative_path = Pathname.new(header_file).relative_path_from(Pathname.new(google_utilities_path))
      public_dir = File.join(File.dirname(header_file), 'Public', File.dirname(relative_path))
      
      unless Dir.exist?(public_dir)
        FileUtils.mkdir_p(public_dir)
      end
      
      public_header = File.join(public_dir, File.basename(header_file))
      unless File.exist?(public_header)
        FileUtils.cp(header_file, public_header)
      end
    end
  end
  
  # Suppress master specs repo warning
  puts "✅ CocoaPods installation completed successfully with all fixes applied"
end
EOF

log_success "✅ Dynamic Podfile generated successfully"

# Make the Podfile executable
chmod +x Podfile

log_info "Podfile contents:"
echo "=========================================="
head -20 Podfile
echo "..."
tail -10 Podfile
echo "=========================================="

log_success "✅ Dynamic Podfile ready for use"
exit 0 