# 🚀 Complete iOS Workflow Setup for Codemagic

## ✅ **Overview**

This document provides a complete step-by-step setup for a comprehensive iOS workflow in Codemagic that includes:

- ✅ **Assertions (asset/scripts) download**
- 🎨 **Branding: App Name, Icon, Splash screen, Colors**
- 🧩 **Dynamic value injection**
- 📦 **IPA archive & export**
- ⬆️ **TestFlight upload (IS_TESTFLIGHT)**
- 🛎️ **Email notification on build success/failure**
- ✅ **iOS-specific Customizations (like app permissions, bundle ID changes only for Runner target)**

## 📁 **File Structure**

```
quikapp22/
├── codemagic.yaml                    # Main workflow configuration
├── scripts/
│   ├── validate_env.sh              # Environment variable validation
│   ├── download_assets.sh           # Download assets and certificates
│   ├── change_app_name.sh           # Change app name
│   ├── change_app_icon.sh           # Change app icon
│   ├── update_bundle_id.sh          # Update bundle ID
│   ├── set_version.sh               # Set app version
│   ├── configure_permissions.sh     # Configure app permissions
│   ├── gen_env_config.sh            # Generate environment configs
│   ├── send_email_notification.sh   # Send email notifications
│   ├── mailer.py                    # Python email script
│   └── exportOptions.plist          # iOS export options
└── lib/
    └── config/
        ├── env_config.dart          # Generated environment config
        └── environment.g.dart       # Generated environment file
```

## 🔧 **Environment Variables Required**

### **Core App Configuration**
```bash
APP_NAME="Your App Name"
BUNDLE_ID="com.yourcompany.yourapp"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
APP_ID="your-app-id"
ORG_NAME="Your Organization"
WEB_URL="https://yourwebsite.com"
PKG_NAME="com.yourcompany.yourapp"
```

### **User Information**
```bash
USER_NAME="Your Name"
EMAIL_ID="your.email@example.com"
```

### **Feature Flags**
```bash
PUSH_NOTIFY="true"
IS_CHATBOT="false"
IS_DOMAIN_URL="false"
IS_SPLASH="true"
IS_PULLDOWN="true"
IS_BOTTOMMENU="true"
IS_LOAD_IND="true"
```

### **Permissions**
```bash
IS_CAMERA="true"
IS_LOCATION="true"
IS_MIC="true"
IS_NOTIFICATION="true"
IS_CONTACT="false"
IS_BIOMETRIC="false"
IS_CALENDAR="false"
IS_STORAGE="true"
```

### **UI Configuration**
```bash
LOGO_URL="https://example.com/logo.png"
SPLASH_URL="https://example.com/splash.png"
SPLASH_BG_COLOR="#FFFFFF"
SPLASH_TAGLINE="Your App Tagline"
SPLASH_TAGLINE_COLOR="#000000"
SPLASH_BG_URL="https://example.com/splash-bg.png"
SPLASH_ANIMATION="fade"
SPLASH_DURATION="3000"
```

### **Bottom Menu Configuration**
```bash
BOTTOMMENU_ITEMS="home,profile,settings"
BOTTOMMENU_BG_COLOR="#FFFFFF"
BOTTOMMENU_ICON_COLOR="#000000"
BOTTOMMENU_TEXT_COLOR="#000000"
BOTTOMMENU_FONT="Roboto"
BOTTOMMENU_FONT_SIZE="14"
BOTTOMMENU_FONT_BOLD="false"
BOTTOMMENU_FONT_ITALIC="false"
BOTTOMMENU_ACTIVE_TAB_COLOR="#007AFF"
BOTTOMMENU_ICON_POSITION="top"
```

### **Firebase Configuration**
```bash
FIREBASE_CONFIG_IOS="https://example.com/GoogleService-Info.plist"
FIREBASE_CONFIG_ANDROID="https://example.com/google-services.json"
```

### **iOS Signing**
```bash
APPLE_TEAM_ID="YOUR_TEAM_ID"
PROFILE_TYPE="app-store"
IS_TESTFLIGHT="true"
```

