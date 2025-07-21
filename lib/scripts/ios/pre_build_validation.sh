#!/bin/bash

# 🚀 iOS Pre-Build Validation Script
# Validates all required components and configurations for iOS workflows
# Handles QuikApp Rules Compliance and environment verification

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
elif [ -f "${SCRIPT_DIR}/../utils/utils.sh" ]; then
    source "${SCRIPT_DIR}/../utils/utils.sh"
else
    # Fallback logging functions - always define them
    log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
    log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
    log_warning() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
    log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }
fi

# Ensure logging functions are always available (more robust approach)
log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"; }
log_success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
log_warning() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"; }

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation functions
validate_required_field() {
    local field_name="$1"
    local field_value="$2"
    local description="$3"
    
    if [ -z "${field_value:-}" ]; then
        log_error "$description is required but not set"
        return 1
    else
        log_success "$description: ${field_value}"
        return 0
    fi
}

validate_optional_field() {
    local field_name="$1"
    local field_value="$2"
    local description="$3"
    
    if [ -z "${field_value:-}" ]; then
        log_warning "$description not set (optional)"
        return 0
    else
        log_success "$description: ${field_value}"
        return 0
    fi
}

validate_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        log_success "$description found: $file_path"
        return 0
    else
        log_error "$description not found: $file_path"
        return 1
    fi
}

validate_script_exists() {
    local script_path="$1"
    local description="$2"
    
    if [ -f "$script_path" ]; then
        log_success "$description found: $script_path"
        chmod +x "$script_path" 2>/dev/null || true
        return 0
    else
        log_error "$description not found: $script_path"
        return 1
    fi
}

