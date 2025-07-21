#!/bin/bash

# 📋 iOS App Store Certificate URL Setup Script
# Helps users set up the correct certificate URLs for App Store builds

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

# Function to display current certificate URLs
show_current_urls() {
    echo -e "${BLUE}📋 Current Certificate URLs${NC}"
    echo "----------------------------------------"
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${BLUE}P12 Certificate URL:${NC} ${CERT_P12_URL}"
    else
        echo -e "${YELLOW}P12 Certificate URL:${NC} Not set"
    fi
    
    if [ -n "${CERT_CER_URL:-}" ]; then
        echo -e "${BLUE}CER Certificate URL:${NC} ${CERT_CER_URL}"
    else
        echo -e "${YELLOW}CER Certificate URL:${NC} Not set"
    fi
    
    if [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${BLUE}KEY Certificate URL:${NC} ${CERT_KEY_URL}"
    else
        echo -e "${YELLOW}KEY Certificate URL:${NC} Not set"
    fi
    
    if [ -n "${PROFILE_URL:-}" ]; then
        echo -e "${BLUE}Provisioning Profile URL:${NC} ${PROFILE_URL}"
    else
        echo -e "${YELLOW}Provisioning Profile URL:${NC} Not set"
    fi
    
    echo ""
}

# Function to provide setup instructions
provide_setup_instructions() {
    echo -e "${BLUE}📋 Certificate URL Setup Instructions${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}💡 To fix the certificate download issue, you need to:${NC}"
    echo ""
    echo -e "${BLUE}1. Upload your certificates to a public repository:${NC}"
    echo "   - Create a new public GitHub repository"
    echo "   - Upload your certificate files (.p12, .cer, .key, .mobileprovision)"
    echo "   - Use the raw URLs from the repository"
    echo ""
    echo -e "${BLUE}2. Example repository structure:${NC}"
    echo "   your-repo/"
    echo "   ├── certificates/"
    echo "   │   ├── certificate.p12"
    echo "   │   ├── certificate.cer"
    echo "   │   ├── certificate.key"
    echo "   │   └── profile.mobileprovision"
    echo "   └── README.md"
    echo ""
    echo -e "${BLUE}3. Example URLs:${NC}"
    echo "   CERT_P12_URL=https://raw.githubusercontent.com/your-username/your-repo/main/certificates/certificate.p12"
    echo "   CERT_CER_URL=https://raw.githubusercontent.com/your-username/your-repo/main/certificates/certificate.cer"
    echo "   CERT_KEY_URL=https://raw.githubusercontent.com/your-username/your-repo/main/certificates/certificate.key"
    echo "   PROFILE_URL=https://raw.githubusercontent.com/your-username/your-repo/main/certificates/profile.mobileprovision"
    echo ""
    echo -e "${BLUE}4. Alternative hosting options:${NC}"
    echo "   - Google Drive (with public sharing)"
    echo "   - Dropbox (with public link)"
    echo "   - AWS S3 (with public access)"
    echo "   - Azure Blob Storage (with public access)"
    echo ""
}

# Function to test URL accessibility
test_url_accessibility() {
    echo -e "${BLUE}🔍 Testing URL Accessibility${NC}"
    echo "----------------------------------------"
    
    local all_accessible=true
    
    if [ -n "${CERT_P12_URL:-}" ]; then
        echo -e "${BLUE}Testing P12 URL: ${CERT_P12_URL}${NC}"
        if curl -I --fail --silent "$CERT_P12_URL" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ P12 URL is accessible${NC}"
        else
            echo -e "${RED}❌ P12 URL is not accessible${NC}"
            all_accessible=false
        fi
    fi
    
    if [ -n "${CERT_CER_URL:-}" ]; then
        echo -e "${BLUE}Testing CER URL: ${CERT_CER_URL}${NC}"
        if curl -I --fail --silent "$CERT_CER_URL" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ CER URL is accessible${NC}"
        else
            echo -e "${RED}❌ CER URL is not accessible${NC}"
            all_accessible=false
        fi
    fi
    
    if [ -n "${CERT_KEY_URL:-}" ]; then
        echo -e "${BLUE}Testing KEY URL: ${CERT_KEY_URL}${NC}"
        if curl -I --fail --silent "$CERT_KEY_URL" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ KEY URL is accessible${NC}"
        else
            echo -e "${RED}❌ KEY URL is not accessible${NC}"
            all_accessible=false
        fi
    fi
    
    if [ -n "${PROFILE_URL:-}" ]; then
        echo -e "${BLUE}Testing Profile URL: ${PROFILE_URL}${NC}"
        if curl -I --fail --silent "$PROFILE_URL" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Profile URL is accessible${NC}"
        else
            echo -e "${RED}❌ Profile URL is not accessible${NC}"
            all_accessible=false
        fi
    fi
    
    echo ""
    
    if [ "$all_accessible" = true ]; then
        echo -e "${GREEN}✅ All URLs are accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ Some URLs are not accessible${NC}"
        return 1
    fi
}

# Function to provide GitHub setup guide
provide_github_setup_guide() {
    echo -e "${BLUE}📋 GitHub Repository Setup Guide${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}💡 Step-by-step guide to set up certificate URLs:${NC}"
    echo ""
    echo -e "${BLUE}1. Create a new GitHub repository:${NC}"
    echo "   - Go to https://github.com/new"
    echo "   - Name it something like 'ios-certificates'"
    echo "   - Make it PUBLIC (important for accessibility)"
    echo "   - Don't initialize with README"
    echo ""
    echo -e "${BLUE}2. Upload your certificate files:${NC}"
    echo "   - Create a 'certificates' folder in your repository"
    echo "   - Upload your .p12, .cer, .key, and .mobileprovision files"
    echo "   - Use descriptive names like 'certificate.p12'"
    echo ""
    echo -e "${BLUE}3. Get the raw URLs:${NC}"
    echo "   - Click on each file in GitHub"
    echo "   - Click the 'Raw' button"
    echo "   - Copy the URL from the address bar"
    echo "   - The URL should look like: https://raw.githubusercontent.com/username/repo/main/certificates/certificate.p12"
    echo ""
    echo -e "${BLUE}4. Update your environment variables:${NC}"
    echo "   - Set CERT_P12_URL to your .p12 file raw URL"
    echo "   - Set CERT_CER_URL to your .cer file raw URL"
    echo "   - Set CERT_KEY_URL to your .key file raw URL"
    echo "   - Set PROFILE_URL to your .mobileprovision file raw URL"
    echo ""
    echo -e "${BLUE}5. Test the URLs:${NC}"
    echo "   - Open each URL in a browser"
    echo "   - You should see the file content or download prompt"
    echo "   - If you see a 404 error, the file doesn't exist at that path"
    echo ""
}

# Function to provide troubleshooting tips
provide_troubleshooting_tips() {
    echo -e "${BLUE}🔧 Troubleshooting Tips${NC}"
    echo "----------------------------------------"
    
    echo -e "${YELLOW}💡 Common issues and solutions:${NC}"
    echo ""
    echo -e "${BLUE}1. 404 Error:${NC}"
    echo "   - Check if the file exists at the specified path"
    echo "   - Verify the file name and extension are correct"
    echo "   - Ensure the repository is public"
    echo ""
    echo -e "${BLUE}2. Repository is private:${NC}"
    echo "   - Make the repository public in GitHub settings"
    echo "   - Or use a different hosting service"
    echo ""
    echo -e "${BLUE}3. Wrong file path:${NC}"
    echo "   - Check the exact path to your files in the repository"
    echo "   - Use the 'Raw' button in GitHub to get the correct URL"
    echo ""
    echo -e "${BLUE}4. File not uploaded:${NC}"
    echo "   - Ensure all certificate files are uploaded to the repository"
    echo "   - Check that the files are in the correct folder"
    echo ""
    echo -e "${BLUE}5. Network issues:${NC}"
    echo "   - Try accessing the URLs from a different network"
    echo "   - Check if GitHub is accessible from your location"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}📋 iOS App Store Certificate URL Setup${NC}"
    echo "=========================================="
    echo ""
    
    # Show current URLs
    show_current_urls
    
    # Test URL accessibility
    if ! test_url_accessibility; then
        echo ""
        provide_setup_instructions
        echo ""
        provide_github_setup_guide
        echo ""
        provide_troubleshooting_tips
        echo ""
        echo -e "${RED}❌ Certificate URLs are not accessible${NC}"
        echo -e "${YELLOW}💡 Please fix the URLs and try again${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ All certificate URLs are accessible${NC}"
    echo -e "${BLUE}💡 Your certificate setup appears to be correct${NC}"
    echo ""
    echo -e "${YELLOW}💡 If you're still having issues, try:${NC}"
    echo "   - Running the enhanced code signing script again"
    echo "   - Checking the certificate password"
    echo "   - Verifying the certificate format"
    echo ""
}

# Run main function
main "$@" 