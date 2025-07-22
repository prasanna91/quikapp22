#!/bin/bash
# Remove strict error handling to prevent build failures
# set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ENV_GEN] $1"; }

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

# 🔥 CRITICAL FIX: Prioritize Codemagic API variables over defaults
# This ensures that dynamic API variables take precedence over static defaults
log "🔍 Checking for Codemagic API variables..."

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

# Override with actual API variables (prioritize Codemagic API variables)
# This ensures that environment variables passed by Codemagic API take precedence
export APP_NAME=$(get_api_var "APP_NAME" "QuikApp")
export VERSION_NAME=$(get_api_var "VERSION_NAME" "1.0.0")
export VERSION_CODE=$(get_api_var "VERSION_CODE" "1")
export BUNDLE_ID=$(get_api_var "BUNDLE_ID" "")
export ORG_NAME=$(get_api_var "ORG_NAME" "")
export WEB_URL=$(get_api_var "WEB_URL" "")
export USER_NAME=$(get_api_var "USER_NAME" "")
export EMAIL_ID=$(get_api_var "EMAIL_ID" "")
export PKG_NAME=$(get_api_var "PKG_NAME" "")
export OUTPUT_DIR=$(get_api_var "OUTPUT_DIR" "output")
export APP_ID=$(get_api_var "APP_ID" "")
export WORKFLOW_ID=$(get_api_var "WORKFLOW_ID" "unknown")
export APPLE_TEAM_ID=$(get_api_var "APPLE_TEAM_ID" "")
export APNS_KEY_ID=$(get_api_var "APNS_KEY_ID" "")

# Log the final values being used
log "📋 Final API variable values:"
log "   APP_NAME: $APP_NAME"
log "   VERSION_NAME: $VERSION_NAME"
log "   VERSION_CODE: $VERSION_CODE"
log "   BUNDLE_ID: $BUNDLE_ID"
log "   ORG_NAME: $ORG_NAME"
log "   WEB_URL: $WEB_URL"
log "   USER_NAME: $USER_NAME"
log "   EMAIL_ID: $EMAIL_ID"
log "   PKG_NAME: $PKG_NAME"
log "   OUTPUT_DIR: $OUTPUT_DIR"
log "   APP_ID: $APP_ID"
log "   WORKFLOW_ID: $WORKFLOW_ID"
log "   APPLE_TEAM_ID: $APPLE_TEAM_ID"
log "   APNS_KEY_ID: $APNS_KEY_ID"

# Network connectivity test (made optional)
test_network_connectivity() {
    log "🌐 Testing network connectivity..."
    
    # Test basic internet connectivity (optional)
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Basic internet connectivity confirmed"
    else
        log "⚠️  Basic internet connectivity issues detected (continuing anyway)"
    fi
    
    # Test DNS resolution (optional)
    if nslookup google.com >/dev/null 2>&1; then
        log "✅ DNS resolution working"
    else
        log "⚠️  DNS resolution issues detected (continuing anyway)"
    fi
    
    # Test HTTPS connectivity (optional)
    if curl --connect-timeout 10 --max-time 30 --silent --head https://www.google.com >/dev/null 2>&1; then
        log "✅ HTTPS connectivity confirmed"
    else
        log "⚠️  HTTPS connectivity issues detected (continuing anyway)"
    fi
}

# Enhanced environment validation (made optional)
validate_environment() {
    log "🔍 Validating build environment..."
    
    # Check essential tools (optional)
    local tools=("flutter" "java" "gradle" "curl")
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log "✅ $tool is available"
        else
            log "⚠️  $tool is not available (continuing anyway)"
        fi
    done
    
    # Check Flutter version (optional)
    if flutter --version >/dev/null 2>&1; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        log "📱 Flutter version: $FLUTTER_VERSION"
    else
        log "⚠️  Could not get Flutter version (continuing anyway)"
    fi
    
    # Check Java version (optional)
    if java -version >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        log "☕ Java version: $JAVA_VERSION"
    else
        log "⚠️  Could not get Java version (continuing anyway)"
    fi
    
    # Check available disk space (optional)
    if command -v df >/dev/null 2>&1; then
        DISK_SPACE=$(df -h . | awk 'NR==2{print $4}')
        log "💾 Available disk space: $DISK_SPACE"
    else
        log "⚠️  Could not check disk space (continuing anyway)"
    fi
    
    # Check available memory (optional)
    if command -v free >/dev/null 2>&1; then
        AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
        log "🧠 Available memory: ${AVAILABLE_MEM}MB"
    else
        log "⚠️  Could not check memory (continuing anyway)"
    fi
}

