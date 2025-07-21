#!/bin/bash

# 🔍 Environment Configuration Validation Script
# Validates that all required variables are being passed correctly to env_config.dart

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if variable is set and not empty
check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    local required="$2"
    
    if [ -z "$var_value" ]; then
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $var_name is required but not set${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠️ $var_name is optional and not set${NC}"
            return 0
        fi
    else
        echo -e "${GREEN}✅ $var_name is set: ${var_value:0:20}${NC}"
        return 0
    fi
}

# Function to validate workflow-specific variables
validate_workflow_variables() {
    local workflow_id="${WORKFLOW_ID:-unknown}"
    local errors=0
    
    log "🔍 Validating variables for workflow: $workflow_id"
    
    # Common required variables for all workflows
    echo -e "${BLUE}📋 Common Required Variables (All Workflows)${NC}"
    echo "----------------------------------------"
    
    check_var "APP_ID" "true" || ((errors++))
    check_var "USER_NAME" "true" || ((errors++))
    check_var "VERSION_NAME" "true" || ((errors++))
    check_var "VERSION_CODE" "true" || ((errors++))
    check_var "APP_NAME" "true" || ((errors++))
    check_var "ORG_NAME" "true" || ((errors++))
    check_var "WEB_URL" "true" || ((errors++))
    check_var "EMAIL_ID" "true" || ((errors++))
    check_var "SPLASH_URL" "true" || ((errors++))
    check_var "LOGO_URL" "false" || ((errors++))
    
    echo ""
    
    # Android-specific variables
    if [[ "$workflow_id" =~ ^android- ]] || [ "$workflow_id" = "combined" ]; then
        echo -e "${BLUE}📋 Android Variables${NC}"
        echo "----------------------------------------"
        
        check_var "PKG_NAME" "true" || ((errors++))
        
        # Firebase for Android
        if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
            check_var "FIREBASE_CONFIG_ANDROID" "true" || ((errors++))
        else
            check_var "FIREBASE_CONFIG_ANDROID" "false"
        fi
        
        # Keystore for publish workflows
        if [ "$workflow_id" = "android-publish" ] || [ "$workflow_id" = "combined" ]; then
            check_var "KEY_STORE_URL" "true" || ((errors++))
            check_var "CM_KEYSTORE_PASSWORD" "true" || ((errors++))
            check_var "CM_KEY_ALIAS" "true" || ((errors++))
            check_var "CM_KEY_PASSWORD" "true" || ((errors++))
        else
            check_var "KEY_STORE_URL" "false"
            check_var "CM_KEYSTORE_PASSWORD" "false"
            check_var "CM_KEY_ALIAS" "false"
            check_var "CM_KEY_PASSWORD" "false"
        fi
    fi
    
    echo ""
    
    # iOS-specific variables
    if [[ "$workflow_id" =~ ^ios- ]] || [ "$workflow_id" = "combined" ]; then
        echo -e "${BLUE}📋 iOS Variables${NC}"
        echo "----------------------------------------"
        
        check_var "BUNDLE_ID" "true" || ((errors++))
        check_var "PROFILE_TYPE" "true" || ((errors++))
        check_var "CERT_PASSWORD" "true" || ((errors++))
        check_var "PROFILE_URL" "true" || ((errors++))
        check_var "APPLE_TEAM_ID" "true" || ((errors++))
        check_var "APNS_KEY_ID" "true" || ((errors++))
        check_var "APNS_AUTH_KEY_URL" "true" || ((errors++))
        check_var "APP_STORE_CONNECT_KEY_IDENTIFIER" "true" || ((errors++))
        
        # Certificate variables (one combination required)
        if [ -n "${CERT_P12_URL:-}" ]; then
            check_var "CERT_P12_URL" "true" || ((errors++))
        elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
            check_var "CERT_CER_URL" "true" || ((errors++))
            check_var "CERT_KEY_URL" "true" || ((errors++))
        else
            echo -e "${RED}❌ Either CERT_P12_URL or (CERT_CER_URL + CERT_KEY_URL) is required${NC}"
            ((errors++))
        fi
        
        # Firebase for iOS
        if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
            check_var "FIREBASE_CONFIG_IOS" "true" || ((errors++))
        else
            check_var "FIREBASE_CONFIG_IOS" "false"
        fi
        
        # TestFlight variables
        if [ "${IS_TESTFLIGHT:-false}" = "true" ]; then
            check_var "APP_STORE_CONNECT_ISSUER_ID" "true" || ((errors++))
            check_var "APP_STORE_CONNECT_API_KEY_PATH" "true" || ((errors++))
        else
            check_var "APP_STORE_CONNECT_ISSUER_ID" "false"
            check_var "APP_STORE_CONNECT_API_KEY_PATH" "false"
        fi
    fi
    
    echo ""
    
    # Feature flags (optional)
    echo -e "${BLUE}📋 Feature Flags (Optional)${NC}"
    echo "----------------------------------------"
    
    check_var "PUSH_NOTIFY" "false"
    check_var "IS_CHATBOT" "false"
    check_var "IS_DOMAIN_URL" "false"
    check_var "IS_SPLASH" "false"
    check_var "IS_PULLDOWN" "false"
    check_var "IS_BOTTOMMENU" "false"
    check_var "IS_LOAD_IND" "false"
    
    echo ""
    
    # Permissions (optional)
    echo -e "${BLUE}📋 Permissions (Optional)${NC}"
    echo "----------------------------------------"
    
    check_var "IS_CAMERA" "false"
    check_var "IS_LOCATION" "false"
    check_var "IS_MIC" "false"
    check_var "IS_NOTIFICATION" "false"
    check_var "IS_CONTACT" "false"
    check_var "IS_BIOMETRIC" "false"
    check_var "IS_CALENDAR" "false"
    check_var "IS_STORAGE" "false"
    
    echo ""
    
    # UI/Branding variables (optional)
    echo -e "${BLUE}📋 UI/Branding Variables (Optional)${NC}"
    echo "----------------------------------------"
    
    check_var "SPLASH_BG_URL" "false"
    check_var "SPLASH_BG_COLOR" "false"
    check_var "SPLASH_TAGLINE" "false"
    check_var "SPLASH_TAGLINE_COLOR" "false"
    check_var "SPLASH_ANIMATION" "false"
    check_var "SPLASH_DURATION" "false"
    check_var "BOTTOMMENU_ITEMS" "false"
    check_var "BOTTOMMENU_BG_COLOR" "false"
    check_var "BOTTOMMENU_ICON_COLOR" "false"
    check_var "BOTTOMMENU_TEXT_COLOR" "false"
    check_var "BOTTOMMENU_FONT" "false"
    check_var "BOTTOMMENU_FONT_SIZE" "false"
    check_var "BOTTOMMENU_FONT_BOLD" "false"
    check_var "BOTTOMMENU_FONT_ITALIC" "false"
    check_var "BOTTOMMENU_ACTIVE_TAB_COLOR" "false"
    check_var "BOTTOMMENU_ICON_POSITION" "false"
    check_var "BOTTOMMENU_VISIBLE_ON" "false"
    
    echo ""
    
    # Email notification variables (optional)
    echo -e "${BLUE}📋 Email Notification Variables (Optional)${NC}"
    echo "----------------------------------------"
    
    check_var "ENABLE_EMAIL_NOTIFICATIONS" "false"
    check_var "EMAIL_SMTP_SERVER" "false"
    check_var "EMAIL_SMTP_PORT" "false"
    check_var "EMAIL_SMTP_USER" "false"
    check_var "EMAIL_SMTP_PASS" "false"
    
    echo ""
    
    return $errors
}

