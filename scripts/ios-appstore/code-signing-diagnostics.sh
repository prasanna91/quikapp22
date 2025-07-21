#!/bin/bash

# 🔍 iOS App Store Code Signing Diagnostics
# Comprehensive diagnostics for certificate and provisioning profile issues

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

# Function to test URL accessibility
test_url() {
    local url="$1"
    local description="$2"
    
    echo -e "${BLUE}🔍 Testing $description URL: $url${NC}"
    
    if curl -I --fail --silent "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ URL is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ URL is not accessible${NC}"
        return 1
    fi
}

# Function to check certificate files
check_certificate_files() {
    echo -e "${BLUE}📋 Checking Downloaded Certificate Files${NC}"
    echo "----------------------------------------"
    
    local found_files=0
    
    if [ -f "temp/certificate.p12" ]; then
        echo -e "${GREEN}✅ Found P12 certificate: temp/certificate.p12${NC}"
        local size=$(stat -f%z "temp/certificate.p12" 2>/dev/null || stat -c%s "temp/certificate.p12" 2>/dev/null || echo "unknown")
        echo -e "${BLUE}   Size: $size bytes${NC}"
        found_files=$((found_files + 1))
    fi
    
    if [ -f "temp/certificate.cer" ]; then
        echo -e "${GREEN}✅ Found CER certificate: temp/certificate.cer${NC}"
        local size=$(stat -f%z "temp/certificate.cer" 2>/dev/null || stat -c%s "temp/certificate.cer" 2>/dev/null || echo "unknown")
        echo -e "${BLUE}   Size: $size bytes${NC}"
        found_files=$((found_files + 1))
    fi
    
    if [ -f "temp/certificate.key" ]; then
        echo -e "${GREEN}✅ Found KEY certificate: temp/certificate.key${NC}"
        local size=$(stat -f%z "temp/certificate.key" 2>/dev/null || stat -c%s "temp/certificate.key" 2>/dev/null || echo "unknown")
        echo -e "${BLUE}   Size: $size bytes${NC}"
        found_files=$((found_files + 1))
    fi
    
    if [ $found_files -eq 0 ]; then
        echo -e "${RED}❌ No certificate files found in temp/ directory${NC}"
        return 1
    fi
    
    return 0
}

# Function to check system setup
check_system_setup() {
    echo -e "${BLUE}📋 Checking System Setup${NC}"
    echo "----------------------------------------"
    
    # Check keychain
    echo -e "${BLUE}🔍 Checking keychain setup${NC}"
    local identity_count=$(security find-identity -v -p codesigning | grep -c "iPhone Distribution\|Apple Distribution" || echo "0")
    if [ "$identity_count" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $identity_count Apple Distribution certificates in keychain${NC}"
        security find-identity -v -p codesigning | grep -E "(iPhone Distribution|Apple Distribution)" || true
    else
        echo -e "${RED}❌ No Apple Distribution certificates found in keychain${NC}"
    fi
    
    # Check login keychain
    if security list-keychains | grep -q "login.keychain"; then
        echo -e "${GREEN}✅ Login keychain is available${NC}"
    else
        echo -e "${RED}❌ Login keychain not found${NC}"
    fi
    
    # Check provisioning profiles directory
    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    echo -e "${BLUE}🔍 Checking provisioning profiles directory: $profiles_dir${NC}"
    if [ -d "$profiles_dir" ]; then
        echo -e "${GREEN}✅ Provisioning profiles directory exists${NC}"
        local profile_count=$(find "$profiles_dir" -name "*.mobileprovision" | wc -l)
        echo -e "${BLUE}📋 Found $profile_count provisioning profiles${NC}"
        
        if [ "$profile_count" -gt 0 ]; then
            echo -e "${BLUE}📋 Profile list:${NC}"
            find "$profiles_dir" -name "*.mobileprovision" -exec basename {} \; | head -5
        fi
    else
        echo -e "${RED}❌ Provisioning profiles directory not found${NC}"
    fi
}

# Function to validate Xcode project
validate_xcode_project() {
    echo -e "${BLUE}📋 Validating Xcode Project Signing Configuration${NC}"
    echo "----------------------------------------"
    
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        echo -e "${GREEN}✅ Xcode project file found${NC}"
        
        # Check code signing settings
        local manual_signing=$(grep -c "CODE_SIGN_STYLE = Manual" ios/Runner.xcodeproj/project.pbxproj || echo "0")
        if [ "$manual_signing" -gt 0 ]; then
            echo -e "${GREEN}✅ Manual code signing is configured${NC}"
        else
            echo -e "${YELLOW}⚠️ Manual code signing not configured (this is normal for automatic signing)${NC}"
        fi
        
        # Check bundle ID
        local bundle_id=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = "[^"]*"' ios/Runner.xcodeproj/project.pbxproj | head -1 | cut -d'"' -f2 || echo "")
        if [ -n "$bundle_id" ]; then
            echo -e "${BLUE}📋 Bundle ID in project: $bundle_id${NC}"
        else
            echo -e "${YELLOW}⚠️ Bundle ID not found in project file${NC}"
        fi
        
        # Check product name
        local product_name=$(grep -o 'PRODUCT_NAME = "[^"]*"' ios/Runner.xcodeproj/project.pbxproj | head -1 | cut -d'"' -f2 || echo "")
        if [ -n "$product_name" ]; then
            echo -e "${BLUE}📋 Product name in project: $product_name${NC}"
        else
            echo -e "${YELLOW}⚠️ Product name not found in project file${NC}"
        fi
    else
        echo -e "${RED}❌ Xcode project file not found${NC}"
    fi
    
    # Check export options
    if [ -f "ios/ExportOptions.plist" ]; then
        echo -e "${GREEN}✅ Export options file found${NC}"
        local method=$(plutil -extract method raw "ios/ExportOptions.plist" 2>/dev/null || echo "")
        if [ -n "$method" ]; then
            echo -e "${BLUE}📋 Export method: $method${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Export options file not found${NC}"
    fi
}

