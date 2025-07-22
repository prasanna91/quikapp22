#!/bin/bash

# Fix iOS Code Signing Script
# Purpose: Configure code signing with development team for iOS builds

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    echo "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    echo "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    echo "⚠️ Using fallback logging functions"
    
    # Define fallback logging functions
    log_info() { echo "INFO: $*"; }
    log_error() { echo "ERROR: $*"; }
    log_success() { echo "SUCCESS: $*"; }
    log_warn() { echo "WARN: $*"; }
    log_warning() { echo "WARN: $*"; }
fi

# Source environment configuration
if [ -f "${SCRIPT_DIR}/../../config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
elif [ -f "${SCRIPT_DIR}/../../../lib/config/env.sh" ]; then
    source "${SCRIPT_DIR}/../../../lib/config/env.sh"
    log_info "✅ Environment configuration loaded from lib/config/env.sh"
else
    log_warning "⚠️ Environment configuration file not found, using system environment variables"
fi

log_info "🔧 Fixing iOS Code Signing Configuration..."

# Function to validate development team
validate_development_team() {
    local team_id="$1"
    
    if [ -z "$team_id" ]; then
        log_error "❌ Development team ID is empty"
        return 1
    fi
    
    # Check if team ID follows Apple's format (10 characters)
    if [[ "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
        log_success "✅ Development team ID format is valid: $team_id"
        return 0
    else
        log_error "❌ Development team ID format is invalid: $team_id"
        log_error "   Expected format: 10-character alphanumeric string"
        return 1
    fi
}

# Function to fix code signing in project.pbxproj
fix_code_signing_project() {
    log_info "📱 Fixing code signing in project.pbxproj..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local team_id="${APPLE_TEAM_ID}"
    
    if [ ! -f "$project_file" ]; then
        log_error "❌ Project file not found: $project_file"
        return 1
    fi
    
    if ! validate_development_team "$team_id"; then
        return 1
    fi
    
    log_info "👥 Development team ID: $team_id"
    
    # Create a backup
    cp "$project_file" "${project_file}.backup"
    log_info "✅ Created backup: ${project_file}.backup"
    
    # Update DEVELOPMENT_TEAM for Runner target
    # Find the Runner target configuration and update DEVELOPMENT_TEAM
    
    # First, try to update existing DEVELOPMENT_TEAM entries
    local updated_count=0
    
    if sed -i '' "s/DEVELOPMENT_TEAM = .*;/DEVELOPMENT_TEAM = $team_id;/g" "$project_file"; then
        updated_count=$(grep -c "DEVELOPMENT_TEAM = $team_id;" "$project_file" 2>/dev/null || echo "0")
        log_success "✅ Updated existing DEVELOPMENT_TEAM entries"
    fi
    
    # If no entries were found, we need to add them to the Runner target
    if [ "$updated_count" -eq 0 ]; then
        log_info "📝 No existing DEVELOPMENT_TEAM entries found, adding new ones..."
        
        # Find the Runner target configuration and add DEVELOPMENT_TEAM
        # Look for the Runner target build settings section
        # First, try to find the Runner target and add DEVELOPMENT_TEAM to its build settings
        if sed -i '' "/Runner.*buildSettings = {/,/};/ s/};/DEVELOPMENT_TEAM = $team_id;\n};/" "$project_file"; then
            log_success "✅ Added DEVELOPMENT_TEAM to Runner target"
            updated_count=$(grep -c "DEVELOPMENT_TEAM = $team_id;" "$project_file" 2>/dev/null || echo "0")
        else
            # If that didn't work, try a more generic approach
            log_info "📝 Trying alternative approach to add DEVELOPMENT_TEAM..."
            if sed -i '' "/buildSettings = {/,/};/ s/};/DEVELOPMENT_TEAM = $team_id;\n};/" "$project_file"; then
                log_success "✅ Added DEVELOPMENT_TEAM using generic approach"
                updated_count=$(grep -c "DEVELOPMENT_TEAM = $team_id;" "$project_file" 2>/dev/null || echo "0")
            else
                log_error "❌ Failed to add DEVELOPMENT_TEAM to any target"
                return 1
            fi
        fi
    fi
    
    # Ensure updated_count is a valid integer
    updated_count=$(echo "$updated_count" | tr -d ' ')
    if ! [[ "$updated_count" =~ ^[0-9]+$ ]]; then
        updated_count=0
    fi
    
    log_info "📋 Total DEVELOPMENT_TEAM entries: $updated_count"
    
    # Verify the changes
    local verification_count
    verification_count=$(grep -c "DEVELOPMENT_TEAM = $team_id;" "$project_file" 2>/dev/null || echo "0")
    verification_count=$(echo "$verification_count" | tr -d ' ')
    
    if [ "$verification_count" -gt 0 ]; then
        log_success "✅ Code signing successfully configured: $verification_count entries found"
        return 0
    else
        log_error "❌ Code signing configuration failed: no entries found"
        return 1
    fi
}

# Function to configure automatic code signing
configure_automatic_signing() {
    log_info "🔧 Configuring automatic code signing..."
    
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    local team_id="${APPLE_TEAM_ID}"
    
    if [ ! -f "$project_file" ]; then
        log_error "❌ Project file not found: $project_file"
        return 1
    fi
    
    if ! validate_development_team "$team_id"; then
        return 1
    fi
    
    # Set CODE_SIGN_STYLE to Automatic
    if sed -i '' "s/CODE_SIGN_STYLE = .*;/CODE_SIGN_STYLE = Automatic;/g" "$project_file"; then
        log_success "✅ Set CODE_SIGN_STYLE to Automatic"
    else
        log_warn "⚠️ Could not set CODE_SIGN_STYLE to Automatic"
    fi
    
    # Set CODE_SIGN_IDENTITY to Apple Development
    if sed -i '' "s/CODE_SIGN_IDENTITY = .*;/CODE_SIGN_IDENTITY = \"Apple Development\";/g" "$project_file"; then
        log_success "✅ Set CODE_SIGN_IDENTITY to Apple Development"
    else
        log_warn "⚠️ Could not set CODE_SIGN_IDENTITY to Apple Development"
    fi
    
    # Set PROVISIONING_PROFILE_SPECIFIER to empty (automatic)
    if sed -i '' "s/PROVISIONING_PROFILE_SPECIFIER = .*;/PROVISIONING_PROFILE_SPECIFIER = \"\";/g" "$project_file"; then
        log_success "✅ Set PROVISIONING_PROFILE_SPECIFIER to empty (automatic)"
    else
        log_warn "⚠️ Could not set PROVISIONING_PROFILE_SPECIFIER to empty"
    fi
    
    return 0
}

# Function to verify code signing configuration
verify_code_signing() {
    log_info "🔍 Verifying code signing configuration..."
    
    local team_id="${APPLE_TEAM_ID}"
    local project_file="ios/Runner.xcodeproj/project.pbxproj"
    
    log_info "📋 Code signing verification summary:"
    
    # Check DEVELOPMENT_TEAM
    local team_count
    team_count=$(grep -c "DEVELOPMENT_TEAM = $team_id;" "$project_file" 2>/dev/null || echo "0")
    
    if [ "$team_count" -gt 0 ]; then
        log_success "✅ DEVELOPMENT_TEAM found in project.pbxproj: $team_count entries"
    else
        log_error "❌ DEVELOPMENT_TEAM not found in project.pbxproj"
        return 1
    fi
    
    # Check CODE_SIGN_STYLE
    if grep -q "CODE_SIGN_STYLE = Automatic;" "$project_file" 2>/dev/null; then
        log_success "✅ CODE_SIGN_STYLE set to Automatic"
    else
        log_warn "⚠️ CODE_SIGN_STYLE not set to Automatic"
    fi
    
    # Check CODE_SIGN_IDENTITY
    if grep -q "CODE_SIGN_IDENTITY = \"Apple Development\";" "$project_file" 2>/dev/null; then
        log_success "✅ CODE_SIGN_IDENTITY set to Apple Development"
    else
        log_warn "⚠️ CODE_SIGN_IDENTITY not set to Apple Development"
    fi
    
    return 0
}

# Function to create export options for automatic signing
create_export_options() {
    log_info "📝 Creating export options for automatic signing..."
    
    local team_id="${APPLE_TEAM_ID}"
    
    if ! validate_development_team "$team_id"; then
        return 1
    fi
    
    mkdir -p ios
    
    cat > "ios/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$team_id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>iCloudContainerEnvironment</key>
    <string>Production</string>
    <key>onDemandInstallCapable</key>
    <false/>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>distributionBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
</dict>
</plist>
EOF
    
    log_success "✅ Export options created: ios/ExportOptions.plist"
    return 0
}

# Main execution function
main() {
    log_info "🚀 Fixing iOS Code Signing Configuration..."
    
    # Validate environment variables
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        log_error "❌ APPLE_TEAM_ID environment variable is not set"
        return 1
    fi
    
    log_info "👥 Development Team ID: ${APPLE_TEAM_ID}"
    
    # Fix code signing in project.pbxproj
    if ! fix_code_signing_project; then
        log_error "❌ Failed to fix code signing in project.pbxproj"
        return 1
    fi
    
    # Configure automatic code signing
    configure_automatic_signing
    
    # Create export options
    if ! create_export_options; then
        log_error "❌ Failed to create export options"
        return 1
    fi
    
    # Verify the configuration
    if ! verify_code_signing; then
        log_error "❌ Code signing configuration verification failed"
        return 1
    fi
    
    log_success "🎉 iOS code signing configuration fixed successfully"
    log_info "📋 Summary:"
    log_info "   ✅ Updated DEVELOPMENT_TEAM in project.pbxproj"
    log_info "   ✅ Configured automatic code signing"
    log_info "   ✅ Created export options for automatic signing"
    log_info "   ✅ Verified code signing configuration"
    log_info "   👥 Development Team: ${APPLE_TEAM_ID}"
    return 0
}

# Execute main function
main "$@" 