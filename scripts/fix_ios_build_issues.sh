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

# Always remove CwlCatchException pods as they cause Swift compiler errors
# These are test-only dependencies that shouldn't be in any production build
log_info "Removing CwlCatchException pods to prevent Swift compiler errors"

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

# Step 2: Fix provisioning profile issues
log_info "Step 2: Fixing provisioning profile issues"

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

# Step 3: Update Xcode project settings for automatic signing
log_info "Step 3: Updating Xcode project settings"

if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_info "Updating project.pbxproj for automatic signing"
    
    # Create backup
    cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.bak
    
    # Update code signing settings
    sed -i '' 's/CODE_SIGN_STYLE = Manual;/CODE_SIGN_STYLE = Automatic;/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/DEVELOPMENT_TEAM = "";/DEVELOPMENT_TEAM = '"$APPLE_TEAM_ID"';/g' ios/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = ".*";/PRODUCT_BUNDLE_IDENTIFIER = "'"$BUNDLE_ID"'";/g' ios/Runner.xcodeproj/project.pbxproj
    
    log_success "Updated project.pbxproj"
fi

# Step 4: Clean and reinstall pods if needed
log_info "Step 4: Cleaning and reinstalling pods"

cd ios
if [ -d "Pods" ]; then
    log_info "Cleaning pods"
    rm -rf Pods
    rm -f Podfile.lock
fi

log_info "Installing pods"
pod install --repo-update

cd ..

log_success "✅ iOS build issues fixed successfully"
exit 0 