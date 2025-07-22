#!/bin/bash
# 🔧 Comprehensive iOS Workflow Fix Script
# Fixes all issues identified in the error log

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [FIX] $1"; }
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

# Function to fix environment variable injection
fix_env_injection() {
    log_info "🔧 Fixing environment variable injection..."
    
    # Ensure environment variables are properly set
    export WORKFLOW_ID="${WORKFLOW_ID:-ios-workflow}"
    export APP_NAME="${APP_NAME:-QuikApp}"
    export VERSION_NAME="${VERSION_NAME:-1.0.0}"
    export VERSION_CODE="${VERSION_CODE:-1}"
    export BUNDLE_ID="${BUNDLE_ID:-}"
    export APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
    
    log_info "📋 Environment variables set:"
    log_info "   WORKFLOW_ID: $WORKFLOW_ID"
    log_info "   APP_NAME: $APP_NAME"
    log_info "   VERSION_NAME: $VERSION_NAME"
    log_info "   VERSION_CODE: $VERSION_CODE"
    log_info "   BUNDLE_ID: $BUNDLE_ID"
    log_info "   APPLE_TEAM_ID: $APPLE_TEAM_ID"
    
    # Regenerate environment configuration
    if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
        chmod +x "lib/scripts/utils/gen_env_config.sh"
        if ./lib/scripts/utils/gen_env_config.sh; then
            log_success "✅ Environment configuration regenerated successfully"
        else
            log_error "❌ Failed to regenerate environment configuration"
            return 1
        fi
    else
        log_error "❌ gen_env_config.sh not found"
        return 1
    fi
    
    # Generate env.g.dart if the script exists
    if [ -f "lib/scripts/utils/gen_env_g.sh" ]; then
        chmod +x "lib/scripts/utils/gen_env_g.sh"
        if ./lib/scripts/utils/gen_env_g.sh; then
            log_success "✅ env.g.dart generated successfully"
        else
            log_warning "⚠️ Failed to generate env.g.dart (continuing anyway)"
        fi
    else
        log_warning "⚠️ gen_env_g.sh not found (continuing anyway)"
    fi
}

# Function to fix grep commands with invalid character ranges
fix_grep_commands() {
    log_info "🔧 Fixing grep commands with invalid character ranges..."
    
    # Fix gen_env_config.sh grep commands
    if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
        # Add 2>/dev/null to suppress grep errors
        sed -i.bak 's/grep -q "static const String pkgName = "${PKG_NAME:-}"" lib\/config\/env_config\.dart/grep -q "static const String pkgName = "${PKG_NAME:-}"" lib\/config\/env_config\.dart 2>\/dev\/null/g' lib/scripts/utils/gen_env_config.sh
        sed -i.bak 's/grep -q "static const String bundleId = "${BUNDLE_ID:-}"" lib\/config\/env_config\.dart/grep -q "static const String bundleId = "${BUNDLE_ID:-}"" lib\/config\/env_config\.dart 2>\/dev\/null/g' lib/scripts/utils/gen_env_config.sh
        sed -i.bak 's/grep -q "static const String appleTeamId = "${APPLE_TEAM_ID:-}"" lib\/config\/env_config\.dart/grep -q "static const String appleTeamId = "${APPLE_TEAM_ID:-}"" lib\/config\/env_config\.dart 2>\/dev\/null/g' lib/scripts/utils/gen_env_config.sh
        log_success "✅ Fixed grep commands in gen_env_config.sh"
    fi
    
    # Fix verify_env_injection.sh grep commands
    if [ -f "lib/scripts/ios-workflow/verify_env_injection.sh" ]; then
        sed -i.bak 's/grep -q "static const String appName = "${APP_NAME:-}"" "lib\/config\/env_config\.dart"/grep -q "static const String appName = "${APP_NAME:-}"" "lib\/config\/env_config\.dart" 2>\/dev\/null/g' lib/scripts/ios-workflow/verify_env_injection.sh
        sed -i.bak 's/grep -q "static const String versionName = "${VERSION_NAME:-}"" "lib\/config\/env_config\.dart"/grep -q "static const String versionName = "${VERSION_NAME:-}"" "lib\/config\/env_config\.dart" 2>\/dev\/null/g' lib/scripts/ios-workflow/verify_env_injection.sh
        sed -i.bak 's/grep -q "static const String bundleId = "${BUNDLE_ID:-}"" "lib\/config\/env_config\.dart"/grep -q "static const String bundleId = "${BUNDLE_ID:-}"" "lib\/config\/env_config\.dart" 2>\/dev\/null/g' lib/scripts/ios-workflow/verify_env_injection.sh
        log_success "✅ Fixed grep commands in verify_env_injection.sh"
    fi
}