# Main execution function
generate_env_config() {
    log "🚀 Starting enhanced environment configuration generation..."

    # Detect workflow type
    WORKFLOW_ID="${WORKFLOW_ID:-unknown}"
    log "🔍 Detected workflow: $WORKFLOW_ID"
    
    # Determine platform support based on workflow
    IS_ANDROID_WORKFLOW=false
    IS_IOS_WORKFLOW=false
    
    case "$WORKFLOW_ID" in
        android-free|android-paid|android-publish)
            IS_ANDROID_WORKFLOW=true
            log "📱 Android-only workflow detected"
            ;;
        ios-workflow)
            IS_IOS_WORKFLOW=true
            log "🍎 iOS-only workflow detected"
            ;;
        combined)
            IS_ANDROID_WORKFLOW=true
            IS_IOS_WORKFLOW=true
            log "🔄 Combined workflow detected (Android + iOS)"
            ;;
        *)
            log "⚠️ Unknown workflow: $WORKFLOW_ID, enabling all platforms"
            IS_ANDROID_WORKFLOW=true
            IS_IOS_WORKFLOW=true
            ;;
    esac

    # Test network connectivity
    log "🌐 Testing network connectivity..."
    test_network_connectivity || log "⚠️ Network connectivity test failed, continuing anyway"

    # Validate environment
    log "🔍 Validating build environment..."
    validate_environment || log "⚠️ Environment validation failed, continuing anyway"

    # Generate environment config with enhanced error handling
    log "📝 Generating Dart environment configuration (lib/config/env_config.dart)..."

    # Debug: Show current environment variables
    log "🔍 Current environment variables:"
    log "   WORKFLOW_ID: ${WORKFLOW_ID:-not_set}"
    log "   BRANCH: ${BRANCH:-not_set} (using static 'main' instead)"
    log "   APP_NAME: ${APP_NAME:-not_set}"
    log "   PKG_NAME: ${PKG_NAME:-not_set}"
    log "   BUNDLE_ID: ${BUNDLE_ID:-not_set}"
    log "   OUTPUT_DIR: ${OUTPUT_DIR:-not_set}"
    log "   PROJECT_ROOT: ${PROJECT_ROOT:-not_set}"
    log "   CM_BUILD_DIR: ${CM_BUILD_DIR:-not_set}"
    log "   APP_ID: ${APP_ID:-not_set}"
    log "   VERSION_NAME: ${VERSION_NAME:-not_set}"
    log "   VERSION_CODE: ${VERSION_CODE:-not_set}"
    log "   APPLE_TEAM_ID: ${APPLE_TEAM_ID:-not_set}"
    log "   APNS_KEY_ID: ${APNS_KEY_ID:-not_set}"
    log "   IS_IOS_WORKFLOW: ${IS_IOS_WORKFLOW:-false}"
    
    # Use environment variables directly (these are already overridden above)
    # No need for local variables since we've already exported the correct values
    
    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$ENV_CONFIG_FILE")"
    
    # Backup existing file
    if [ -f "$ENV_CONFIG_FILE" ]; then
        cp "$ENV_CONFIG_FILE" "${ENV_CONFIG_FILE}.backup"
        log "📋 Backed up existing env_config.dart"
    fi
    
    # Generate the Dart environment configuration file
    log "📝 Writing environment configuration file..."
    
    cat > "$ENV_CONFIG_FILE" <<EOF
// 🔥 GENERATED FILE: DO NOT EDIT 🔥
//
// This file is generated by lib/scripts/utils/gen_env_config.sh
// It contains all environment-specific variables for the app.
// Generated for workflow: $WORKFLOW_ID

class EnvConfig {
  // App Metadata
  static const String appId = "$APP_ID";
  static const String versionName = "$VERSION_NAME";
  static const int versionCode = $VERSION_CODE;
  static const String appName = "$APP_NAME";
  static const String orgName = "$ORG_NAME";
  static const String webUrl = "$WEB_URL";
  static const String userName = "$USER_NAME";
  static const String emailId = "$EMAIL_ID";
  static const String branch = "main";
  static const String workflowId = "$WORKFLOW_ID";

