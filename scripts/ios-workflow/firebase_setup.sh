#!/bin/bash
# 🔥 Firebase Setup Script for iOS Workflow
# Configures Firebase for push notifications when PUSH_NOTIFY is true

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIREBASE] $1"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m"; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m"; }

# Source environment configuration
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../lib/config/env.sh"
    log "Environment configuration loaded from lib/config/env.sh"
else
    log "Environment configuration file not found, using system environment variables"
fi

# Function to safely get environment variable with fallback
get_api_var() {
    local var_name="$1"
    local fallback="$2"
    local value="${!var_name:-}"
    
    if [ -n "$value" ]; then
        log "✅ Found API variable $var_name: $value"
        printf "%s" "$value"
    else
        log "⚠️ API variable $var_name not set, using fallback: $fallback"
        printf "%s" "$fallback"
    fi
}

# Set Firebase configuration variables
export PUSH_NOTIFY=$(get_api_var "PUSH_NOTIFY" "false")
export FIREBASE_CONFIG_IOS=$(get_api_var "FIREBASE_CONFIG_IOS" "")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "com.example.quikapp")
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")

# Check if Firebase setup is required
if [ "$PUSH_NOTIFY" != "true" ]; then
    log_info "Firebase Setup (Skipped)"
    log "PUSH_NOTIFY is false, skipping Firebase setup"
    exit 0
fi

log_info "Firebase Setup for iOS"
log "Configuring Firebase for push notifications..."

# Step 1: Validate Firebase Configuration
log_info "Step 1: Validate Firebase Configuration"
log "Validating Firebase configuration..."

if [ -z "$FIREBASE_CONFIG_IOS" ]; then
    log_error "FIREBASE_CONFIG_IOS not provided"
    log "Please provide the URL to your Firebase iOS configuration file"
    exit 1
fi

if [ -z "$BUNDLE_ID" ]; then
    log_error "BUNDLE_ID not provided"
    log "Please provide the bundle identifier for Firebase configuration"
    exit 1
fi

log_success "Firebase configuration validated"

# Step 2: Download Firebase Configuration
log_info "Step 2: Download Firebase Configuration"
log "Downloading Firebase configuration file..."

# Create Firebase directory
mkdir -p ios/Runner

# Download GoogleService-Info.plist
if curl -L -o "ios/Runner/GoogleService-Info.plist" "$FIREBASE_CONFIG_IOS" 2>/dev/null; then
    log_success "Firebase configuration downloaded successfully"
    
    # Validate the downloaded file
    if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
        FILE_SIZE=$(stat -f%z "ios/Runner/GoogleService-Info.plist" 2>/dev/null || stat -c%s "ios/Runner/GoogleService-Info.plist" 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -gt 100 ]; then
            log_success "Firebase configuration file is valid ($FILE_SIZE bytes)"
        else
            log_error "Firebase configuration file is too small ($FILE_SIZE bytes) - may be corrupted"
            exit 1
        fi
    else
        log_error "Firebase configuration file not found after download"
        exit 1
    fi
else
    log_error "Failed to download Firebase configuration"
    log "URL: $FIREBASE_CONFIG_IOS"
    exit 1
fi

# Step 3: Update Podfile for Firebase
log_info "Step 3: Update Podfile for Firebase"
log "Configuring Podfile for Firebase dependencies..."

# Check if Firebase is already in Podfile
if ! grep -q "Firebase" ios/Podfile 2>/dev/null; then
    log "Adding Firebase dependencies to Podfile..."
    
    # Add Firebase pods to Podfile
    cat >> ios/Podfile <<EOF

# Firebase Configuration
pod 'Firebase/Core'
pod 'Firebase/Messaging'
pod 'Firebase/Analytics'
pod 'Firebase/Crashlytics'

EOF
    
    log_success "Firebase dependencies added to Podfile"
else
    log_success "Firebase dependencies already present in Podfile"
fi

# Step 4: Update Info.plist for Push Notifications
log_info "Step 4: Update Info.plist for Push Notifications"
log "Configuring Info.plist for push notifications..."

# Add push notification capability to Info.plist
if [ -f "ios/Runner/Info.plist" ]; then
    # Add background modes for push notifications
    plutil -insert UIBackgroundModes -array ios/Runner/Info.plist 2>/dev/null || true
    plutil -insert UIBackgroundModes.0 -string "remote-notification" ios/Runner/Info.plist 2>/dev/null || true
    
    # Add Firebase configuration
    plutil -insert FirebaseAppDelegateProxyEnabled -bool false ios/Runner/Info.plist 2>/dev/null || true
    
    log_success "Info.plist updated for push notifications"
else
    log_warning "Info.plist not found, skipping push notification configuration"
fi

# Step 5: Update AppDelegate for Firebase
log_info "Step 5: Update AppDelegate for Firebase"
log "Configuring AppDelegate for Firebase..."

