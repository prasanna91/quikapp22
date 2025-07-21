#!/bin/bash

# Enhanced Certificate Setup for IPA Export with P12 Generation
# Purpose: Configure iOS Distribution certificate for successful IPA export
# Features: Auto-generate P12 from CER/KEY files if P12 URL not available
# Fixes: "No signing certificate iOS Distribution found" error

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/utils.sh"

log_info "🔐 Enhanced Certificate Setup for IPA Export (v2.0)"
log_info "🎯 Purpose: Fix 'No signing certificate iOS Distribution found' error"
log_info "✨ Features: Auto P12 generation from CER/KEY files"

# Function to validate URL format
is_valid_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        return 1
    fi
}

# Function to generate P12 from CER and KEY files
generate_p12_from_cer_key() {
    log_info "🔧 Generating P12 certificate from CER and KEY files..."
    
    local cer_url="${CERT_CER_URL:-}"
    local key_url="${CERT_KEY_URL:-}"
    local cert_password="${CERT_PASSWORD:-Password@1234}"
    
    # Validate CER and KEY URLs
    if [[ -z "$cer_url" || -z "$key_url" ]]; then
        log_error "❌ CERT_CER_URL or CERT_KEY_URL not set"
        log_info "Required for P12 generation:"
        log_info "   CERT_CER_URL: ${cer_url:-NOT_SET}"
        log_info "   CERT_KEY_URL: ${key_url:-NOT_SET}"
        return 1
    fi
    
    if ! is_valid_url "$cer_url" || ! is_valid_url "$key_url"; then
        log_error "❌ Invalid CER or KEY URL format"
        log_info "   CERT_CER_URL: $cer_url"
        log_info "   CERT_KEY_URL: $key_url"
        return 1
    fi
    
    log_info "📋 P12 Generation Configuration:"
    log_info "   CER URL: $cer_url"
    log_info "   KEY URL: $key_url"
    log_info "   Password: ${cert_password:+SET (${#cert_password} chars)}"
    log_info "   Password Source: ${CERT_PASSWORD:+Environment Variable}${CERT_PASSWORD:-Default Password@1234}"
    
    # Create temporary directory for certificate files
    local temp_dir="/tmp/cert_generation_$$"
    mkdir -p "$temp_dir"
    
    local cer_file="$temp_dir/certificate.cer"
    local key_file="$temp_dir/private_key.key"
    local p12_file="$temp_dir/generated_certificate.p12"
    
    # Download CER file
    log_info "📥 Downloading CER certificate..."
    if curl -fsSL -o "$cer_file" "$cer_url"; then
        log_success "✅ CER file downloaded: $(ls -lh "$cer_file" | awk '{print $5}')"
    else
        log_error "❌ Failed to download CER file from: $cer_url"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Download KEY file
    log_info "📥 Downloading private KEY file..."
    if curl -fsSL -o "$key_file" "$key_url"; then
        log_success "✅ KEY file downloaded: $(ls -lh "$key_file" | awk '{print $5}')"
    else
        log_error "❌ Failed to download KEY file from: $key_url"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Validate downloaded files
    if ! openssl x509 -in "$cer_file" -text -noout >/dev/null 2>&1; then
        log_error "❌ Invalid CER file format"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if ! openssl rsa -in "$key_file" -check -noout >/dev/null 2>&1; then
        log_error "❌ Invalid KEY file format"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_success "✅ CER and KEY files validated successfully"
    
    # Extract certificate information
    log_info "📋 Certificate Information:"
    local cert_subject=$(openssl x509 -in "$cer_file" -subject -noout | sed 's/subject=//' || echo "Unknown")
    local cert_issuer=$(openssl x509 -in "$cer_file" -issuer -noout | sed 's/issuer=//' || echo "Unknown")
    local cert_dates=$(openssl x509 -in "$cer_file" -dates -noout || echo "Unknown")
    
    log_info "   Subject: $cert_subject"
    log_info "   Issuer: $cert_issuer"
    log_info "   $cert_dates"
    
    # Generate P12 file
    log_info "🔧 Generating P12 certificate file..."
    if openssl pkcs12 -export \
        -out "$p12_file" \
        -inkey "$key_file" \
        -in "$cer_file" \
        -password "pass:$cert_password" \
        -name "iOS Distribution Certificate (Generated)" 2>/dev/null; then
        
        local p12_size=$(ls -lh "$p12_file" | awk '{print $5}')
        log_success "✅ P12 certificate generated successfully: $p12_size"
        
        # Verify P12 file
        if openssl pkcs12 -in "$p12_file" -info -noout -password "pass:$cert_password" >/dev/null 2>&1; then
            log_success "✅ Generated P12 file validated"
            
            # Set the generated P12 file as CERT_P12_URL for subsequent processing
            export CERT_P12_FILE="$p12_file"
            export CERT_PASSWORD="$cert_password"
            export GENERATED_P12="true"
            
            log_info "🎯 P12 Generation Complete:"
            log_info "   Generated File: $p12_file"
            log_info "   Password: $cert_password"
            log_info "   Ready for installation"
            
            return 0
        else
            log_error "❌ Generated P12 file validation failed"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_error "❌ Failed to generate P12 certificate"
        log_info "Common causes:"
        log_info "  1. CER and KEY files don't match"
        log_info "  2. KEY file is encrypted (not supported)"
        log_info "  3. Invalid certificate format"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to validate current certificate setup
validate_certificate_setup() {
    log_info "🔍 Validating current certificate setup..."
    
    local missing_items=0
    local cert_method=""
    
    # Check App Store Connect API key
    if [[ -n "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" && -n "${APP_STORE_CONNECT_ISSUER_ID:-}" && -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
        log_success "✅ App Store Connect API key: Available"
        log_info "   Key ID: ${APP_STORE_CONNECT_KEY_IDENTIFIER}"
        log_info "   Issuer ID: ${APP_STORE_CONNECT_ISSUER_ID}"
        log_info "   API Key URL: ${APP_STORE_CONNECT_API_KEY_PATH}"
    else
        log_warn "⚠️ App Store Connect API key: Incomplete"
        ((missing_items++))
    fi
    
    # Check certificate method preference
    if [[ -n "${CERT_P12_URL:-}" ]] && is_valid_url "${CERT_P12_URL}"; then
        log_success "✅ iOS Distribution Certificate (P12): ${CERT_P12_URL}"
        cert_method="P12_URL"
    elif [[ -n "${CERT_CER_URL:-}" && -n "${CERT_KEY_URL:-}" ]]; then
        if is_valid_url "${CERT_CER_URL}" && is_valid_url "${CERT_KEY_URL}"; then
            log_success "✅ iOS Distribution Certificate (CER+KEY): Available"
            log_info "   CER URL: ${CERT_CER_URL}"
            log_info "   KEY URL: ${CERT_KEY_URL}"
            cert_method="CER_KEY"
        else
            log_error "❌ Invalid CER or KEY URL format"
            ((missing_items++))
        fi
    else
        log_error "❌ No valid certificate method found"
        log_info "   Option 1: Set CERT_P12_URL to P12 file URL"
        log_info "   Option 2: Set CERT_CER_URL and CERT_KEY_URL"
        log_info "   Current Status:"
        log_info "     CERT_P12_URL: ${CERT_P12_URL:-NOT_SET}"
        log_info "     CERT_CER_URL: ${CERT_CER_URL:-NOT_SET}"
        log_info "     CERT_KEY_URL: ${CERT_KEY_URL:-NOT_SET}"
        ((missing_items++))
    fi
    
    # Check Certificate Password
    if [[ -n "${CERT_PASSWORD:-}" ]]; then
        log_success "✅ Certificate Password: SET (${#CERT_PASSWORD} characters)"
    else
        log_info "ℹ️ Certificate Password: Using default 'Password@1234'"
        log_info "   Set CERT_PASSWORD environment variable for custom password"
    fi
    
    # Check Provisioning Profile
    if [[ -n "${PROFILE_URL:-}" ]]; then
        log_success "✅ Provisioning Profile URL: ${PROFILE_URL}"
    else
        log_warn "⚠️ Provisioning Profile URL: NOT_SET"
        ((missing_items++))
    fi
    
    # Check Team ID
    if [[ -n "${APPLE_TEAM_ID:-}" ]]; then
        log_success "✅ Apple Team ID: ${APPLE_TEAM_ID}"
    else
        log_warn "⚠️ Apple Team ID: NOT_SET"
        ((missing_items++))
    fi
    
    log_info "📊 Certificate Setup Status:"
    log_info "   Method: $cert_method"
    log_info "   Missing items: $missing_items"
    log_info "   Password source: ${CERT_PASSWORD:+Environment}${CERT_PASSWORD:-Default}"
    
    return $missing_items
}

# Function to setup automatic certificate configuration
setup_automatic_certificate_config() {
    log_info "🔧 Setting up automatic certificate configuration..."
    
    # Check if we need to generate P12 from CER/KEY
    if [[ -z "${CERT_P12_URL:-}" ]] || ! is_valid_url "${CERT_P12_URL:-}"; then
        log_info "📋 P12 URL not available, checking CER/KEY method..."
        
        if [[ -n "${CERT_CER_URL:-}" && -n "${CERT_KEY_URL:-}" ]]; then
            log_info "🔄 CER/KEY URLs found, generating P12..."
            if generate_p12_from_cer_key; then
                log_success "✅ P12 certificate generated from CER/KEY files"
                return 0
            else
                log_error "❌ Failed to generate P12 from CER/KEY files"
                return 1
            fi
        else
            log_warn "⚠️ Neither P12 URL nor CER/KEY URLs available"
            return 1
        fi
    else
        log_success "✅ P12 URL is configured: ${CERT_P12_URL}"
        return 0
    fi
}

# Function to create a keychain and install certificates
setup_keychain_and_certificates() {
    log_info "🔑 Setting up keychain and installing certificates..."
    
    local keychain_name="ios-build"
    local keychain_password="build123"
    local keychain_path="$HOME/Library/Keychains/${keychain_name}.keychain-db"
    
    # Create keychain if it doesn't exist
    if [[ ! -f "$keychain_path" ]]; then
        log_info "Creating new keychain: $keychain_name"
        security create-keychain -p "$keychain_password" "$keychain_name"
        security set-keychain-settings -t 3600 -u "$keychain_name"
        security unlock-keychain -p "$keychain_password" "$keychain_name"
        log_success "✅ Keychain created: $keychain_path"
    else
        log_info "Using existing keychain: $keychain_path"
        security unlock-keychain -p "$keychain_password" "$keychain_name"
    fi
    
    # Add to search list
    security list-keychains -s "$keychain_name" login.keychain
    
    # Install certificate based on available method
    local cert_installed=false
    
    # Method 1: Use generated P12 file
    if [[ -n "${CERT_P12_FILE:-}" && -f "${CERT_P12_FILE}" ]]; then
        log_info "📥 Installing generated P12 certificate..."
        
        if security import "${CERT_P12_FILE}" -k "$keychain_name" -P "${CERT_PASSWORD:-Password@1234}" -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null; then
            log_success "✅ Generated P12 certificate installed successfully"
            cert_installed=true
        else
            log_error "❌ Failed to install generated P12 certificate"
        fi
    fi
    
    # Method 2: Download and install P12 from URL
    if [[ "$cert_installed" = "false" && -n "${CERT_P12_URL:-}" ]] && is_valid_url "${CERT_P12_URL}"; then
        log_info "📥 Downloading P12 certificate from URL..."
        local cert_file="/tmp/ios_distribution_cert.p12"
        
        if curl -fsSL -o "$cert_file" "${CERT_P12_URL}"; then
            log_success "✅ P12 certificate downloaded: $(ls -lh "$cert_file" | awk '{print $5}')"
            
            # Install certificate
            log_info "🔧 Installing P12 certificate in keychain..."
            if security import "$cert_file" -k "$keychain_name" -P "${CERT_PASSWORD:-Password@1234}" -T /usr/bin/codesign -T /usr/bin/security 2>/dev/null; then
                log_success "✅ P12 certificate installed successfully"
                cert_installed=true
            else
                log_error "❌ Failed to install P12 certificate"
                log_info "Please check certificate password: ${CERT_PASSWORD:+SET}${CERT_PASSWORD:-Using default}"
            fi
            
            rm -f "$cert_file"
        else
            log_error "❌ Failed to download P12 certificate from: ${CERT_P12_URL}"
        fi
    fi
    
    if [[ "$cert_installed" = "true" ]]; then
        # Set key partition list for codesign access
        security set-key-partition-list -S apple-tool:,apple: -s -k "$keychain_password" "$keychain_name" 2>/dev/null || true
        
        # Verify certificate installation
        if security find-identity -v -p codesigning "$keychain_name" | grep -q "iOS Distribution"; then
            log_success "✅ iOS Distribution certificate verified in keychain"
            
            # Extract certificate details for code signing
            log_info "📋 Extracting certificate details for code signing..."
            local cert_info=$(security find-identity -v -p codesigning "$keychain_name" | grep "iOS Distribution" | head -1)
            local cert_hash=$(echo "$cert_info" | awk '{print $2}')
            local cert_name=$(echo "$cert_info" | sed 's/.*") //' | sed 's/"$//')
            
            if [[ -n "$cert_hash" && -n "$cert_name" ]]; then
                export CODE_SIGN_IDENTITY="$cert_name"
                export CODE_SIGN_IDENTITY_HASH="$cert_hash"
                
                log_success "✅ Code signing variables extracted:"
                log_info "   Identity: $cert_name"
                log_info "   Hash: $cert_hash"
            fi
            
            return 0
        else
            log_warn "⚠️ Certificate installed but not found in identity list"
        fi
    fi
    
    return 1
}

# Function to download and install provisioning profile
setup_provisioning_profile() {
    log_info "📱 Setting up provisioning profile..."
    
    if [[ -z "${PROFILE_URL:-}" ]]; then
        log_warn "⚠️ PROFILE_URL not set, skipping provisioning profile setup"
        return 1
    fi
    
    local profile_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    mkdir -p "$profile_dir"
    
    local profile_file="/tmp/app_store_profile.mobileprovision"
    
    log_info "📥 Downloading provisioning profile..."
    if curl -fsSL -o "$profile_file" "${PROFILE_URL}"; then
        log_success "✅ Provisioning profile downloaded: $(ls -lh "$profile_file" | awk '{print $5}')"
        
        # Install provisioning profile
        cp "$profile_file" "$profile_dir/"
        log_success "✅ Provisioning profile installed: $profile_dir/"
        
        # Extract provisioning profile information
        if command -v security >/dev/null 2>&1; then
            log_info "📋 Provisioning profile information:"
            local profile_info=$(security cms -D -i "$profile_file" 2>/dev/null | plutil -p - 2>/dev/null || echo "Could not parse profile")
            
            # Extract key information
            local profile_name=$(echo "$profile_info" | grep '"Name"' | sed 's/.*"Name" => "//' | sed 's/".*//' || echo "Unknown")
            local team_name=$(echo "$profile_info" | grep '"TeamName"' | sed 's/.*"TeamName" => "//' | sed 's/".*//' || echo "Unknown")
            local bundle_id=$(echo "$profile_info" | grep '"application-identifier"' | head -1 | sed 's/.*"//' | sed 's/".*//' | sed 's/.*\.//' || echo "Unknown")
            
            log_info "   Profile Name: $profile_name"
            log_info "   Team Name: $team_name"
            log_info "   Bundle ID Pattern: $bundle_id"
            
            # Export for use in build process
            export PROVISIONING_PROFILE_NAME="$profile_name"
            export PROVISIONING_PROFILE_UUID=$(echo "$profile_info" | grep '"UUID"' | sed 's/.*"UUID" => "//' | sed 's/".*//' || echo "Unknown")
        fi
        
        rm -f "$profile_file"
        return 0
    else
        log_error "❌ Failed to download provisioning profile from: ${PROFILE_URL}"
        return 1
    fi
}

# Function to create enhanced export options
create_enhanced_export_options() {
    log_info "📝 Creating enhanced export options for collision-free IPA export..."
    
    local export_options_path="ios/ExportOptions.plist"
    local method="${PROFILE_TYPE:-app-store}"
    
    # Convert profile type to export method
    case "$method" in
        "app-store") method="app-store" ;;
        "ad-hoc") method="ad-hoc" ;;
        "enterprise") method="enterprise" ;;
        "development") method="development" ;;
        *) method="app-store" ;;
    esac
    
    log_info "🎯 Export Configuration:"
    log_info "   Method: $method"
    log_info "   Bundle ID: ${BUNDLE_ID:-com.twinklub.twinklub}"
    log_info "   Team ID: ${APPLE_TEAM_ID:-}"
    log_info "   Code Sign Identity: ${CODE_SIGN_IDENTITY:-Automatic}"
    log_info "   Provisioning Profile: ${PROVISIONING_PROFILE_UUID:-Automatic}"
    
    cat > "$export_options_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$method</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID:-}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>destinationTimeout</key>
    <integer>30</integer>
    <key>distributionBundleIdentifier</key>
    <string>${BUNDLE_ID:-com.twinklub.twinklub}</string>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
