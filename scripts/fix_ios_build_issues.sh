#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [IOS_BUILD_FIX] ❌ $1"; }

log "🔧 Fixing iOS Build Issues"

# Step 1: Fix CwlCatchException Swift compiler error
log_info "Step 1: Fixing CwlCatchException Swift compiler error"

# Remove CwlCatchException pods from Pods project
if [ -d "ios/Pods/CwlCatchException" ]; then
    log_info "Removing CwlCatchException pod"
    rm -rf ios/Pods/CwlCatchException
fi

if [ -d "ios/Pods/CwlCatchExceptionSupport" ]; then
    log_info "Removing CwlCatchExceptionSupport pod"
    rm -rf ios/Pods/CwlCatchExceptionSupport
fi

# Update Pods project file to remove these targets
if [ -f "ios/Pods/Pods.xcodeproj/project.pbxproj" ]; then
    log_info "Updating Pods project file"
    
    # Create backup
    cp ios/Pods/Pods.xcodeproj/project.pbxproj ios/Pods/Pods.xcodeproj/project.pbxproj.bak
    
    # Remove CwlCatchException targets from project file
    sed -i '' '/CwlCatchException/d' ios/Pods/Pods.xcodeproj/project.pbxproj
    sed -i '' '/CwlCatchExceptionSupport/d' ios/Pods/Pods.xcodeproj/project.pbxproj
    
    log_success "Updated Pods project file"
fi

log_success "CwlCatchException pods removed successfully"

# Step 2: Fix GoogleUtilities header file issues
log_info "Step 2: Fixing GoogleUtilities header file issues"

if [ -d "ios/Pods/GoogleUtilities" ]; then
    log_info "Fixing GoogleUtilities header paths"
    
    # Create missing header directories
    mkdir -p ios/Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted
    mkdir -p ios/Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities
    mkdir -p ios/Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities
    mkdir -p ios/Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities
    mkdir -p ios/Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities
    
    # Copy header files to the expected locations
    if [ -f "ios/Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h" ]; then
        cp ios/Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h ios/Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted/
    fi
    
    if [ -f "ios/Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h" ]; then
        cp ios/Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h ios/Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities/
    fi
    
    if [ -f "ios/Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h" ]; then
        cp ios/Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h ios/Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/
    fi
    
    if [ -f "ios/Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h" ]; then
        cp ios/Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h ios/Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities/
    fi
    
    if [ -f "ios/Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h" ]; then
        cp ios/Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h ios/Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities/
    fi
    
    log_success "GoogleUtilities header files fixed"
fi

# Step 3: Fix provisioning profile issues
log_info "Step 3: Fixing provisioning profile issues"

# Ensure exportOptions.plist exists with correct configuration
log_info "Creating/updating exportOptions.plist"

mkdir -p scripts

cat > scripts/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${PROFILE_TYPE:-app-store}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>${APP_NAME}</string>
    </dict>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

log_success "Created exportOptions.plist"

# Step 4: Update Xcode project settings for automatic signing
log_info "Step 4: Updating Xcode project settings"

if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_info "Updating project.pbxproj for automatic signing"
    
    # Create backup
    cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.bak
    
    # Update code signing settings - be more aggressive about automatic signing
    sed -i '' 's/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/CODE_SIGN_STYLE = "Manual";/CODE_SIGN_STYLE = "Automatic";/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = '"$APPLE_TEAM_ID"';/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = "'"$APPLE_TEAM_ID"'";/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = ".*";/PRODUCT_BUNDLE_IDENTIFIER = "'"$BUNDLE_ID"'";/g' ios/Runner.xcodeproj/project.pbxproj
    
    # Also set automatic signing for all configurations
    sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Developer";/CODE_SIGN_IDENTITY = "Apple Development";/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/CODE_SIGN_IDENTITY = "iPhone Distribution";/CODE_SIGN_IDENTITY = "Apple Development";/g' ios/Runner.xcodeproj/project.pbxproj
    
    log_success "Updated project.pbxproj"
fi

# Step 5: Handle speech_to_text dependency issue
log_info "Step 5: Handling speech_to_text dependency issue"

# Use the dedicated script to handle speech_to_text dependency
if [ -f "scripts/fix_speech_to_text_dependency.sh" ]; then
    chmod +x scripts/fix_speech_to_text_dependency.sh
    ./scripts/fix_speech_to_text_dependency.sh
else
    log_warning "fix_speech_to_text_dependency.sh not found, using fallback approach"
    
    # Check if speech_to_text is being used
    if grep -q "speech_to_text" pubspec.yaml; then
        log_warning "speech_to_text plugin detected - this may cause CwlCatchException to be reinstalled"
        log_info "Creating post-install hook to remove CwlCatchException after pod install"
        
        # Create a post-install script
        cat > ios/remove_cwl_catch_exception.rb << 'EOF'
