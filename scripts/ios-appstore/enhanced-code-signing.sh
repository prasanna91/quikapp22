#!/bin/bash

# 🔐 Enhanced iOS App Store Code Signing Setup
# Comprehensive certificate and provisioning profile management for App Store builds

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

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
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}❌ $var_name is not set or empty${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $var_name is set${NC}"
        return 0
    fi
}

# Function to download file with retry
download_file() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    local max_retries="${4:-3}"
    
    log "Downloading $description from $url"
    
    # Check if URL is accessible first
    if ! curl -I --fail --silent "$url" >/dev/null 2>&1; then
        echo -e "${RED}❌ URL is not accessible: $url${NC}"
        echo -e "${YELLOW}💡 This could be due to:${NC}"
        echo -e "${YELLOW}   - File doesn't exist at the URL${NC}"
        echo -e "${YELLOW}   - Repository is private${NC}"
        echo -e "${YELLOW}   - Network connectivity issues${NC}"
        echo -e "${YELLOW}   - URL is incorrect${NC}"
        return 1
    fi
    
    for ((i=1; i<=max_retries; i++)); do
        echo -e "${BLUE}📥 Download attempt $i/$max_retries for $description${NC}"
        
        # Try to download with verbose output for debugging
        if curl -L -v -o "$output_path" "$url" 2>&1; then
            # Verify the downloaded file is not empty
            if [ -s "$output_path" ]; then
                local size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "unknown")
                echo -e "${GREEN}✅ Downloaded $description successfully (size: $size bytes)${NC}"
                return 0
            else
                echo -e "${RED}❌ Downloaded file is empty${NC}"
                rm -f "$output_path"
            fi
        else
            echo -e "${YELLOW}⚠️ Download attempt $i failed for $description${NC}"
            if [ $i -lt $max_retries ]; then
                echo -e "${BLUE}⏳ Waiting 2 seconds before retry...${NC}"
                sleep 2
            fi
        fi
    done
    
    echo -e "${RED}❌ Failed to download $description after $max_retries attempts${NC}"
    return 1
}

# Function to import P12 certificate
import_p12_certificate() {
    local cert_path="$1"
    local password="$2"
    
    log "Importing P12 certificate into keychain"
    
    # Create temporary keychain for this build
    local keychain_name="build.keychain"
    local keychain_password="temp_password_$(date +%s)"
    
    # Create new keychain
    security create-keychain -p "$keychain_password" "$keychain_name"
    security default-keychain -s "$keychain_name"
    security unlock-keychain -p "$keychain_password" "$keychain_name"
    security set-keychain-settings -t 3600 -u "$keychain_name"
    
    # Import certificate
    if security import "$cert_path" -k "$keychain_name" -P "$password" -T /usr/bin/codesign; then
        echo -e "${GREEN}✅ P12 certificate imported successfully${NC}"
        
        # Verify import
        local identity_count=$(security find-identity -v -p codesigning "$keychain_name" | grep -c "iPhone Distribution\|Apple Distribution" || echo "0")
        if [ "$identity_count" -gt 0 ]; then
            echo -e "${GREEN}✅ Found $identity_count Apple Distribution identity(ies) in keychain${NC}"
            
            # List identities
            security find-identity -v -p codesigning "$keychain_name" | grep -E "(iPhone Distribution|Apple Distribution)" || true
        else
            echo -e "${RED}❌ No Apple Distribution identities found in keychain${NC}"
            return 1
        fi
        
        return 0
    else
        echo -e "${RED}❌ Failed to import P12 certificate${NC}"
        return 1
    fi
}

# Function to create P12 from CER and KEY
create_p12_from_cer_key() {
    local cer_path="$1"
    local key_path="$2"
    local password="$3"
    local output_path="$4"
    
    log "Creating P12 certificate from CER and KEY files"
    
    # Convert CER to PEM
    if openssl x509 -in "$cer_path" -inform DER -out temp_cert.pem; then
        echo -e "${GREEN}✅ Converted CER to PEM${NC}"
    else
        echo -e "${RED}❌ Failed to convert CER to PEM${NC}"
        return 1
    fi
    
    # Convert KEY to PEM (if needed)
    if openssl rsa -in "$key_path" -out temp_key.pem -passin pass:"$password" 2>/dev/null; then
        echo -e "${GREEN}✅ Converted KEY to PEM${NC}"
    else
        # Try without password
        if openssl rsa -in "$key_path" -out temp_key.pem 2>/dev/null; then
            echo -e "${GREEN}✅ Converted KEY to PEM (no password)${NC}"
        else
            echo -e "${RED}❌ Failed to convert KEY to PEM${NC}"
            return 1
        fi
    fi
    
    # Create P12
    if openssl pkcs12 -export -out "$output_path" -inkey temp_key.pem -in temp_cert.pem -passout pass:"$password"; then
        echo -e "${GREEN}✅ Created P12 certificate successfully${NC}"
        
        # Clean up temp files
        rm -f temp_cert.pem temp_key.pem
        
        return 0
    else
        echo -e "${RED}❌ Failed to create P12 certificate${NC}"
        rm -f temp_cert.pem temp_key.pem
        return 1
    fi
}