EOF

    # Add code signing identity if available
    if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
        cat >> "$export_options_path" << EOF
    <key>signingCertificate</key>
    <string>${CODE_SIGN_IDENTITY}</string>
EOF
    fi

    # Add provisioning profile if available
    if [[ -n "${PROVISIONING_PROFILE_UUID:-}" && "${PROVISIONING_PROFILE_UUID}" != "Unknown" ]]; then
        cat >> "$export_options_path" << EOF
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID:-com.twinklub.twinklub}</key>
        <string>${PROVISIONING_PROFILE_UUID}</string>
    </dict>
EOF
    fi

    if [[ "$method" == "app-store" ]]; then
        cat >> "$export_options_path" << EOF
    <key>uploadToAppStore</key>
    <false/>
EOF
    fi

    cat >> "$export_options_path" << EOF
</dict>
</plist>
EOF
    
    if [[ -f "$export_options_path" ]]; then
        log_success "✅ Enhanced export options created: $export_options_path"
        
        # Validate export options
        if plutil -lint "$export_options_path" >/dev/null 2>&1; then
            log_success "✅ Export options validated"
        else
            log_warn "⚠️ Export options may have formatting issues"
        fi
        
        return 0
    else
        log_error "❌ Failed to create export options"
        return 1
    fi
}