post_install do |installer|
  # Remove CwlCatchException pods after installation
  installer.pods_project.targets.each do |target|
    if target.name == 'CwlCatchException' || target.name == 'CwlCatchExceptionSupport'
      puts "Removing #{target.name} from build"
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphoneos*]'] = 'arm64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
  
  # Also remove from Pods project file
  pods_project_path = installer.pods_project.path
  project_contents = File.read(pods_project_path)
  project_contents.gsub!(/CwlCatchException[^}]*}/, '')
  project_contents.gsub!(/CwlCatchExceptionSupport[^}]*}/, '')
  File.write(pods_project_path, project_contents)
end
EOF
        
        # Update Podfile to include the post-install hook
        if [ -f "ios/Podfile" ]; then
            log_info "Updating Podfile with post-install hook"
            
            # Create backup
            cp ios/Podfile ios/Podfile.bak
            
            # Add the post-install hook at the end
            echo "" >> ios/Podfile
            echo "# Post-install hook to remove CwlCatchException" >> ios/Podfile
            echo "require_relative 'remove_cwl_catch_exception'" >> ios/Podfile
            
            log_success "Updated Podfile"
        fi
    fi
fi

# Step 6: Clean and reinstall pods with fix
log_info "Step 6: Cleaning and reinstalling pods"

cd ios
if [ -d "Pods" ]; then
    log_info "Cleaning pods"
    rm -rf Pods
    rm -f Podfile.lock
fi

log_info "Installing pods"
pod install --repo-update

# Step 7: Remove CwlCatchException again after pod install
log_info "Step 7: Removing CwlCatchException after pod install"

if [ -d "Pods/CwlCatchException" ]; then
    log_info "Removing CwlCatchException pod (post-install)"
    rm -rf Pods/CwlCatchException
fi

if [ -d "Pods/CwlCatchExceptionSupport" ]; then
    log_info "Removing CwlCatchExceptionSupport pod (post-install)"
    rm -rf Pods/CwlCatchExceptionSupport
fi

# Update Pods project file again
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
    log_info "Updating Pods project file (post-install)"
    
    # Create backup
    cp Pods/Pods.xcodeproj/project.pbxproj Pods/Pods.xcodeproj/project.pbxproj.bak2
    
    # Remove CwlCatchException targets from project file
    sed -i '' '/CwlCatchException/d' Pods/Pods.xcodeproj/project.pbxproj
    sed -i '' '/CwlCatchExceptionSupport/d' Pods/Pods.xcodeproj/project.pbxproj
    
    log_success "Updated Pods project file (post-install)"
fi

# Step 8: Fix GoogleUtilities headers again after pod install
log_info "Step 8: Fixing GoogleUtilities headers after pod install"

if [ -d "Pods/GoogleUtilities" ]; then
    log_info "Fixing GoogleUtilities header paths (post-install)"
    
    # Create missing header directories
    mkdir -p Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted
    mkdir -p Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities
    mkdir -p Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities
    mkdir -p Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities
    mkdir -p Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities
    
    # Copy header files to the expected locations
    if [ -f "Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h" ]; then
        cp Pods/GoogleUtilities/third_party/IsAppEncrypted/IsAppEncrypted.h Pods/GoogleUtilities/third_party/IsAppEncrypted/Public/IsAppEncrypted/
    fi
    
    if [ -f "Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h" ]; then
        cp Pods/GoogleUtilities/GoogleUtilities/UserDefaults/GULUserDefaults.h Pods/GoogleUtilities/GoogleUtilities/UserDefaults/Public/GoogleUtilities/
    fi
    
    if [ -f "Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h" ]; then
        cp Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/GULSceneDelegateSwizzler.h Pods/GoogleUtilities/GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/
    fi
    
    if [ -f "Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h" ]; then
        cp Pods/GoogleUtilities/GoogleUtilities/Reachability/GULReachabilityChecker.h Pods/GoogleUtilities/GoogleUtilities/Reachability/Public/GoogleUtilities/
    fi
    
    if [ -f "Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h" ]; then
        cp Pods/GoogleUtilities/GoogleUtilities/Network/GULNetworkURLSession.h Pods/GoogleUtilities/GoogleUtilities/Network/Public/GoogleUtilities/
    fi
    
    log_success "GoogleUtilities header files fixed (post-install)"
fi

cd ..

log_success "✅ iOS build issues fixed successfully"
exit 0 