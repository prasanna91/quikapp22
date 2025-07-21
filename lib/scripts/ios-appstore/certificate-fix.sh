#!/bin/bash

# 🔧 iOS App Store Certificate Fix Script
# Helps resolve certificate download and setup issues

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

# Function to check if URL is accessible
check_url() {
    local url="$1"
    local description="$2"
    
    echo -e "${BLUE}🔍 Testing $description: $url${NC}"
    
    if curl -I --fail --silent "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ URL is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ URL is not accessible${NC}"
        return 1
    fi
}

# Function to suggest alternative certificate URLs
suggest_alternatives() {
    echo -e "${BLUE}💡 Certificate URL Alternatives${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}The current certificate URL is not accessible. Here are some alternatives:${NC}"
    echo ""
    echo -e "${BLUE}1. Use CER/KEY certificates instead of P12:${NC}"
    echo "   - Set CERT_CER_URL to your .cer certificate file URL"
    echo "   - Set CERT_KEY_URL to your .key certificate file URL"
    echo "   - Keep CERT_PASSWORD for the certificate password"
    echo ""
    echo -e "${BLUE}2. Upload certificate to a public repository:${NC}"
    echo "   - Upload your .p12 file to a public GitHub repository"
    echo "   - Use the raw URL (e.g., https://raw.githubusercontent.com/user/repo/main/cert.p12)"
    echo "   - Ensure the repository is public and accessible"
    echo ""
    echo -e "${BLUE}3. Use a different hosting service:${NC}"
    echo "   - Google Drive (with proper sharing settings)"
    echo "   - Dropbox (with public link)"
    echo "   - AWS S3 (with public access)"
    echo "   - Azure Blob Storage (with public access)"
    echo ""
    echo -e "${BLUE}4. Example environment variables:${NC}"
    echo "   # Option 1: P12 certificate"
    echo "   CERT_P12_URL=https://raw.githubusercontent.com/your-username/your-repo/main/cert.p12"
    echo "   CERT_PASSWORD=your_certificate_password"
    echo ""
    echo "   # Option 2: CER/KEY certificates"
    echo "   CERT_CER_URL=https://raw.githubusercontent.com/your-username/your-repo/main/cert.cer"
    echo "   CERT_KEY_URL=https://raw.githubusercontent.com/your-username/your-repo/main/cert.key"
    echo "   CERT_PASSWORD=your_certificate_password"
    echo ""
}