# Function to validate generated env_config.dart
validate_generated_config() {
    log "🔍 Validating generated env_config.dart file"
    
    if [ ! -f "lib/config/env_config.dart" ]; then
        echo -e "${RED}❌ env_config.dart file not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ env_config.dart file exists${NC}"
    
    # Check if file contains expected content
    local workflow_id="${WORKFLOW_ID:-unknown}"
    
    # Check workflow ID
    if grep -q "workflowId = \"$workflow_id\"" lib/config/env_config.dart; then
        echo -e "${GREEN}✅ Workflow ID correctly set to: $workflow_id${NC}"
    else
        echo -e "${RED}❌ Workflow ID not found or incorrect in env_config.dart${NC}"
        return 1
    fi
    
    # Check platform-specific variables
    if [[ "$workflow_id" =~ ^android- ]] || [ "$workflow_id" = "combined" ]; then
        if grep -q "pkgName = \"${PKG_NAME:-}\"" lib/config/env_config.dart; then
            echo -e "${GREEN}✅ Android package name correctly set${NC}"
        else
            echo -e "${RED}❌ Android package name not found or incorrect${NC}"
            return 1
        fi
    fi
    
    if [[ "$workflow_id" =~ ^ios- ]] || [ "$workflow_id" = "combined" ]; then
        if grep -q "bundleId = \"${BUNDLE_ID:-}\"" lib/config/env_config.dart; then
            echo -e "${GREEN}✅ iOS bundle ID correctly set${NC}"
        else
            echo -e "${RED}❌ iOS bundle ID not found or incorrect${NC}"
            return 1
        fi
    fi
    
    # Check if file is valid Dart
    if command -v dart >/dev/null 2>&1; then
        if dart analyze lib/config/env_config.dart >/dev/null 2>&1; then
            echo -e "${GREEN}✅ env_config.dart passes Dart analysis${NC}"
        else
            echo -e "${RED}❌ env_config.dart has Dart analysis errors${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ Dart not available for analysis${NC}"
    fi
    
    return 0
}