# Function to test IPA export with enhanced setup
test_ipa_export() {
    log_info "🚀 Testing IPA export with enhanced certificate setup..."
    
    local archive_path="${OUTPUT_DIR:-output/ios}/Runner.xcarchive"
    local export_path="${OUTPUT_DIR:-output/ios}"
    local export_options_path="ios/ExportOptions.plist"
    
    # Verify archive exists
    if [[ ! -d "$archive_path" ]]; then
        log_error "❌ Archive not found: $archive_path"
        return 1
    fi
    
    log_info "📦 Archive found: $archive_path ($(du -h "$archive_path" | cut -f1))"
    log_info "📱 Export options: $export_options_path"
    log_info "📂 Export path: $export_path"
    
    # Test export with enhanced certificate setup
    log_info "🔧 Running xcodebuild export with enhanced certificate setup..."
    
    if xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$export_options_path" \
        -allowProvisioningUpdates 2>&1 | tee /tmp/enhanced_export.log; then
        
        log_success "✅ IPA export successful with enhanced certificate setup!"
        
        # Verify IPA was created
        local ipa_file="${export_path}/Runner.ipa"
        if [[ -f "$ipa_file" ]]; then
            local ipa_size=$(du -h "$ipa_file" | cut -f1)
            log_success "🎉 IPA file created: Runner.ipa (${ipa_size})"
            log_info "🎯 Ready for distribution via $PROFILE_TYPE"
            log_info "📋 Certificate method used: ${GENERATED_P12:+Generated from CER/KEY}${GENERATED_P12:-Downloaded P12}"
            return 0
        else
            log_warn "⚠️ Export reported success but IPA file not found"
            return 1
        fi
    else
        log_error "❌ IPA export failed even with enhanced certificate setup"
        log_info "📋 Check export log: /tmp/enhanced_export.log"
        
        # Show last few lines of error log
        if [[ -f "/tmp/enhanced_export.log" ]]; then
            log_info "📋 Last 10 lines of export log:"
            tail -10 /tmp/enhanced_export.log | while read -r line; do
                log_info "   $line"
            done
        fi
        
        return 1
    fi
}