# Main validation function
main() {
    echo "🚀 Starting iOS Pre-Build Validation..."
    echo "📊 Build Environment:"
    echo "  - Flutter: $(flutter --version | head -1)"
    echo "  - Java: $(java -version 2>&1 | head -1)"
    echo "  - Xcode: $(xcodebuild -version 2>/dev/null | head -1 || echo 'Xcode not available')"
    echo "  - CocoaPods: $(pod --version 2>/dev/null || echo 'CocoaPods not available')"
    echo "  - Memory: $(sysctl -n hw.memsize 2>/dev/null | awk '{print $0/1024/1024/1024 " GB"}' || echo 'Memory info not available')"
    echo "  - Profile Type: ${PROFILE_TYPE:-not set}"

    local validation_errors=0
    PROJECT_ROOT=$(pwd)
    
    echo ""
    echo "🔍 Validating QuikApp Rules Compliance..."

    # App Metadata & Versioning (✅ Required for all workflows)
    echo "📋 Validating required fields..."
    
    validate_required_field "VERSION_NAME" "${VERSION_NAME:-}" "VERSION_NAME" || validation_errors=$((validation_errors + 1))
    validate_required_field "VERSION_CODE" "${VERSION_CODE:-}" "VERSION_CODE" || validation_errors=$((validation_errors + 1))
    validate_required_field "APP_NAME" "${APP_NAME:-}" "APP_NAME" || validation_errors=$((validation_errors + 1))
    validate_required_field "WEB_URL" "${WEB_URL:-}" "WEB_URL" || validation_errors=$((validation_errors + 1))
    validate_required_field "EMAIL_ID" "${EMAIL_ID:-}" "EMAIL_ID" || validation_errors=$((validation_errors + 1))

    # Customization Block (✅ Required for iOS workflows)
    validate_required_field "BUNDLE_ID" "${BUNDLE_ID:-}" "BUNDLE_ID" || validation_errors=$((validation_errors + 1))

    # iOS Signing (✅ Required for iOS workflows)
    validate_required_field "PROFILE_TYPE" "${PROFILE_TYPE:-}" "PROFILE_TYPE" || validation_errors=$((validation_errors + 1))
    validate_required_field "PROFILE_URL" "${PROFILE_URL:-}" "PROFILE_URL" || validation_errors=$((validation_errors + 1))

    # Apple Push & StoreConnect (✅ Required for iOS workflows)
    validate_required_field "APPLE_TEAM_ID" "${APPLE_TEAM_ID:-}" "APPLE_TEAM_ID" || validation_errors=$((validation_errors + 1))
    validate_required_field "APNS_KEY_ID" "${APNS_KEY_ID:-}" "APNS_KEY_ID" || validation_errors=$((validation_errors + 1))
    validate_required_field "APNS_AUTH_KEY_URL" "${APNS_AUTH_KEY_URL:-}" "APNS_AUTH_KEY_URL" || validation_errors=$((validation_errors + 1))
    validate_required_field "APP_STORE_CONNECT_KEY_IDENTIFIER" "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" "APP_STORE_CONNECT_KEY_IDENTIFIER" || validation_errors=$((validation_errors + 1))

    # Certificate validation (one of these combinations required)
    if [ -z "${CERT_P12_URL:-}" ] && [ -z "${CERT_CER_URL:-}" ]; then
        log_error "Either CERT_P12_URL or CERT_CER_URL is required but neither is set"
        validation_errors=$((validation_errors + 1))
    else
        if [ -n "${CERT_P12_URL:-}" ]; then
            log_success "CERT_P12_URL provided"
        else
            log_success "CERT_CER_URL provided"
            if [ -z "${CERT_KEY_URL:-}" ]; then
                log_error "CERT_KEY_URL is required when CERT_P12_URL is not provided"
                validation_errors=$((validation_errors + 1))
            else
                log_success "CERT_KEY_URL provided"
            fi
        fi
    fi

    # Firebase validation based on PUSH_NOTIFY
    echo ""
    echo "🔍 Validating Firebase configuration..."
    if [ "${PUSH_NOTIFY:-false}" = "true" ]; then
        log_info "Push notifications ENABLED - Firebase required"
        if [ -z "$FIREBASE_CONFIG_IOS" ]; then
            log_error "FIREBASE_CONFIG_IOS is required when PUSH_NOTIFY is true"
            validation_errors=$((validation_errors + 1))
        else
            log_success "Firebase configuration provided for push notifications"
        fi
    else
        log_info "Push notifications DISABLED - Firebase optional"
        if [ -n "$FIREBASE_CONFIG_IOS" ]; then
            log_warning "Firebase configuration provided but PUSH_NOTIFY is false"
            log_info "Firebase will be disabled during build"
        fi
    fi

    # Profile type validation
    echo ""
    echo "🔍 Validating profile type: ${PROFILE_TYPE:-not set}"
    case "${PROFILE_TYPE:-}" in
        "app-store"|"ad-hoc")
            log_success "Valid profile type: $PROFILE_TYPE"
            ;;
        "")
            log_error "PROFILE_TYPE is not set"
            validation_errors=$((validation_errors + 1))
            ;;
        *)
            log_error "Invalid profile type: $PROFILE_TYPE"
            log_error "Supported types: app-store, ad-hoc"
            validation_errors=$((validation_errors + 1))
            ;;
    esac

    # Email notification validation (if enabled) - NON-CRITICAL
    if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
        echo ""
        echo "📧 Validating email notification configuration..."
        local email_errors=0
        validate_required_field "EMAIL_SMTP_SERVER" "${EMAIL_SMTP_SERVER:-}" "EMAIL_SMTP_SERVER" || email_errors=$((email_errors + 1))
        validate_required_field "EMAIL_SMTP_PORT" "${EMAIL_SMTP_PORT:-}" "EMAIL_SMTP_PORT" || email_errors=$((email_errors + 1))
        validate_required_field "EMAIL_SMTP_USER" "${EMAIL_SMTP_USER:-}" "EMAIL_SMTP_USER" || email_errors=$((email_errors + 1))
        validate_required_field "EMAIL_SMTP_PASS" "${EMAIL_SMTP_PASS:-}" "EMAIL_SMTP_PASS" || email_errors=$((email_errors + 1))
        
        if [ $email_errors -eq 0 ]; then
            log_success "Email notification configuration validated"
        else
            log_warning "Email notification configuration incomplete (continuing...)"
        fi
    fi

    # Verify required scripts exist
    echo ""
    echo "🔍 Validating build process components..."
    log_info "Project root: $PROJECT_ROOT"

    local script_errors=0
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/main.sh" "Main iOS script" || script_errors=$((script_errors + 1))
    
    # Check utils script in correct location
    if [ -f "$PROJECT_ROOT/lib/scripts/utils/utils.sh" ]; then
        log_success "Utils script found: $PROJECT_ROOT/lib/scripts/utils/utils.sh"
    elif [ -f "$PROJECT_ROOT/lib/scripts/ios/utils.sh" ]; then
        log_success "iOS utils script found: $PROJECT_ROOT/lib/scripts/ios/utils.sh"
    else
        log_error "Utils script not found in expected locations"
        script_errors=$((script_errors + 1))
    fi

    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/validate_profile_type.sh" "Profile validation script" || script_errors=$((script_errors + 1))
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/comprehensive_certificate_validation.sh" "Certificate validation script" || script_errors=$((script_errors + 1))
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/setup_environment.sh" "Environment setup script" || script_errors=$((script_errors + 1))
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/email_notifications.sh" "Email notifications script" || script_errors=$((script_errors + 1))
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/update_bundle_id_rename.sh" "Rename-based bundle ID update script" || script_errors=$((script_errors + 1))
    validate_script_exists "$PROJECT_ROOT/lib/scripts/ios/ultimate_bundle_executable_fix.sh" "Ultimate bundle executable fix script" || script_errors=$((script_errors + 1))

    if [ $script_errors -eq 0 ]; then
        log_success "Build process components validated"
    else
        log_error "Build process components validation failed"
        validation_errors=$((validation_errors + script_errors))
    fi

    # Pre-build bundle executable validation
    echo ""
    echo "🔍 Pre-build bundle executable validation..."
    if [ -f "$PROJECT_ROOT/lib/scripts/ios/ultimate_bundle_executable_fix.sh" ]; then
        chmod +x "$PROJECT_ROOT/lib/scripts/ios/ultimate_bundle_executable_fix.sh"
        
        # Check Xcode project configuration
        if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
            log_info "Checking Xcode project configuration..."
            
            # Check for PRODUCT_NAME setting
            local product_name=""
            if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
                product_name=$(grep -A 1 "PRODUCT_NAME" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
            fi
            
            if [ -n "$product_name" ]; then
                log_success "PRODUCT_NAME found: $product_name"
                # Handle Xcode variables - don't fail on $(TARGET_NAME) or similar
                if echo "$product_name" | grep -q '\$(' || echo "$product_name" | grep -q 'TARGET_NAME'; then
                    log_info "PRODUCT_NAME uses Xcode variable (normal): $product_name"
                elif [ "$product_name" != "Runner" ]; then
                    log_warning "PRODUCT_NAME mismatch: expected Runner, found $product_name"
                    log_info "This might cause bundle executable issues (continuing...)"
                fi
            else
                log_warning "PRODUCT_NAME not found in project file (continuing...)"
            fi
            
            # Check for EXECUTABLE_NAME setting
            local executable_name=""
            if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
                executable_name=$(grep -A 1 "EXECUTABLE_NAME" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"' || echo "")
            fi
            
            if [ -n "$executable_name" ]; then
                log_success "EXECUTABLE_NAME found: $executable_name"
                # Handle Xcode variables - don't fail on $(TARGET_NAME) or similar
                if echo "$executable_name" | grep -q '\$(' || echo "$executable_name" | grep -q 'TARGET_NAME'; then
                    log_info "EXECUTABLE_NAME uses Xcode variable (normal): $executable_name"
                elif [ "$executable_name" != "Runner" ]; then
                    log_warning "EXECUTABLE_NAME mismatch: expected Runner, found $executable_name"
                    log_info "This might cause bundle executable issues (continuing...)"
                fi
            else
                log_warning "EXECUTABLE_NAME not found in project file (continuing...)"
            fi
        else
            log_warning "Xcode project file not found: ios/Runner.xcodeproj/project.pbxproj (continuing...)"
        fi
        
        # Check Info.plist configuration
        if [ -f "ios/Runner/Info.plist" ]; then
            log_info "Checking Info.plist configuration..."
            
            # Check CFBundleExecutable
            local bundle_executable=""
            if [ -f "ios/Runner/Info.plist" ]; then
                bundle_executable=$(plutil -extract CFBundleExecutable xml1 -o - ios/Runner/Info.plist 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1 || echo "")
            fi
            
            if [ -n "$bundle_executable" ]; then
                log_success "CFBundleExecutable found: $bundle_executable"
                if [ "$bundle_executable" != "Runner" ]; then
                    log_warning "CFBundleExecutable mismatch: expected Runner, found $bundle_executable"
                    log_info "This might cause bundle executable issues (continuing...)"
                fi
            else
                log_warning "CFBundleExecutable not found in Info.plist (continuing...)"
            fi
        else
            log_warning "Info.plist not found: ios/Runner/Info.plist (continuing...)"
        fi
    fi

    # Final validation result
    echo ""
    if [ $validation_errors -eq 0 ]; then
        log_success "Pre-build validation completed successfully"
        echo "✅ Environment verification completed"
        exit 0
    else
        log_error "Pre-build validation failed with $validation_errors error(s)"
        echo "❌ Please fix the above errors before proceeding with the build"
        exit 1
    fi
}

# Run main function
main "$@" 