# Function to show environment summary
show_environment_summary() {
    log "📋 Environment Summary"
    echo "----------------------------------------"
    echo "Workflow ID: ${WORKFLOW_ID:-unknown}"
    echo "App Name: ${APP_NAME:-not set}"
    echo "Version: ${VERSION_NAME:-not set} (${VERSION_CODE:-not set})"
    echo "Package Name: ${PKG_NAME:-not set}"
    echo "Bundle ID: ${BUNDLE_ID:-not set}"
    echo "Push Notifications: ${PUSH_NOTIFY:-false}"
    echo "Firebase Android: ${FIREBASE_CONFIG_ANDROID:+enabled}"
    echo "Firebase iOS: ${FIREBASE_CONFIG_IOS:+enabled}"
    echo "Android Keystore: ${KEY_STORE_URL:+enabled}"
    echo "iOS Signing: ${CERT_PASSWORD:+enabled}"
    echo "Profile Type: ${PROFILE_TYPE:-not set}"
    echo "TestFlight: ${IS_TESTFLIGHT:-false}"
    echo "Email Notifications: ${ENABLE_EMAIL_NOTIFICATIONS:-false}"
    echo "----------------------------------------"
}

# Main validation function
main() {
    echo -e "${BLUE}🔍 Environment Configuration Validation${NC}"
    echo "================================================"
    echo ""
    
    # Show environment summary
    show_environment_summary
    echo ""
    
    # Validate workflow-specific variables
    local validation_errors=0
    if ! validate_workflow_variables; then
        validation_errors=$?
    fi
    
    echo ""
    
    # Generate environment config if validation passes
    if [ $validation_errors -eq 0 ]; then
        echo -e "${BLUE}📝 Generating environment configuration...${NC}"
        chmod +x lib/scripts/utils/gen_env_config.sh
        if ./lib/scripts/utils/gen_env_config.sh; then
            echo -e "${GREEN}✅ Environment configuration generated successfully${NC}"
            
            # Validate generated config
            if validate_generated_config; then
                echo -e "${GREEN}✅ All validations passed!${NC}"
                return 0
            else
                echo -e "${RED}❌ Generated config validation failed${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ Environment configuration generation failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Variable validation failed with $validation_errors errors${NC}"
        echo -e "${YELLOW}💡 Please fix the missing required variables before proceeding${NC}"
        return 1
    fi
}

# Run validation
main 