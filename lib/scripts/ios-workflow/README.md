# iOS Workflow - Centralized Scripts

## Overview
This directory contains all iOS-specific workflow scripts that have been centralized for better maintainability and organization. Utility files remain in `lib/scripts/utils/` for shared use across different workflows.

## Structure

### Core Workflow Scripts
- **`main.sh`** - Main entry point for the iOS workflow
- **`pre_build_validation.sh`** - Pre-build validation and environment checks
- **`setup_environment.sh`** - Environment setup and configuration
- **`build_flutter_app.sh`** - Flutter app building process
- **`export_ipa_framework_fix.sh`** - IPA export with modern App Store Connect API
- **`email_notifications.sh`** - Email notification handling

### Build Process Scripts
- **`pre-build.sh`** - Pre-build setup and validation
- **`build.sh`** - Main build orchestration
- **`post-build.sh`** - Post-build validation and cleanup
- **`simplified-build.sh`** - Simplified build process for testing

### Asset and Configuration Scripts
- **`branding_assets.sh`** - Branding assets download and setup
- **`inject_info_plist.sh`** - Info.plist injection and modification
- **`inject_permissions.sh`** - Permission injection for iOS
- **`generate_launcher_icons.sh`** - App icon generation
- **`conditional_firebase_injection.sh`** - Firebase configuration injection

### Fix and Validation Scripts
- **`enhanced_bundle_executable_fix.sh`** - Bundle executable fixes
- **`archive_structure_fix.sh`** - Archive structure fixes
- **`improved_ipa_export.sh`** - Enhanced IPA export process
- **`fix_app_store_connect_issues.sh`** - App Store Connect fixes
- **`bundle-executable-fix.sh`** - Basic bundle executable fixes

### Modern Workflow Scripts
- **`modern-setup.sh`** - Modern App Store Connect API setup
- **`app-store-connect-fix.sh`** - App Store Connect API fixes
- **`testflight-upload.sh`** - TestFlight upload process
- **`app-store-validation.sh`** - App Store validation
- **`validate-workflow.sh`** - Workflow validation

### Firebase Integration
- **`firebase_setup.sh`** - Firebase configuration and setup

## Utility Files (Shared)
Utility files remain in `lib/scripts/utils/` for shared use:
- **`send_email.py`** - Email sending functionality
- **`process_artifacts.sh`** - Artifact processing
- **`download_custom_icons.sh`** - Custom icon downloads
- **`gen_env_config.sh`** - Environment configuration generation
- **`utils.sh`** - Common utility functions

## Usage

### Main Workflow
```bash
# Run the complete iOS workflow
./lib/scripts/ios-workflow/main.sh
```

### Individual Steps
```bash
# Pre-build validation
./lib/scripts/ios-workflow/pre_build_validation.sh

# Build Flutter app
./lib/scripts/ios-workflow/build_flutter_app.sh

# Export IPA
./lib/scripts/ios-workflow/export_ipa_framework_fix.sh
```

## Environment Variables
The workflow uses environment variables from `lib/config/env.sh` and Codemagic environment variables.

## Modern Code Signing
This workflow is configured to use modern App Store Connect API for code signing, eliminating the need for traditional certificates and provisioning profiles.

## Benefits of Centralization
1. **Maintainability** - All iOS scripts in one location
2. **Discoverability** - Easy to find and understand workflow
3. **Consistency** - Standardized approach across workflows
4. **Shared Utilities** - Common utilities remain shared across workflows
5. **Version Control** - Better tracking of iOS-specific changes

## File Permissions
All scripts are automatically made executable during the workflow:
```bash
chmod +x lib/scripts/ios-workflow/*.sh
chmod +x lib/scripts/utils/*.sh
``` 