# Function to provide troubleshooting guidance
provide_troubleshooting_guidance() {
    echo -e "${BLUE}📋 Troubleshooting Guidance${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}💡 Common Issues and Solutions:${NC}"
    echo ""
    echo -e "${BLUE}1. Certificate Download Issues:${NC}"
    echo "   - Ensure the certificate file exists at the provided URL"
    echo "   - Verify the repository is public and accessible"
    echo "   - Check if the URL is correct and accessible from the build environment"
    echo "   - Consider using CER/KEY certificates instead of P12"
    echo ""
    echo -e "${BLUE}2. Certificate Import Issues:${NC}"
    echo "   - Verify the certificate password is correct"
    echo "   - Ensure the certificate is valid and not expired"
    echo "   - Check if the certificate matches the provisioning profile"
    echo ""
    echo -e "${BLUE}3. Provisioning Profile Issues:${NC}"
    echo "   - Ensure the profile is valid and not expired"
    echo "   - Verify the profile matches the bundle ID"
    echo "   - Check if the profile is for the correct team"
    echo ""
    echo -e "${BLUE}4. Code Signing Issues:${NC}"
    echo "   - Ensure the certificate and profile are properly installed"
    echo "   - Verify the bundle ID matches the profile"
    echo "   - Check if the team ID is correct"
    echo ""
    echo -e "${BLUE}5. Environment Variables:${NC}"
    echo "   - CERT_P12_URL: Direct P12 certificate URL"
    echo "   - CERT_CER_URL + CERT_KEY_URL: CER and KEY certificate URLs"
    echo "   - CERT_PASSWORD: Certificate password"
    echo "   - PROFILE_URL: Provisioning profile URL"
    echo "   - BUNDLE_ID: App bundle identifier"
    echo "   - APPLE_TEAM_ID: Apple Developer Team ID"
    echo ""
}

# Main diagnostics function
run_diagnostics() {
    echo -e "${BLUE}🔍 iOS App Store Code Signing Diagnostics${NC}"
    echo "=========================================="
    echo ""
    
    # Check required environment variables
    echo -e "${BLUE}📋 Checking Required Environment Variables${NC}"
    echo "----------------------------------------"
    
    local errors=0
    
    if ! check_var "BUNDLE_ID"; then errors=$((errors + 1)); fi
    if ! check_var "PROFILE_TYPE"; then errors=$((errors + 1)); fi
    if ! check_var "CERT_PASSWORD"; then errors=$((errors + 1)); fi
    if ! check_var "PROFILE_URL"; then errors=$((errors + 1)); fi
    if ! check_var "APPLE_TEAM_ID"; then errors=$((errors + 1)); fi
    
    # Check certificate URLs
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${GREEN}✅ CERT_P12_URL is set${NC}"
    elif [ -n "${CERT_CER_URL:-}" ] && [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${GREEN}✅ CERT_CER_URL and CERT_KEY_URL are set${NC}"
    else
        echo -e "${RED}❌ No certificate URLs provided${NC}"
        errors=$((errors + 1))
    fi
    
    # Validate profile type
    if [ "${PROFILE_TYPE:-}" = "app-store" ]; then
        echo -e "${GREEN}✅ Valid profile type: app-store${NC}"
    else
        echo -e "${RED}❌ Invalid profile type: ${PROFILE_TYPE:-not_set} (should be app-store)${NC}"
        errors=$((errors + 1))
    fi
    
    echo ""
    
    # Test URL accessibility
    echo -e "${BLUE}📋 Checking URL Accessibility${NC}"
    echo "----------------------------------------"
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        if ! test_url "$CERT_P12_URL" "Certificate P12"; then
            errors=$((errors + 1))
        fi
    fi
    
    if [ -n "${CERT_CER_URL:-}" ]; then
        if ! test_url "$CERT_CER_URL" "Certificate CER"; then
            errors=$((errors + 1))
        fi
    fi
    
    if [ -n "${CERT_KEY_URL:-}" ]; then
        if ! test_url "$CERT_KEY_URL" "Certificate KEY"; then
            errors=$((errors + 1))
        fi
    fi
    
    if ! test_url "$PROFILE_URL" "Provisioning Profile"; then
        errors=$((errors + 1))
    fi
    
    echo ""
    
    # Check downloaded files
    if [ -d "temp" ]; then
        check_certificate_files
    else
        echo -e "${YELLOW}⚠️ No temp directory found (files not downloaded yet)${NC}"
    fi
    
    echo ""
    
    # Check system setup
    check_system_setup
    
    echo ""
    
    # Validate Xcode project
    validate_xcode_project
    
    echo ""
    
    # Provide troubleshooting guidance
    provide_troubleshooting_guidance
    
    echo ""
    
    # Summary
    echo -e "${BLUE}📋 Diagnostic Summary${NC}"
    echo "----------------------------------------"
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed! Code signing setup appears correct.${NC}"
        echo -e "${BLUE}💡 If you're still getting signing errors, check the build logs for specific codesign/xcodebuild errors.${NC}"
    else
        echo -e "${RED}❌ Found $errors issue(s) that need to be resolved.${NC}"
        echo -e "${YELLOW}💡 Please fix the issues above before proceeding with the build.${NC}"
    fi
    
    echo ""
}

# Run diagnostics
run_diagnostics 