# Function to provide comprehensive certificate solution
provide_certificate_solution() {
    log_info "💡 COMPREHENSIVE CERTIFICATE SOLUTION GUIDE"
    log_info "============================================="
    
    cat << SOLUTION

🔐 ENHANCED iOS DISTRIBUTION CERTIFICATE SETUP:

📋 CURRENT STATUS:
   ✅ Provisioning Profile: ${PROFILE_URL:+Available}
   ✅ Certificate Password: ${CERT_PASSWORD:+Custom (${#CERT_PASSWORD} chars)}${CERT_PASSWORD:-Default (Password@1234)}
   
   Certificate Methods Available:
   📦 Method 1 - Direct P12: ${CERT_P12_URL:+Available}${CERT_P12_URL:-NOT_SET}
   🔧 Method 2 - CER+KEY: ${CERT_CER_URL:+CER Available}${CERT_CER_URL:-CER NOT_SET} / ${CERT_KEY_URL:+KEY Available}${CERT_KEY_URL:-KEY NOT_SET}

🚀 SOLUTION OPTIONS:

Option A - Use Direct P12 Certificate:
   Variable Name: CERT_P12_URL
   Variable Value: https://raw.githubusercontent.com/prasanna91/QuikApp/main/ios_distribution_certificate.p12

Option B - Generate P12 from CER and KEY files:
   Variable Name: CERT_CER_URL
   Variable Value: https://raw.githubusercontent.com/prasanna91/QuikApp/main/certificate.cer
   
   Variable Name: CERT_KEY_URL  
   Variable Value: https://raw.githubusercontent.com/prasanna91/QuikApp/main/private_key.key
   
   Optional - Custom Password:
   Variable Name: CERT_PASSWORD
   Variable Value: YourCustomPassword (default: Password@1234)

🎯 AUTOMATIC P12 GENERATION:
   If CERT_P12_URL is empty/invalid AND CERT_CER_URL + CERT_KEY_URL are set:
   → Script will automatically download CER and KEY files
   → Generate P12 certificate with specified/default password
   → Install certificate for code signing
   → Extract required variables for IPA export

✅ Expected result: IPA export will succeed with either method!

SOLUTION

    log_success "💡 Comprehensive certificate solution guide provided"
}

# Main execution function
main() {
    log_info "🚀 Enhanced Certificate Setup v2.0 Starting..."
    
    # Stage 1: Validate current setup
    log_info "--- Stage 1: Certificate Setup Validation ---"
    local missing_items=0
    if ! validate_certificate_setup; then
        missing_items=$?
        log_warn "⚠️ Certificate setup has $missing_items missing items"
    else
        log_success "✅ Certificate setup validation complete"
    fi
    
    # Stage 2: Automatic certificate configuration
    log_info "--- Stage 2: Automatic Certificate Configuration ---"
    if setup_automatic_certificate_config; then
        log_success "✅ Certificate configuration completed"
    else
        log_warn "⚠️ Certificate configuration had issues"
    fi
    
    # Stage 3: Keychain and certificate setup
    log_info "--- Stage 3: Keychain and Certificate Installation ---"
    if setup_keychain_and_certificates; then
        log_success "✅ Keychain and certificates configured"
    else
        log_warn "⚠️ Keychain setup had issues"
    fi
    
    # Stage 4: Provisioning profile setup
    log_info "--- Stage 4: Provisioning Profile Setup ---"
    if setup_provisioning_profile; then
        log_success "✅ Provisioning profile configured"
    else
        log_warn "⚠️ Provisioning profile setup had issues"
    fi
    
    # Stage 5: Enhanced export options
    log_info "--- Stage 5: Enhanced Export Options ---"
    if create_enhanced_export_options; then
        log_success "✅ Enhanced export options created"
    else
        log_error "❌ Failed to create export options"
        return 1
    fi
    
    # Stage 6: Test IPA export (if archive exists)
    if [[ -d "${OUTPUT_DIR:-output/ios}/Runner.xcarchive" ]]; then
        log_info "--- Stage 6: Test IPA Export ---"
        if test_ipa_export; then
            log_success "🎉 IPA EXPORT SUCCESSFUL!"
            log_info "================================="
            log_success "✅ All certificate issues resolved"
            log_success "✅ IPA file created successfully"
            log_success "✅ Ready for App Store distribution"
            log_success "✅ Method: ${GENERATED_P12:+P12 Generated from CER/KEY}${GENERATED_P12:-P12 Downloaded from URL}"
            return 0
        else
            log_error "❌ IPA export still failed"
        fi
    else
        log_info "--- Stage 6: Archive Not Found (Skipping IPA Export Test) ---"
        log_info "📦 No archive found at: ${OUTPUT_DIR:-output/ios}/Runner.xcarchive"
        log_info "🎯 This script prepares certificates for when archive is available"
    fi
    
    # Stage 7: Provide solution guide
    log_info "--- Stage 7: Comprehensive Solution Guide ---"
    provide_certificate_solution
    
    # Return appropriate status
    if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
        log_success "✅ Certificate setup completed successfully"
        return 0
    else
        log_warn "⚠️ Certificate setup needs attention"
        return 1
    fi
}

# Cleanup function
cleanup() {
    # Clean up any temporary files
    rm -rf /tmp/cert_generation_* 2>/dev/null || true
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@" 