# Function to install provisioning profile
install_provisioning_profile() {
    local profile_path="$1"
    
    log "Installing provisioning profile"
    
    # Create provisioning profiles directory if it doesn't exist
    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    mkdir -p "$profiles_dir"
    
    # Get profile UUID
    local profile_uuid=$(security cms -D -i "$profile_path" 2>/dev/null | plutil -extract UUID raw - 2>/dev/null || echo "")
    
    if [ -z "$profile_uuid" ]; then
        echo -e "${RED}❌ Could not extract UUID from provisioning profile${NC}"
        return 1
    fi
    
    # Install profile
    local target_path="$profiles_dir/$profile_uuid.mobileprovision"
    if cp "$profile_path" "$target_path"; then
        echo -e "${GREEN}✅ Provisioning profile installed: $target_path${NC}"
        
        # Verify installation
        if [ -f "$target_path" ]; then
            echo -e "${GREEN}✅ Profile verification successful${NC}"
            
            # Extract profile info
            local app_id=$(security cms -D -i "$target_path" 2>/dev/null | plutil -extract Entitlements.application-identifier raw - 2>/dev/null || echo "")
            local team_id=$(security cms -D -i "$target_path" 2>/dev/null | plutil -extract TeamIdentifier.0 raw - 2>/dev/null || echo "")
            
            echo -e "${BLUE}📋 Profile App ID: $app_id${NC}"
            echo -e "${BLUE}📋 Profile Team ID: $team_id${NC}"
            
            return 0
        else
            echo -e "${RED}❌ Profile installation verification failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to install provisioning profile${NC}"
        return 1
    fi
}

# Function to create export options plist
create_export_options() {
    local bundle_id="$1"
    local team_id="$2"
    local profile_uuid="$3"
    local output_path="$4"
    
    log "Creating export options plist for App Store"
    
    cat > "$output_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$team_id</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>$bundle_id</key>
        <string>$profile_uuid</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    if [ -f "$output_path" ]; then
        echo -e "${GREEN}✅ Export options plist created: $output_path${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create export options plist${NC}"
        return 1
    fi
}

# Function to validate App Store readiness
validate_app_store_readiness() {
    log "Validating App Store build readiness"
    
    # Check bundle ID
    if [ -z "${BUNDLE_ID:-}" ]; then
        echo -e "${RED}❌ BUNDLE_ID is not set${NC}"
        return 1
    fi
    
    # Check team ID
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        echo -e "${RED}❌ APPLE_TEAM_ID is not set${NC}"
        return 1
    fi
    
    # Check profile type
    if [ "${PROFILE_TYPE:-}" != "app-store" ]; then
        echo -e "${RED}❌ PROFILE_TYPE must be 'app-store' for App Store builds${NC}"
        return 1
    fi
    
    # Check certificate password
    if [ -z "${CERT_PASSWORD:-}" ]; then
        echo -e "${RED}❌ CERT_PASSWORD is not set${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ App Store build configuration is valid${NC}"
    return 0
}

