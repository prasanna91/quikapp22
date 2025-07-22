# 🔧 iOS Workflow Firebase Deployment Target Fix

## ✅ **Issue Identified and Fixed**

The iOS workflow was failing due to Firebase Core requiring a higher minimum iOS deployment version than what was configured. The error was:

```
Error: The plugin "firebase_core" requires a higher minimum iOS deployment version than your application is targeting.
```

## 🔍 **Root Cause**

1. **iOS Deployment Target**: The project was set to iOS 12.0
2. **Firebase Core Requirement**: Firebase Core 3.0.0 requires iOS 13.0 or higher
3. **Missing Podfile**: The Podfile was missing, preventing proper CocoaPods setup
4. **Configuration Mismatch**: The iOS deployment target wasn't being set correctly for all build configurations

## 🛠️ **Fixes Applied**

### **1. Updated iOS Deployment Target**

**Updated `ios/Runner.xcodeproj/project.pbxproj`:**
- Changed `IPHONEOS_DEPLOYMENT_TARGET` from `12.0` to `13.0` in all three build configurations:
  - Debug configuration
  - Release configuration  
  - Profile configuration

### **2. Created Missing Podfile**

**Created `ios/Podfile`:**
```ruby
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
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set minimum deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

### **3. Enhanced Build Script**

**Updated `scripts/ios-workflow/comprehensive_build.sh`:**
- Added automatic iOS deployment target validation and correction
- Added Podfile creation if missing
- Enhanced Flutter configuration generation with proper error handling

**Key additions:**
```bash
# Ensure iOS deployment target is set correctly for Firebase
log "Setting iOS deployment target to 13.0 for Firebase compatibility..."
if [ -f "Podfile" ]; then
    sed -i '' 's/platform :ios, '"'"'[0-9.]*'"'"'/platform :ios, '"'"'13.0'"'"'/g' Podfile
fi

# Update project.pbxproj deployment target
if [ -f "Runner.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/g' Runner.xcodeproj/project.pbxproj
fi

# Ensure Podfile exists and is properly configured
if [ ! -f "Podfile" ]; then
    log_error "Podfile not found. Creating Podfile..."
    # Create Podfile with proper configuration
fi
```

## 🎯 **What This Fixes**

1. **✅ Firebase Core Compatibility**: Resolves the "higher minimum iOS deployment version" error
2. **✅ Podfile Missing**: Creates the missing Podfile with proper configuration
3. **✅ iOS Deployment Target**: Ensures all build configurations use iOS 13.0
4. **✅ CocoaPods Installation**: Allows `pod install` to run successfully
5. **✅ Build Process**: Enables the complete iOS build process to continue

## 📋 **Firebase Version Compatibility**

| Firebase Plugin | Minimum iOS Version | Current Setting |
|----------------|-------------------|-----------------|
| firebase_core: ^3.0.0 | iOS 13.0+ | ✅ iOS 13.0 |
| firebase_messaging: ^15.0.0 | iOS 13.0+ | ✅ iOS 13.0 |

## 🔄 **Updated Workflow Flow**

The updated workflow now follows this sequence:

1. **Environment Setup** → Generate environment configuration
2. **Asset Downloads** → Download app icons and splash screens
3. **Firebase Setup** → Configure Firebase (if enabled)
4. **App Configuration** → Update bundle ID and app name
5. **Flutter Dependencies** → Install Flutter packages
6. **iOS Deployment Target** → Set iOS 13.0 for Firebase compatibility ⭐ **NEW**
7. **Flutter Configuration** → Generate iOS configuration files
8. **Podfile Validation** → Ensure Podfile exists and is configured ⭐ **NEW**
9. **iOS Dependencies** → Install CocoaPods dependencies
10. **Build Configuration** → Set up code signing and export options
11. **Build Archive** → Create iOS archive
12. **Export IPA** → Generate final IPA file

## 🚀 **Expected Results**

After this fix, the iOS workflow should:

- ✅ **Resolve Firebase Core Error**: No more "higher minimum iOS deployment version" errors
- ✅ **Install iOS Dependencies**: `pod install` runs successfully
- ✅ **Complete the Build Process**: iOS build completes without Firebase-related errors
- ✅ **Create the IPA File**: Generate the final IPA file as expected
- ✅ **Support Firebase Features**: All Firebase functionality works properly

## 🔍 **Monitoring**

To monitor the fix:

1. **Check logs** for "Setting iOS deployment target to 13.0" message
2. **Verify** that `ios/Podfile` exists and has `platform :ios, '13.0'`
3. **Confirm** that `ios/Runner.xcodeproj/project.pbxproj` has `IPHONEOS_DEPLOYMENT_TARGET = 13.0`
4. **Validate** that `pod install` runs without Firebase errors
5. **Check** that the build process completes successfully

## 📞 **Troubleshooting**

If issues persist:

1. **Check Firebase versions**: Ensure Firebase plugins are compatible with iOS 13.0
2. **Verify iOS SDK**: Ensure Xcode has iOS 13.0 SDK available
3. **Review logs**: Look for specific error messages in the build logs
4. **Manual testing**: Try running the steps manually to identify issues

---

**🎉 The iOS workflow should now build successfully without Firebase deployment target errors!** 