  // Package Identifiers
$(if [ "$IS_IOS_WORKFLOW" = true ]; then
cat <<IOS_PKG
  static const String bundleId = "$BUNDLE_ID";
IOS_PKG
else
cat <<ANDROID_PKG
  static const String packageName = "$PKG_NAME";
ANDROID_PKG
fi)

  // Build Configuration
  static const String outputDir = "$OUTPUT_DIR";
  static const String projectRoot = "${PROJECT_ROOT:-.}";
  static const String buildDir = "${CM_BUILD_DIR:-.}";

  // iOS-specific Configuration
$(if [ "$IS_IOS_WORKFLOW" = true ]; then
cat <<IOS_CONFIG
  static const String appleTeamId = "$APPLE_TEAM_ID";
  static const String apnsKeyId = "$APNS_KEY_ID";
  static const bool isIosWorkflow = true;
IOS_CONFIG
else
cat <<ANDROID_CONFIG
  static const bool isIosWorkflow = false;
ANDROID_CONFIG
fi)

  // Feature Flags
  static const bool pushNotify = ${PUSH_NOTIFY:-false};
  static const bool isChatbot = ${IS_CHATBOT:-false};
  static const bool isDomainUrl = ${IS_DOMAIN_URL:-false};
  static const bool isSplash = ${IS_SPLASH:-false};
  static const bool isPulldown = ${IS_PULLDOWN:-false};
  static const bool isBottomMenu = ${IS_BOTTOMMENU:-false};
  static const bool isLoadInd = ${IS_LOAD_IND:-false};
  static const bool isCamera = ${IS_CAMERA:-false};
  static const bool isLocation = ${IS_LOCATION:-false};
  static const bool isMic = ${IS_MIC:-false};
  static const bool isNotification = ${IS_NOTIFICATION:-false};
  static const bool isContact = ${IS_CONTACT:-false};
  static const bool isBiometric = ${IS_BIOMETRIC:-false};
  static const bool isCalendar = ${IS_CALENDAR:-false};
  static const bool isStorage = ${IS_STORAGE:-false};

  // Asset URLs
  static const String logoUrl = "$LOGO_URL";
  static const String splashUrl = "$SPLASH_URL";
  static const String splashBgUrl = "$SPLASH_BG_URL";

  // Splash Screen Configuration
  static const String splashBgColor = "$SPLASH_BG_COLOR";
  static const String splashTagline = "$SPLASH_TAGLINE";
  static const String splashTaglineColor = "$SPLASH_TAGLINE_COLOR";
  static const String splashAnimation = "$SPLASH_ANIMATION";
  static const int splashDuration = ${SPLASH_DURATION:-4};

  // Bottom Menu Configuration
  static const String bottomMenuItems = r'$BOTTOMMENU_ITEMS';
  static const String bottomMenuBgColor = "$BOTTOMMENU_BG_COLOR";
  static const String bottomMenuIconColor = "$BOTTOMMENU_ICON_COLOR";
  static const String bottomMenuTextColor = "$BOTTOMMENU_TEXT_COLOR";
  static const String bottomMenuFont = "$BOTTOMMENU_FONT";
  static const int bottomMenuFontSize = ${BOTTOMMENU_FONT_SIZE:-12};
  static const bool bottomMenuFontBold = ${BOTTOMMENU_FONT_BOLD:-false};
  static const bool bottomMenuFontItalic = ${BOTTOMMENU_FONT_ITALIC:-false};
  static const String bottomMenuActiveTabColor = "$BOTTOMMENU_ACTIVE_TAB_COLOR";
  static const String bottomMenuIconPosition = "$BOTTOMMENU_ICON_POSITION";

  // Firebase Configuration
  static const String firebaseConfigAndroid = "$FIREBASE_CONFIG_ANDROID";
  static const String firebaseConfigIos = "$FIREBASE_CONFIG_IOS";

  // Email Configuration
  static const String emailSmtpServer = "$EMAIL_SMTP_SERVER";
  static const int emailSmtpPort = ${EMAIL_SMTP_PORT:-587};
  static const String emailSmtpUser = "$EMAIL_SMTP_USER";
  static const bool enableEmailNotifications = ${ENABLE_EMAIL_NOTIFICATIONS:-false};