# Main setup function
setup_code_signing() {
    echo -e "${BLUE}🔐 Setting up iOS App Store Code Signing${NC}"
    echo "================================================"
    echo ""
    
    # Validate configuration
    if ! validate_app_store_readiness; then
        echo -e "${RED}❌ App Store configuration validation failed${NC}"
        exit 1
    fi
    
    # Create temp directory
    mkdir -p temp
    cd temp
    
    # Download and setup certificate
    echo -e "${BLUE}📋 Setting up Certificate${NC}"
    echo "----------------------------------------"
    
    local cert_path=""
    local p12_path="temp/certificate.p12"
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${BLUE}🔍 Attempting to download P12 certificate from: ${CERT_P12_URL}${NC}"
        # Download P12 certificate
        if download_file "$CERT_P12_URL" "$p12_path" "P12 Certificate"; then
            cert_path="$p12_path"
        else
            echo -e "${RED}❌ Failed to download P12 certificate from: ${CERT_P12_URL}${NC}"
            echo -e "${YELLOW}💡 Possible solutions:${NC}"
            echo -e "${YELLOW}   1. Check if the certificate file exists at the URL${NC}"
            echo -e "${YELLOW}   2. Verify the repository is public and accessible${NC}"
            echo -e "${YELLOW}   3. Use CER/KEY certificate URLs instead${NC}"
            echo -e "${YELLOW}   4. Upload the certificate to a public repository${NC}"
            
            # Check if we have CER/KEY as fallback
            if [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
                echo -e "${BLUE}🔄 Attempting fallback to CER/KEY certificates...${NC}"
                local cer_path="temp/certificate.cer"
                local key_path="temp/certificate.key"
                
                if download_file "$CERT_CER_URL" "$cer_path" "CER Certificate" && \
                   download_file "$CERT_KEY_URL" "$key_path" "KEY Certificate"; then
                    
                    # Create P12 from CER and KEY
                    if create_p12_from_cer_key "$cer_path" "$key_path" "$CERT_PASSWORD" "$p12_path"; then
                        cert_path="$p12_path"
                        echo -e "${GREEN}✅ Successfully created P12 from CER/KEY certificates${NC}"
                    else
                        echo -e "${RED}❌ Failed to create P12 certificate from CER/KEY${NC}"
                        exit 1
                    fi
                else
                    echo -e "${RED}❌ Failed to download CER/KEY certificates as fallback${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}❌ No CER/KEY certificates available as fallback${NC}"
                echo -e "${YELLOW}💡 Please provide either:${NC}"
                echo -e "${YELLOW}   - A valid CERT_P12_URL, or${NC}"
                echo -e "${YELLOW}   - Both CERT_CER_URL and CERT_KEY_URL${NC}"
                exit 1
            fi
        fi
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${BLUE}🔍 Using CER/KEY certificates to create P12${NC}"
        # Download CER and KEY certificates
        local cer_path="temp/certificate.cer"
        local key_path="temp/certificate.key"
        
        if download_file "$CERT_CER_URL" "$cer_path" "CER Certificate" && \
           download_file "$CERT_KEY_URL" "$key_path" "KEY Certificate"; then
            
            # Create P12 from CER and KEY
            if create_p12_from_cer_key "$cer_path" "$key_path" "$CERT_PASSWORD" "$p12_path"; then
                cert_path="$p12_path"
            else
                echo -e "${RED}❌ Failed to create P12 certificate${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ Failed to download CER/KEY certificates${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ No certificate URLs provided${NC}"
        echo -e "${YELLOW}💡 Required environment variables:${NC}"
        echo -e "${YELLOW}   - CERT_P12_URL: Direct P12 certificate URL, or${NC}"
        echo -e "${YELLOW}   - CERT_CER_URL + CERT_KEY_URL: CER and KEY certificate URLs${NC}"
        echo -e "${YELLOW}   - CERT_PASSWORD: Certificate password${NC}"
        exit 1
    fi
    
    # Import certificate
    if ! import_p12_certificate "$cert_path" "$CERT_PASSWORD"; then
        echo -e "${RED}❌ Failed to import certificate${NC}"
        exit 1
    fi
    
    echo ""
    
    # Download and setup provisioning profile
    echo -e "${BLUE}📋 Setting up Provisioning Profile${NC}"
    echo "----------------------------------------"
    
    local profile_path="temp/profile.mobileprovision"
    
    if download_file "$PROFILE_URL" "$profile_path" "Provisioning Profile"; then
        if ! install_provisioning_profile "$profile_path"; then
            echo -e "${RED}❌ Failed to install provisioning profile${NC}"
            exit 1
        fi
        
        # Get profile UUID for export options
        local profile_uuid=$(security cms -D -i "$profile_path" 2>/dev/null | plutil -extract UUID raw - 2>/dev/null || echo "")
        
        if [ -n "$profile_uuid" ]; then
            # Create export options plist
            local export_options_path="../ios/ExportOptions.plist"
            if create_export_options "$BUNDLE_ID" "$APPLE_TEAM_ID" "$profile_uuid" "$export_options_path"; then
                echo -e "${GREEN}✅ Export options configured for App Store${NC}"
            else
                echo -e "${RED}❌ Failed to create export options${NC}"
                exit 1
            fi
        else
            echo -e "${RED}❌ Could not extract profile UUID for export options${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to download provisioning profile${NC}"
        exit 1
    fi
    
    echo ""
    
    # Final validation
    echo -e "${BLUE}📋 Final Validation${NC}"
    echo "----------------------------------------"
    
    # Check keychain
    local identity_count=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution\|Apple Distribution" || echo "0")
    if [ "$identity_count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $identity_count Apple Distribution identity(ies)${NC}"
    else
        echo -e "${RED}❌ No Apple Distribution identities found${NC}"
        exit 1
    fi
    
    # Check provisioning profiles
    local profile_count=$(find "$HOME/Library/MobileDevice/Provisioning Profiles" -name "*.mobileprovision" | wc -l)
    if [ "$profile_count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $profile_count provisioning profile(s)${NC}"
    else
        echo -e "${RED}❌ No provisioning profiles found${NC}"
        exit 1
    fi
    
    # Check export options
    if [ -f "../ios/ExportOptions.plist" ]; then
        echo -e "${GREEN}✅ Export options file exists${NC}"
        
        local method=$(plutil -extract method raw "../ios/ExportOptions.plist" 2>/dev/null || echo "")
        if [ "$method" = "app-store" ]; then
            echo -e "${GREEN}✅ Export method is app-store${NC}"
        else
            echo -e "${RED}❌ Export method is not app-store: $method${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Export options file not found${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 iOS App Store Code Signing Setup Complete!${NC}"
    echo -e "${BLUE}💡 Your build is now ready for App Store submission.${NC}"
    
    cd ..
}

# Run setup
setup_code_signing 