# Function to test current certificate URLs
test_current_certificates() {
    echo -e "${BLUE}🔍 Testing Current Certificate URLs${NC}"
    echo "----------------------------------------"
    
    local has_accessible_cert=false
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${BLUE}📋 Testing P12 certificate URL:${NC}"
        if check_url "$CERT_P12_URL" "P12 Certificate"; then
            has_accessible_cert=true
        fi
    fi
    
    if [ -n "${CERT_CER_URL:-}" ]; then
        echo -e "${BLUE}📋 Testing CER certificate URL:${NC}"
        if check_url "$CERT_CER_URL" "CER Certificate"; then
            has_accessible_cert=true
        fi
    fi
    
    if [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${BLUE}📋 Testing KEY certificate URL:${NC}"
        if check_url "$CERT_KEY_URL" "KEY Certificate"; then
            has_accessible_cert=true
        fi
    fi
    
    if [ "$has_accessible_cert" = true ]; then
        echo -e "${GREEN}✅ At least one certificate URL is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ No certificate URLs are accessible${NC}"
        return 1
    fi
}

# Function to create a sample certificate setup
create_sample_setup() {
    echo -e "${BLUE}📋 Creating Sample Certificate Setup${NC}"
    echo "----------------------------------------"
    
    # Create a sample directory structure
    mkdir -p sample_certificates
    
    echo -e "${YELLOW}💡 Sample certificate files created in sample_certificates/ directory${NC}"
    echo ""
    echo -e "${BLUE}To use these sample files:${NC}"
    echo "1. Replace the sample files with your actual certificates"
    echo "2. Upload them to a public repository"
    echo "3. Update the environment variables with the new URLs"
    echo ""
    
    # Create sample files (empty files for demonstration)
    touch sample_certificates/certificate.p12
    touch sample_certificates/certificate.cer
    touch sample_certificates/certificate.key
    touch sample_certificates/profile.mobileprovision
    
    echo -e "${GREEN}✅ Sample files created:${NC}"
    echo "   - sample_certificates/certificate.p12"
    echo "   - sample_certificates/certificate.cer"
    echo "   - sample_certificates/certificate.key"
    echo "   - sample_certificates/profile.mobileprovision"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Replace these files with your actual certificates"
    echo "2. Upload to a public GitHub repository"
    echo "3. Use the raw URLs in your environment variables"
}

# Function to validate environment variables
validate_environment() {
    echo -e "${BLUE}📋 Validating Environment Variables${NC}"
    echo "----------------------------------------"
    
    local missing_vars=()
    
    # Check required variables
    if [ -z "${BUNDLE_ID:-}" ]; then
        missing_vars+=("BUNDLE_ID")
    fi
    
    if [ -z "${CERT_PASSWORD:-}" ]; then
        missing_vars+=("CERT_PASSWORD")
    fi
    
    if [ -z "${PROFILE_URL:-}" ]; then
        missing_vars+=("PROFILE_URL")
    fi
    
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        missing_vars+=("APPLE_TEAM_ID")
    fi
    
    # Check certificate variables
    if [ -z "${CERT_P12_URL:-}" ] && [ -z "${CERT_CER_URL:-}" ] && [ -z "${CERT_KEY_URL:-}" ]; then
        missing_vars+=("CERT_P12_URL or CERT_CER_URL+CERT_KEY_URL")
    fi
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ All required environment variables are set${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing required environment variables:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "${RED}   - $var${NC}"
        done
        return 1
    fi
}

# Function to provide quick fixes
provide_quick_fixes() {
    echo -e "${BLUE}🔧 Quick Fixes for Certificate Issues${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}💡 Immediate actions you can take:${NC}"
    echo ""
    echo -e "${BLUE}1. Check your certificate URLs:${NC}"
    echo "   - Open the URLs in a browser to verify they're accessible"
    echo "   - Ensure the repository is public"
    echo "   - Check if the files exist at the specified paths"
    echo ""
    echo -e "${BLUE}2. Use alternative certificate format:${NC}"
    echo "   - If you have .cer and .key files, use those instead of .p12"
    echo "   - Set CERT_CER_URL and CERT_KEY_URL instead of CERT_P12_URL"
    echo ""
    echo -e "${BLUE}3. Upload certificates to a different location:${NC}"
    echo "   - Create a new public GitHub repository"
    echo "   - Upload your certificates there"
    echo "   - Use the raw URLs from the new repository"
    echo ""
    echo -e "${BLUE}4. Check certificate validity:${NC}"
    echo "   - Ensure certificates are not expired"
    echo "   - Verify the certificate password is correct"
    echo "   - Check if certificates match your provisioning profile"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}🔧 iOS App Store Certificate Fix${NC}"
    echo "====================================="
    echo ""
    
    # Validate environment variables
    if ! validate_environment; then
        echo -e "${RED}❌ Environment validation failed${NC}"
        echo -e "${YELLOW}💡 Please set the missing environment variables and try again${NC}"
        exit 1
    fi
    
    echo ""
    
    # Test current certificate URLs
    if ! test_current_certificates; then
        echo ""
        suggest_alternatives
        echo ""
        provide_quick_fixes
        echo ""
        create_sample_setup
        echo ""
        echo -e "${RED}❌ Certificate URLs are not accessible${NC}"
        echo -e "${YELLOW}💡 Please fix the certificate URLs and try again${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ Certificate URLs are accessible${NC}"
    echo -e "${BLUE}💡 The issue might be with the download process or certificate format${NC}"
    echo ""
    echo -e "${YELLOW}💡 Try running the enhanced code signing script again:${NC}"
    echo "   ./lib/scripts/ios-appstore/enhanced-code-signing.sh"
    echo ""
}

# Run main function
main "$@" 