### **Email Configuration**
```bash
ENABLE_EMAIL_NOTIFICATIONS="true"
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="your.email@gmail.com"
EMAIL_SMTP_PASS="your-app-password"
```

### **APNS Configuration**
```bash
APNS_KEY_ID="YOUR_APNS_KEY_ID"
APNS_AUTH_KEY_URL="https://example.com/AuthKey.p8"
```

### **Android Keystore**
```bash
KEY_STORE_URL="https://example.com/keystore.jks"
CM_KEYSTORE_PASSWORD="your-keystore-password"
CM_KEY_ALIAS="your-key-alias"
CM_KEY_PASSWORD="your-key-password"
```

### **App Store Connect**
```bash
APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_API_KEY_URL="https://example.com/AuthKey.p8"
```

### **Workflow**
```bash
WORKFLOW_ID="ios-workflow"
```

## 📋 **Workflow Steps**

### **1. 🔍 Validate Required Environment Vars**
- Validates all required environment variables
- Ensures all necessary configuration is present
- Exits with error if any required variables are missing

### **2. ⬇️ Download Assets (icons, splash, certificates)**
- Downloads app logo from `LOGO_URL`
- Downloads splash screen from `SPLASH_URL`
- Downloads Firebase configuration files
- Downloads iOS provisioning profile
- Downloads App Store Connect API key
- Downloads APNS auth key
- Downloads Android keystore
- Creates default assets if URLs are not provided

### **3. 🎨 Change App Name and Icons**
- Updates iOS Info.plist with new app name
- Updates Android strings.xml with new app name
- Updates pubspec.yaml with new app name
- Generates app icons using flutter_launcher_icons
- Falls back to manual icon copying if flutter_launcher_icons fails

### **4. 🎯 Update Bundle ID and Versioning**
- Updates iOS project.pbxproj bundle identifier
- Updates Android build.gradle applicationId
- Updates AndroidManifest.xml package name
- Updates MainActivity.kt package name
- Updates pubspec.yaml version
- Updates iOS Info.plist version strings
- Updates Android build.gradle version strings

### **5. ⚙️ Inject Permissions and Features**
- Adds iOS permissions to Info.plist based on feature flags
- Adds Android permissions to AndroidManifest.xml
- Supports camera, location, microphone, notifications, contacts, biometric, calendar, storage
- Adds basic Android permissions (internet, network state, wake lock)

### **6. 🚀 Generate Env Configs (env_config.dart, Info.plist, etc)**
- Generates `lib/config/env_config.dart` with all environment variables
- Generates `lib/config/environment.g.dart` for Flutter
- Generates `scripts/exportOptions.plist` for iOS export
- Generates `.env` file for local development

### **7. 🧪 Run Flutter Tests**
- Runs `flutter test` to ensure code quality
- Fails build if tests fail

### **8. 🏗️ Build and Archive iOS (.ipa)**
- Runs `flutter build ios --release --no-codesign`
- Creates Xcode archive using xcodebuild
- Sets development team and bundle identifier

### **9. 📦 Export IPA**
- Exports IPA using xcodebuild
- Uses generated exportOptions.plist
- Allows provisioning updates

### **10. ⬆️ Upload to TestFlight (optional)**
- Uploads to TestFlight if `IS_TESTFLIGHT` is "true"
- Uses App Store Connect API
- Requires valid API credentials

### **11. ✉️ Email Notification**
- Sends success/failure email notifications
- Uses SMTP configuration
- Includes build details and status

## 🔧 **Script Details**

### **validate_env.sh**
```bash
# Validates all required environment variables
# Exits with error if any are missing
# Logs all variables for debugging
```

### **download_assets.sh**
```bash
# Downloads all assets from URLs
# Creates default assets if URLs not provided
# Sets proper permissions for certificates
```

### **change_app_name.sh**
```bash
# Updates app name in all platform files
# Supports iOS and Android
# Updates pubspec.yaml
```

