# 🚀 iOS Workflow Documentation

## Overview

This iOS workflow provides a comprehensive solution for building, configuring, and deploying iOS apps with the following features:

- ✅ **Environment Variable Injection** - All variables properly injected into Dart code
- ✅ **Asset Downloads** - Automatic download and configuration of app icons and splash screens
- ✅ **Firebase Setup** - Conditional Firebase configuration when PUSH_NOTIFY=true
- ✅ **TestFlight Upload** - Conditional upload to TestFlight when IS_TESTFLIGHT=true
- ✅ **Email Notifications** - Optional email notifications on build completion
- ✅ **Comprehensive Logging** - Detailed logs for debugging and monitoring

## 📁 Script Structure

```
scripts/ios-workflow/
├── main_workflow.sh          # Main orchestrator script
├── comprehensive_build.sh     # Complete build process
├── asset_download.sh         # Asset download and configuration
├── firebase_setup.sh         # Firebase configuration
├── testflight_upload.sh      # TestFlight upload
└── update_bundle_id_target_only.sh  # Bundle ID updates
```

## 🔧 Required Environment Variables

### Essential Variables (Required)
```bash
BUNDLE_ID="com.yourcompany.yourapp"
APPLE_TEAM_ID="YOUR_TEAM_ID"
PROFILE_TYPE="app-store"  # app-store, ad-hoc, development
```

### App Configuration Variables
```bash
WORKFLOW_ID="ios-workflow"
APP_NAME="Your App Name"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
EMAIL_ID="admin@example.com"
```

### Asset Configuration Variables
```bash
LOGO_URL="https://example.com/logo.png"
SPLASH_URL="https://example.com/splash.png"
SPLASH_BG_COLOR="#FFFFFF"
SPLASH_TAGLINE="Your App Tagline"
SPLASH_TAGLINE_COLOR="#000000"
```

### Firebase Configuration (when PUSH_NOTIFY=true)
```bash
PUSH_NOTIFY="true"
FIREBASE_CONFIG_IOS="https://example.com/GoogleService-Info.plist"
```

### TestFlight Configuration (when IS_TESTFLIGHT=true)
```bash
IS_TESTFLIGHT="true"
APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_API_KEY_URL="https://example.com/AuthKey_KEYID.p8"
```

### Email Configuration (optional)
```bash
ENABLE_EMAIL_NOTIFICATIONS="true"
EMAIL_SMTP_SERVER="smtp.gmail.com"
EMAIL_SMTP_PORT="587"
EMAIL_SMTP_USER="your-email@gmail.com"
EMAIL_SMTP_PASS="your-app-password"
```

### Feature Flags
```bash
IS_CHATBOT="false"
IS_DOMAIN_URL="false"
IS_SPLASH="true"
IS_PULLDOWN="false"
IS_BOTTOMMENU="false"
IS_LOAD_IND="false"
IS_CAMERA="false"
IS_LOCATION="false"
IS_MIC="false"
IS_NOTIFICATION="false"
IS_CONTACT="false"
IS_BIOMETRIC="false"
IS_CALENDAR="false"
IS_STORAGE="false"
```

## 🚀 Usage

### 1. Basic Usage

```bash
# Set required environment variables
export BUNDLE_ID="com.yourcompany.yourapp"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export PROFILE_TYPE="app-store"

# Run the main workflow
./scripts/ios-workflow/main_workflow.sh
```

### 2. With Firebase Setup

```bash
# Set Firebase variables
export PUSH_NOTIFY="true"
export FIREBASE_CONFIG_IOS="https://example.com/GoogleService-Info.plist"

# Run the workflow
./scripts/ios-workflow/main_workflow.sh
```

### 3. With TestFlight Upload

```bash
# Set TestFlight variables
export IS_TESTFLIGHT="true"
export APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_URL="https://example.com/AuthKey_KEYID.p8"

# Run the workflow
./scripts/ios-workflow/main_workflow.sh
```

### 4. Complete Configuration

```bash
# Set all variables
export WORKFLOW_ID="ios-workflow"
export APP_NAME="My Awesome App"
export VERSION_NAME="1.0.0"
export VERSION_CODE="1"
export BUNDLE_ID="com.mycompany.myapp"
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export PROFILE_TYPE="app-store"
export EMAIL_ID="admin@mycompany.com"

# Asset configuration
export LOGO_URL="https://example.com/logo.png"
export SPLASH_URL="https://example.com/splash.png"
export SPLASH_BG_COLOR="#FFFFFF"
export SPLASH_TAGLINE="Welcome to My App"
export SPLASH_TAGLINE_COLOR="#000000"

# Firebase configuration
export PUSH_NOTIFY="true"
export FIREBASE_CONFIG_IOS="https://example.com/GoogleService-Info.plist"

# TestFlight configuration
export IS_TESTFLIGHT="true"
export APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_URL="https://example.com/AuthKey_KEYID.p8"

# Email configuration
export ENABLE_EMAIL_NOTIFICATIONS="true"
export EMAIL_SMTP_SERVER="smtp.gmail.com"
export EMAIL_SMTP_PORT="587"
export EMAIL_SMTP_USER="your-email@gmail.com"
export EMAIL_SMTP_PASS="your-app-password"

# Run the workflow
./scripts/ios-workflow/main_workflow.sh
```