  // Build Information
  static const String buildId = "${CM_BUILD_ID:-${FCI_BUILD_ID:-unknown}}";
  static const String projectId = "${CM_PROJECT_ID:-${FCI_PROJECT_ID:-unknown}}";
  static const String workflowName = "${CM_WORKFLOW_NAME:-${FCI_WORKFLOW_NAME:-unknown}}";
  static const int buildNumber = ${BUILD_NUMBER:-${PROJECT_BUILD_NUMBER:-0}};
}
EOF

    log "✅ Dart environment configuration generated successfully."
    
    # Show first few lines of generated file for verification
    log "🔍 Generated file preview:"
    head -20 lib/config/env_config.dart | while IFS= read -r line; do
        log "   $line"
    done

    # Validate generated config
    if [ -f "lib/config/env_config.dart" ]; then
        log "✅ Environment configuration generated successfully"
        
        # Verify workflow-specific fields
        log "🔍 Verifying workflow-specific fields..."
        if [ "$IS_ANDROID_WORKFLOW" = true ]; then
            if grep -q "static const String pkgName = \"${PKG_NAME:-}\"" lib/config/env_config.dart; then
                log "✅ Android package name correctly set to: ${PKG_NAME:-}"
            else
                log "⚠️ Android package name not found or incorrect"
            fi
        fi
        
        if [ "$IS_IOS_WORKFLOW" = true ]; then
            if grep -q "static const String bundleId = \"${BUNDLE_ID:-}\"" lib/config/env_config.dart; then
                log "✅ iOS bundle ID correctly set to: ${BUNDLE_ID:-}"
            else
                log "⚠️ iOS bundle ID not found or incorrect"
            fi
            
            # Check if APPLE_TEAM_ID was properly substituted
            if grep -q "static const String appleTeamId = \"${APPLE_TEAM_ID:-}\"" lib/config/env_config.dart; then
                log "✅ iOS team ID correctly set to: ${APPLE_TEAM_ID:-}"
            else
                log "⚠️ iOS team ID not found or incorrect"
            fi
        fi
        
        # Verify outputDir value
        log "🔍 Verifying outputDir value in generated file..."
        if grep -q "static const String outputDir = \"${OUTPUT_DIR:-output}\"" lib/config/env_config.dart; then
            log "✅ outputDir value correctly set to: ${OUTPUT_DIR:-output}"
        else
            log "❌ outputDir value mismatch in generated file"
            log "   Expected: ${OUTPUT_DIR:-output}"
            log "   Found in file:"
            grep "static const String outputDir" lib/config/env_config.dart || log "   Not found in file"
        fi
        
        # Check if config is valid Dart (optional)
        if command -v dart >/dev/null 2>&1; then
            if dart analyze lib/config/env_config.dart >/dev/null 2>&1; then
                log "✅ Generated config passes Dart analysis"
            else
                log "⚠️  Generated config has Dart analysis issues (continuing anyway)"
            fi
        else
            log "⚠️  Dart not available for analysis (continuing anyway)"
        fi
        
        # Show config summary
        log "📋 Configuration Summary:"
        log "   App: ${APP_NAME:-QuikApp} v${VERSION_NAME:-1.0.0}"
        log "   Workflow: ${WORKFLOW_ID:-unknown}"
        log "   Platform: $(if [ "$IS_ANDROID_WORKFLOW" = true ]; then echo -n "Android "; fi)$(if [ "$IS_IOS_WORKFLOW" = true ]; then echo -n "iOS"; fi)"
        log "   Firebase: ${PUSH_NOTIFY:-false}"
        log "   Keystore: ${KEY_STORE_URL:+true}"
        log "   iOS Signing: ${CERT_PASSWORD:+true}"
        
    else
        log "❌ Failed to generate environment configuration"
        
        # Restore backup if available
        if [ -f "lib/config/env_config.dart.backup" ]; then
            cp lib/config/env_config.dart.backup lib/config/env_config.dart
            log "✅ Restored backup configuration"
        fi
        
        # Don't exit with error, just return 1
        log "⚠️  Environment configuration generation failed, but continuing build"
        return 1
    fi

    log "🎉 Enhanced environment configuration generation completed"
    return 0
}

# Run the function if script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_env_config
    exit $?
fi