### **change_app_icon.sh**
```bash
# Generates app icons using flutter_launcher_icons
# Falls back to manual copying
# Supports all platforms
```

### **update_bundle_id.sh**
```bash
# Updates bundle ID in all platform files
# Supports iOS and Android
# Updates package names
```

### **set_version.sh**
```bash
# Updates version in all platform files
# Supports iOS and Android
# Updates version name and code
```

### **configure_permissions.sh**
```bash
# Adds permissions based on feature flags
# Supports iOS and Android
# Adds basic permissions automatically
```

### **gen_env_config.sh**
```bash
# Generates environment configuration files
# Creates Dart files for Flutter
# Creates iOS export options
```

### **send_email_notification.sh**
```bash
# Sends email notifications
# Uses Python mailer script
# Includes build details
```

### **mailer.py**
```python
# Python script for sending emails
# Uses SMTP configuration
# Handles errors gracefully
```

## 📦 **Artifacts**

The workflow produces the following artifacts:

- `build/export/*.ipa` - iOS app package
- `flutter_drive.log` - Flutter test logs

## 🚀 **Usage**

### **1. Set Environment Variables**
Set all required environment variables in Codemagic:

```yaml
environment:
  vars:
    APP_NAME: "Your App Name"
    BUNDLE_ID: "com.yourcompany.yourapp"
    # ... all other variables
```

### **2. Configure Credentials**
Add credential groups in Codemagic:

```yaml
groups:
  - app_store_credentials
  - firebase_credentials
  - email_credentials
```

### **3. Run Workflow**
Trigger the workflow in Codemagic:

```bash
# The workflow will automatically:
# 1. Validate environment variables
# 2. Download assets
# 3. Configure app branding
# 4. Set up permissions
# 5. Build and archive
# 6. Export IPA
# 7. Upload to TestFlight (if enabled)
# 8. Send email notification
```

## ✅ **Benefits**

1. **Dynamic Configuration**: All values are injected from environment variables
2. **Comprehensive Asset Management**: Downloads and configures all assets
3. **Automatic Branding**: Changes app name, icon, and splash screen
4. **Permission Management**: Conditionally adds permissions based on flags
5. **Version Control**: Automatically updates version information
6. **TestFlight Integration**: Optional upload to TestFlight
7. **Email Notifications**: Success/failure notifications
8. **Error Handling**: Comprehensive error handling and logging
9. **Caching**: Efficient caching for faster builds
10. **Security**: Secure handling of certificates and credentials

## 🔧 **Customization**

### **Adding New Features**
1. Add new environment variables to the validation script
2. Update the configuration generation script
3. Add new build steps as needed

### **Modifying Permissions**
1. Update the `configure_permissions.sh` script
2. Add new permission flags to environment variables
3. Update iOS and Android permission mappings

### **Custom Build Steps**
1. Add new scripts to the `scripts/` directory
2. Update the workflow in `codemagic.yaml`
3. Ensure proper error handling and logging

## 📋 **Troubleshooting**

### **Common Issues**

1. **Missing Environment Variables**
   - Check the validation script output
   - Ensure all required variables are set in Codemagic

2. **Asset Download Failures**
   - Verify URLs are accessible
   - Check network connectivity
   - Review download script logs

3. **Build Failures**
   - Check Xcode build logs
   - Verify signing configuration
   - Ensure all certificates are valid

4. **TestFlight Upload Issues**
   - Verify App Store Connect API credentials
   - Check API key permissions
   - Review upload logs

5. **Email Notification Failures**
   - Verify SMTP configuration
   - Check email credentials
   - Review Python mailer logs

## ✅ **Status: Complete**

The iOS workflow setup is now complete with:

- ✅ All scripts created and configured
- ✅ Environment variable validation
- ✅ Asset download and management
- ✅ Dynamic app branding
- ✅ Permission configuration
- ✅ Version management
- ✅ Build and archive process
- ✅ TestFlight integration
- ✅ Email notifications
- ✅ Comprehensive error handling
- ✅ Detailed logging and documentation

The workflow is ready for use in Codemagic with all the requested features implemented! 