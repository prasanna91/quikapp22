#!/bin/bash

# 🔐 Simple iOS App Store Code Signing Setup
# Simplified version focusing on core functionality

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

# Function to download file with simple retry
download_file_simple() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    
    echo -e "${BLUE}📥 Downloading $description from $url${NC}"
    
    # Try to download
    if curl -L -o "$output_path" "$url"; then
        if [ -s "$output_path" ]; then
            local size=$(stat -f%z "$output_path" 2>/dev/null || stat -c%s "$output_path" 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✅ Downloaded $description successfully (size: $size bytes)${NC}"
            return 0
        else
            echo -e "${RED}❌ Downloaded file is empty${NC}"
            rm -f "$output_path"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to download $description${NC}"
        return 1
    fi
}

# Function to import P12 certificate
import_p12_certificate() {
    local cert_path="$1"
    local password="$2"
    
    echo -e "${BLUE}🔐 Importing P12 certificate into keychain${NC}"
    
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
            return 0
        else
            echo -e "${RED}❌ No Apple Distribution identities found in keychain${NC}"
            return 1
        fi
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
    
    echo -e "${BLUE}🔧 Creating P12 certificate from CER and KEY files${NC}"
    
    # Convert CER to PEM
    if openssl x509 -in "$cer_path" -inform DER -out temp_cert.pem; then
        echo -e "${GREEN}✅ Converted CER to PEM${NC}"
    else
        echo -e "${RED}❌ Failed to convert CER to PEM${NC}"
        return 1
    fi
    
    # Convert KEY to PEM (try with and without password)
    if openssl rsa -in "$key_path" -out temp_key.pem -passin pass:"$password" 2>/dev/null; then
        echo -e "${GREEN}✅ Converted KEY to PEM (with password)${NC}"
    elif openssl rsa -in "$key_path" -out temp_key.pem 2>/dev/null; then
        echo -e "${GREEN}✅ Converted KEY to PEM (no password)${NC}"
    else
        echo -e "${RED}❌ Failed to convert KEY to PEM${NC}"
        return 1
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
    
    echo -e "${BLUE}📋 Installing provisioning profile${NC}"
    
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
        return 0
    else
        echo -e "${RED}❌ Failed to install provisioning profile${NC}"
        return 1
    fi
}

# Main setup function
setup_code_signing() {
    echo -e "${BLUE}🔐 Setting up iOS App Store Code Signing (Simple Version)${NC}"
    echo "================================================================"
    echo ""
    
    # Validate required variables
    if [ -z "${BUNDLE_ID:-}" ]; then
        echo -e "${RED}❌ BUNDLE_ID is not set${NC}"
        exit 1
    fi
    
    if [ -z "${CERT_PASSWORD:-}" ]; then
        echo -e "${RED}❌ CERT_PASSWORD is not set${NC}"
        exit 1
    fi
    
    if [ -z "${PROFILE_URL:-}" ]; then
        echo -e "${RED}❌ PROFILE_URL is not set${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Required variables validated${NC}"
    echo ""
    
    # Create temp directory
    mkdir -p temp
    cd temp
    
    # Download and setup certificate
    echo -e "${BLUE}📋 Setting up Certificate${NC}"
    echo "----------------------------------------"
    
    local cert_path=""
    local p12_path="certificate.p12"
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${BLUE}🔍 Using P12 certificate: ${CERT_P12_URL}${NC}"
        if download_file_simple "$CERT_P12_URL" "$p12_path" "P12 Certificate"; then
            cert_path="$p12_path"
        else
            echo -e "${RED}❌ Failed to download P12 certificate${NC}"
            exit 1
        fi
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${BLUE}🔍 Using CER/KEY certificates${NC}"
        local cer_path="certificate.cer"
        local key_path="certificate.key"
        
        if download_file_simple "$CERT_CER_URL" "$cer_path" "CER Certificate" && \
           download_file_simple "$CERT_KEY_URL" "$key_path" "KEY Certificate"; then
            
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
    
    local profile_path="profile.mobileprovision"
    
    if download_file_simple "$PROFILE_URL" "$profile_path" "Provisioning Profile"; then
        if ! install_provisioning_profile "$profile_path"; then
            echo -e "${RED}❌ Failed to install provisioning profile${NC}"
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
    
    echo ""
    echo -e "${GREEN}🎉 Simple iOS App Store Code Signing Setup Complete!${NC}"
    echo -e "${BLUE}💡 Your build is now ready for App Store submission.${NC}"
    
    cd ..
}

# Run setup
setup_code_signing 