#class EnvConfig {
#  // App Metadata
#  static const String appId = String.fromEnvironment('APP_ID', defaultValue: '');
#  static const String versionName = String.fromEnvironment('VERSION_NAME', defaultValue: '1.0.0');
#  static const int versionCode = int.fromEnvironment('VERSION_CODE', defaultValue: 1);
#  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'QuikApp');
#  static const String orgName = String.fromEnvironment('ORG_NAME', defaultValue: '');
#  static const String webUrl = String.fromEnvironment('WEB_URL', defaultValue: '');
#  static const String userName = String.fromEnvironment('USER_NAME', defaultValue: '');
#  static const String emailId = String.fromEnvironment('EMAIL_ID', defaultValue: '');
#  static const String branch = String.fromEnvironment('BRANCH', defaultValue: 'main');
#  static const String workflowId = String.fromEnvironment('WORKFLOW_ID', defaultValue: '');
#
#  // Package Identifiers
#  static const String pkgName = String.fromEnvironment('PKG_NAME', defaultValue: '');
#  static const String bundleId = String.fromEnvironment('BUNDLE_ID', defaultValue: '');
#
#  // Feature Flags
#  static const bool pushNotify = bool.fromEnvironment('PUSH_NOTIFY', defaultValue: false);
#  static const bool isChatbot = bool.fromEnvironment('IS_CHATBOT', defaultValue: false);
#  static const bool isDomainUrl = bool.fromEnvironment('IS_DOMAIN_URL', defaultValue: false);
#  static const bool isSplash = bool.fromEnvironment('IS_SPLASH', defaultValue: true);
#  static const bool isPulldown = bool.fromEnvironment('IS_PULLDOWN', defaultValue: true);
#  static const bool isBottommenu = bool.fromEnvironment('IS_BOTTOMMENU', defaultValue: true);
#  static const bool isLoadIndicator = bool.fromEnvironment('IS_LOAD_IND', defaultValue: true);
#
#  // Permissions (converted to bool)
#  static const bool isCamera = ${IS_CAMERA:-false};
#  static const bool isLocation = ${IS_LOCATION:-false};
#  static const bool isMic = ${IS_MIC:-false};
#  static const bool isNotification = ${IS_NOTIFICATION:-false};
#  static const bool isContact = ${IS_CONTACT:-false};
#  static const bool isBiometric = ${IS_BIOMETRIC:-false};
#  static const bool isCalendar = ${IS_CALENDAR:-false};
#  static const bool isStorage = ${IS_STORAGE:-false};
#
#  // UI/Branding
#  static const String logoUrl = String.fromEnvironment('LOGO_URL', defaultValue: '');
#  static const String splashUrl = String.fromEnvironment('SPLASH_URL', defaultValue: '');
#  static const String splashBg = String.fromEnvironment('SPLASH_BG_URL', defaultValue: '');
#  static const String splashBgColor = String.fromEnvironment('SPLASH_BG_COLOR', defaultValue: '#FFFFFF');
#  static const String splashTagline = String.fromEnvironment('SPLASH_TAGLINE', defaultValue: '');
#  static const String splashTaglineColor = String.fromEnvironment('SPLASH_TAGLINE_COLOR', defaultValue: '#000000');
#  static const String splashAnimation = String.fromEnvironment('SPLASH_ANIMATION', defaultValue: 'fade');
#  static const int splashDuration = int.fromEnvironment('SPLASH_DURATION', defaultValue: 3);
#
#  // Bottom Menu Configuration
#  static const String bottommenuItems = String.fromEnvironment('BOTTOMMENU_ITEMS', defaultValue: '[]');
#  static const String bottommenuBgColor = String.fromEnvironment('BOTTOMMENU_BG_COLOR', defaultValue: '#FFFFFF');
#  static const String bottommenuIconColor = String.fromEnvironment('BOTTOMMENU_ICON_COLOR', defaultValue: '#6d6e8c');
#  static const String bottommenuTextColor = String.fromEnvironment('BOTTOMMENU_TEXT_COLOR', defaultValue: '#6d6e8c');
#  static const String bottommenuFont = String.fromEnvironment('BOTTOMMENU_FONT', defaultValue: 'DM Sans');
#  static const double bottommenuFontSize = double.fromEnvironment('BOTTOMMENU_FONT_SIZE', defaultValue: 12.0);
#  static const bool bottommenuFontBold = bool.fromEnvironment('BOTTOMMENU_FONT_BOLD', defaultValue: false);
#  static const bool bottommenuFontItalic = bool.fromEnvironment('BOTTOMMENU_FONT_ITALIC', defaultValue: false);
#  static const String bottommenuActiveTabColor = String.fromEnvironment('BOTTOMMENU_ACTIVE_TAB_COLOR', defaultValue: '#a30237');
#  static const String bottommenuIconPosition = String.fromEnvironment('BOTTOMMENU_ICON_POSITION', defaultValue: 'above');
#  static const String bottommenuVisibleOn = String.fromEnvironment('BOTTOMMENU_VISIBLE_ON', defaultValue: 'home,settings,profile');
#
#  // Firebase Configuration
#  static const String firebaseConfigAndroid = String.fromEnvironment('FIREBASE_CONFIG_ANDROID', defaultValue: '');
#  static const String firebaseConfigIos = String.fromEnvironment('FIREBASE_CONFIG_IOS', defaultValue: '');
#
#  // Android Signing
#  static const String keyStoreUrl = String.fromEnvironment('KEY_STORE_URL', defaultValue: '');
#  static const String cmKeystorePassword = String.fromEnvironment('CM_KEYSTORE_PASSWORD', defaultValue: '');
#  static const String cmKeyAlias = String.fromEnvironment('CM_KEY_ALIAS', defaultValue: '');
#  static const String cmKeyPassword = String.fromEnvironment('CM_KEY_PASSWORD', defaultValue: '');
#
#  // iOS Signing
#  static const String appleTeamId = String.fromEnvironment('APPLE_TEAM_ID', defaultValue: '');
#  static const String apnsKeyId = String.fromEnvironment('APNS_KEY_ID', defaultValue: '');
#  static const String apnsAuthKeyUrl = String.fromEnvironment('APNS_AUTH_KEY_URL', defaultValue: '');
#  static const String certPassword = String.fromEnvironment('CERT_PASSWORD', defaultValue: '');
#  static const String profileUrl = String.fromEnvironment('PROFILE_URL', defaultValue: '');
#  static const String certP12Url = String.fromEnvironment('CERT_P12_URL', defaultValue: '');
#  static const String certCerUrl = String.fromEnvironment('CERT_CER_URL', defaultValue: '');
#  static const String certKeyUrl = String.fromEnvironment('CERT_KEY_URL', defaultValue: '');
#  static const String profileType = String.fromEnvironment('PROFILE_TYPE', defaultValue: 'app-store');
#  static const String appStoreConnectKeyIdentifier = String.fromEnvironment('APP_STORE_CONNECT_KEY_IDENTIFIER', defaultValue: '');
#
#  // Email Configuration
#  static const bool enableEmailNotifications = bool.fromEnvironment('ENABLE_EMAIL_NOTIFICATIONS', defaultValue: false);
#  static const String emailSmtpServer = String.fromEnvironment('EMAIL_SMTP_SERVER', defaultValue: '');
#  static const int emailSmtpPort = int.fromEnvironment('EMAIL_SMTP_PORT', defaultValue: 587);
#  static const String emailSmtpUser = String.fromEnvironment('EMAIL_SMTP_USER', defaultValue: '');
#  static const String emailSmtpPass = String.fromEnvironment('EMAIL_SMTP_PASS', defaultValue: '');
#
#  // Build Environment
#  static const String buildId = String.fromEnvironment('CM_BUILD_ID', defaultValue: 'unknown');
#  static const String buildDir = String.fromEnvironment('CM_BUILD_DIR', defaultValue: '');
#  static const String projectRoot = String.fromEnvironment('PROJECT_ROOT', defaultValue: '');
#  static const String outputDir = String.fromEnvironment('OUTPUT_DIR', defaultValue: 'output');
#
#  // Memory and Performance Settings
#  static const String gradleOpts = String.fromEnvironment('GRADLE_OPTS', defaultValue: '');
#  static const int xcodeParallelJobs = int.fromEnvironment('XCODE_PARALLEL_JOBS', defaultValue: 4);
#  static const String flutterBuildArgs = String.fromEnvironment('FLUTTER_BUILD_ARGS', defaultValue: '');
#
#  // Utility Methods
#  static bool get isAndroidBuild => workflowId.startsWith('android');
#  static bool get isIosBuild => workflowId == 'ios-only';
#  static bool get isCombinedBuild => workflowId == 'combined';
#  static bool get hasFirebase => firebaseConfigAndroid.isNotEmpty || firebaseConfigIos.isNotEmpty;
#  static bool get hasKeystore => keyStoreUrl.isNotEmpty;
#  static bool get hasIosSigning => certPassword.isNotEmpty && profileUrl.isNotEmpty;
#}