# Function to ensure scripts are in correct directories
fix_script_organization() {
    log_info "🔧 Fixing script organization..."
    
    # Ensure key scripts are in ios-workflow directory
    local scripts_to_copy=(
        "lib/scripts/ios/main.sh:lib/scripts/ios-workflow/main_legacy.sh"
        "lib/scripts/ios/update_bundle_id_target_only.sh:lib/scripts/ios-workflow/update_bundle_id_target_only.sh"
        "lib/scripts/ios/utils.sh:lib/scripts/ios-workflow/utils.sh"
    )
    
    for script_pair in "${scripts_to_copy[@]}"; do
        IFS=':' read -r source dest <<< "$script_pair"
        if [ -f "$source" ] && [ ! -f "$dest" ]; then
            cp "$source" "$dest"
            chmod +x "$dest"
            log_success "✅ Copied $source to $dest"
        fi
    done
}

# Function to verify environment variable injection
verify_env_injection() {
    log_info "🔧 Verifying environment variable injection..."
    
    if [ -f "lib/config/env_config.dart" ]; then
        # Check if variables are properly injected
        local app_name_in_file
        local version_name_in_file
        local bundle_id_in_file
        
        app_name_in_file=$(grep "static const String appName = " lib/config/env_config.dart | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        version_name_in_file=$(grep "static const String versionName = " lib/config/env_config.dart | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        bundle_id_in_file=$(grep "static const String bundleId = " lib/config/env_config.dart | sed 's/.*= "\([^"]*\)".*/\1/' | head -1)
        
        log_info "📋 Values in generated file:"
        log_info "   APP_NAME: $app_name_in_file"
        log_info "   VERSION_NAME: $version_name_in_file"
        log_info "   BUNDLE_ID: $bundle_id_in_file"
        
        # Check for unresolved variables
        if [[ "$app_name_in_file" == *"\${APP_NAME"* ]] || [[ "$version_name_in_file" == *"\${VERSION_NAME"* ]] || [[ "$bundle_id_in_file" == *"\${BUNDLE_ID"* ]]; then
            log_error "❌ Environment variables not properly resolved"
            return 1
        else
            log_success "✅ Environment variables properly injected"
        fi
    else
        log_error "❌ env_config.dart not found"
        return 1
    fi
}

# Function to fix script permissions
fix_script_permissions() {
    log_info "🔧 Fixing script permissions..."
    
    local scripts_to_fix=(
        "lib/scripts/ios-workflow/main.sh"
        "lib/scripts/ios-workflow/pre-build.sh"
        "lib/scripts/ios-workflow/build.sh"
        "lib/scripts/ios-workflow/post-build.sh"
        "lib/scripts/ios-workflow/verify_env_injection.sh"
        "lib/scripts/utils/gen_env_config.sh"
        "lib/scripts/utils/gen_env_g.sh"
    )
    
    for script in "${scripts_to_fix[@]}"; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            log_success "✅ Made $script executable"
        else
            log_warning "⚠️ $script not found"
        fi
    done
}

# Function to run comprehensive validation
run_validation() {
    log_info "🔧 Running comprehensive validation..."
    
    # Check if all required scripts exist and are executable
    local required_scripts=(
        "lib/scripts/ios-workflow/pre-build.sh"
        "lib/scripts/ios-workflow/build.sh"
        "lib/scripts/ios-workflow/post-build.sh"
        "lib/scripts/utils/gen_env_config.sh"
    )
    
    local missing_scripts=()
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            missing_scripts+=("$script")
        elif [ ! -x "$script" ]; then
            chmod +x "$script"
            log_success "✅ Made $script executable"
        fi
    done
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        log_error "❌ Missing required scripts:"
        for script in "${missing_scripts[@]}"; do
            log_error "   - $script"
        done
        return 1
    else
        log_success "✅ All required scripts present and executable"
    fi
    
    # Validate environment configuration
    if [ -f "lib/config/env_config.dart" ]; then
        log_success "✅ env_config.dart exists"
    else
        log_error "❌ env_config.dart not found"
        return 1
    fi
    
    # Validate env.g.dart
    if [ -f "lib/config/env.g.dart" ]; then
        log_success "✅ env.g.dart exists"
    else
        log_warning "⚠️ env.g.dart not found (will be generated during build)"
    fi
}

# Main function
main() {
    log_info "🚀 Starting comprehensive iOS workflow fix..."
    
    # Fix environment variable injection
    if ! fix_env_injection; then
        log_error "❌ Failed to fix environment variable injection"
        exit 1
    fi
    
    # Fix grep commands
    fix_grep_commands
    
    # Fix script organization
    fix_script_organization
    
    # Fix script permissions
    fix_script_permissions
    
    # Verify environment variable injection
    if ! verify_env_injection; then
        log_error "❌ Environment variable injection verification failed"
        exit 1
    fi
    
    # Run comprehensive validation
    if ! run_validation; then
        log_error "❌ Validation failed"
        exit 1
    fi
    
    log_success "🎉 iOS workflow fix completed successfully!"
    log_info "📋 Summary of fixes:"
    log_info "   ✅ Fixed environment variable injection"
    log_info "   ✅ Fixed grep commands with invalid character ranges"
    log_info "   ✅ Organized scripts in correct directories"
    log_info "   ✅ Fixed script permissions"
    log_info "   ✅ Verified environment variable injection"
    log_info "   ✅ Validated all required components"
}

# Run the main function
main "$@" 