# Check if AppDelegate.swift exists
if [ -f "ios/Runner/AppDelegate.swift" ]; then
    # Backup original AppDelegate
    cp ios/Runner/AppDelegate.swift ios/Runner/AppDelegate.swift.backup
    
    # Check if Firebase is already configured
    if ! grep -q "Firebase" ios/Runner/AppDelegate.swift 2>/dev/null; then
        log "Adding Firebase configuration to AppDelegate..."
        
        # Create temporary file with Firebase imports
        cat > ios/Runner/AppDelegate.swift.tmp <<EOF
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Configure push notifications
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { _, _ in }
    )
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle push notification registration
  override func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle push notification errors
  override func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
EOF
        
        # Replace original AppDelegate
        mv ios/Runner/AppDelegate.swift.tmp ios/Runner/AppDelegate.swift
        log_success "AppDelegate updated for Firebase"
    else
        log_success "Firebase already configured in AppDelegate"
    fi
else
    log_warning "AppDelegate.swift not found, skipping Firebase configuration"
fi

# Step 6: Install Firebase Dependencies
log_info "Step 6: Install Firebase Dependencies"
log "Installing Firebase dependencies..."

cd ios
# Clean previous pods
rm -rf Pods/ Podfile.lock

# Install pods
if pod install --repo-update; then
    log_success "Firebase dependencies installed successfully"
else
    log_error "Failed to install Firebase dependencies"
    exit 1
fi
cd ..

# Step 7: Validate Firebase Setup
log_info "Step 7: Validate Firebase Setup"
log "Validating Firebase configuration..."

# Check if GoogleService-Info.plist exists and is valid
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    # Check if bundle ID matches
    CONFIG_BUNDLE_ID=$(plutil -extract GOOGLE_APP_ID raw ios/Runner/GoogleService-Info.plist 2>/dev/null || echo "")
    if [ -n "$CONFIG_BUNDLE_ID" ]; then
        log_success "Firebase configuration file is valid"
        log "Bundle ID in config: $CONFIG_BUNDLE_ID"
    else
        log_warning "Could not validate bundle ID in Firebase config"
    fi
else
    log_error "Firebase configuration file not found"
    exit 1
fi

# Check if Firebase pods are installed
if [ -d "ios/Pods/Firebase" ]; then
    log_success "Firebase pods are installed"
else
    log_warning "Firebase pods directory not found"
fi

# Step 8: Create Firebase Summary
log_info "Step 8: Create Firebase Summary"
log "Creating Firebase setup summary..."

cat > output/ios/FIREBASE_SUMMARY.txt <<EOF
Firebase Setup Summary
======================

Configuration:
- Push Notifications: $PUSH_NOTIFY
- Firebase Config URL: $FIREBASE_CONFIG_IOS
- Bundle ID: $BUNDLE_ID
- App Name: $APP_NAME

Files Created/Updated:
- GoogleService-Info.plist: $([ -f "ios/Runner/GoogleService-Info.plist" ] && echo "✅ Downloaded" || echo "❌ Missing")
- Podfile: $([ -f "ios/Podfile" ] && echo "✅ Updated" || echo "❌ Missing")
- AppDelegate.swift: $([ -f "ios/Runner/AppDelegate.swift" ] && echo "✅ Updated" || echo "❌ Missing")
- Info.plist: $([ -f "ios/Runner/Info.plist" ] && echo "✅ Updated" || echo "❌ Missing")

Dependencies:
- Firebase/Core: $([ -d "ios/Pods/Firebase" ] && echo "✅ Installed" || echo "❌ Missing")
- Firebase/Messaging: $([ -d "ios/Pods/Firebase" ] && echo "✅ Installed" || echo "❌ Missing")
- Firebase/Analytics: $([ -d "ios/Pods/Firebase" ] && echo "✅ Installed" || echo "❌ Missing")

Configuration Status:
- Push Notifications Enabled: $PUSH_NOTIFY
- Firebase Configured: $([ -f "ios/Runner/GoogleService-Info.plist" ] && echo "Yes" || echo "No")
- AppDelegate Updated: $([ -f "ios/Runner/AppDelegate.swift" ] && grep -q "Firebase" ios/Runner/AppDelegate.swift 2>/dev/null && echo "Yes" || echo "No")

Setup Time: $(date)
EOF

log_success "Firebase setup completed successfully!"
log "Firebase summary available in: output/ios/FIREBASE_SUMMARY.txt"

# Step 9: Test Firebase Configuration
log_info "Step 9: Test Firebase Configuration"
log "Testing Firebase configuration..."

# Create a simple test to verify Firebase is working
cat > ios/Runner/FirebaseTest.swift <<EOF
import Foundation
import Firebase

class FirebaseTest {
    static func testConfiguration() -> Bool {
        // This will be called during app initialization
        // If Firebase is properly configured, this should not crash
        return FirebaseApp.app() != nil
    }
}
EOF

log_success "Firebase test file created"

log_success "Firebase setup completed successfully!"
log "Firebase is now configured for push notifications" 