## 📋 Workflow Steps

The main workflow executes the following steps in order:

1. **Environment Setup**
   - Validates essential variables
   - Generates environment configuration
   - Creates output directories

2. **Asset Downloads**
   - Downloads app icons and splash screens
   - Generates iOS app icons in all required sizes
   - Creates asset mapping for Dart code
   - Updates pubspec.yaml with asset paths

3. **Firebase Setup** (if PUSH_NOTIFY=true)
   - Downloads Firebase configuration
   - Updates Podfile with Firebase dependencies
   - Configures AppDelegate for push notifications
   - Updates Info.plist for push notification capabilities

4. **App Configuration**
   - Updates bundle identifier
   - Updates app name in Info.plist
   - Configures app settings

5. **Build Process**
   - Installs Flutter dependencies
   - Installs iOS dependencies (CocoaPods)
   - Creates Xcode archive
   - Exports IPA file

6. **TestFlight Upload** (if IS_TESTFLIGHT=true)
   - Downloads App Store Connect API key
   - Validates API access
   - Uploads IPA to TestFlight
   - Creates upload summary

7. **Final Steps**
   - Creates comprehensive build summary
   - Validates build results
   - Sends email notifications (if enabled)

## 📁 Output Files

After successful execution, the following files will be created:

```
output/ios/
├── Runner.ipa                    # Main IPA file
├── WORKFLOW_SUMMARY.txt         # Complete workflow summary
├── ASSET_SUMMARY.txt            # Asset download summary
├── FIREBASE_SUMMARY.txt         # Firebase setup summary (if applicable)
├── TESTFLIGHT_SUMMARY.txt       # TestFlight upload summary (if applicable)
└── ARTIFACTS_SUMMARY.txt        # Build artifacts summary
```

## 🔍 Troubleshooting

### Common Issues

1. **Missing Essential Variables**
   ```
   ❌ Missing essential variables: BUNDLE_ID APPLE_TEAM_ID
   ```
   **Solution**: Set the required environment variables before running the workflow.

2. **Firebase Configuration Failed**
   ```
   ❌ FIREBASE_CONFIG_IOS not provided
   ```
   **Solution**: Provide the Firebase configuration URL or set PUSH_NOTIFY=false.

3. **TestFlight Upload Failed**
   ```
   ❌ Missing required TestFlight variables
   ```
   **Solution**: Provide all required TestFlight variables or set IS_TESTFLIGHT=false.

4. **Asset Download Failed**
   ```
   ⚠️ Failed to download app icon
   ```
   **Solution**: Check the asset URLs or the workflow will continue with default assets.

### Debug Mode

To enable detailed logging, set the following environment variable:

```bash
export DEBUG_MODE="true"
./scripts/ios-workflow/main_workflow.sh
```

### Individual Script Execution

You can run individual scripts for testing:

```bash
# Test asset downloads only
./scripts/ios-workflow/asset_download.sh

# Test Firebase setup only
./scripts/ios-workflow/firebase_setup.sh

# Test TestFlight upload only
./scripts/ios-workflow/testflight_upload.sh
```

## 🔐 Security Considerations

1. **API Keys**: Store sensitive API keys securely and use environment variables
2. **Email Passwords**: Use app-specific passwords for email notifications
3. **Firebase Config**: Ensure Firebase configuration files are properly secured
4. **TestFlight Keys**: Store App Store Connect API keys securely

## 📊 Monitoring and Logs

The workflow provides comprehensive logging:

- ✅ Success messages in green
- ⚠️ Warning messages in yellow
- ❌ Error messages in red
- 🔍 Info messages in blue

All logs include timestamps and script identification for easy debugging.

## 🔄 Integration with Codemagic

To use this workflow with Codemagic, add the following to your `codemagic.yaml`:

```yaml
workflows:
  ios_workflow:
    name: iOS Workflow
    environment:
      vars:
        WORKFLOW_ID: "ios-workflow"
        APP_NAME: $APP_NAME
        BUNDLE_ID: $BUNDLE_ID
        # ... other variables
    scripts:
      - name: Run iOS Workflow
        script: |
          chmod +x scripts/ios-workflow/main_workflow.sh
          ./scripts/ios-workflow/main_workflow.sh
    artifacts:
      - output/ios/*.ipa
      - output/ios/*.txt
```

## 📞 Support

For issues or questions:

1. Check the troubleshooting section above
2. Review the generated summary files in `output/ios/`
3. Enable debug mode for detailed logging
4. Verify all required environment variables are set

## 🎯 Best Practices

1. **Always validate variables** before running the workflow
2. **Use secure URLs** for asset downloads and API keys
3. **Test individual components** before running the full workflow
4. **Monitor build logs** for any issues
5. **Keep API keys secure** and rotate them regularly
6. **Use version control** for configuration changes
7. **Document customizations** for team members

---

**Last Updated**: $(date)
**Version**: 1.0.0
**Compatibility**: Flutter 3.x+, iOS 12.0+ 