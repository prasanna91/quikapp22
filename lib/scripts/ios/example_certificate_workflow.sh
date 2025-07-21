#!/bin/bash

# Example Certificate Workflow Script
# Purpose: Demonstrate how to use the comprehensive certificate validation
# Author: AI Assistant
# Version: 1.0

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

log_info() { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_warn() { echo "⚠️ $1"; }
log_error() { echo "❌ $1"; }

log_info "📚 Example Certificate Workflow Script"
log_info "This script demonstrates how to use the comprehensive certificate validation"

# Function to show usage
show_usage() {
    cat << EOF

🔒 Comprehensive Certificate Validation Workflow

This workflow handles certificate validation and code signing for iOS IPA export.

📋 Required Environment Variables:

1. Certificate Variables (Choose ONE option):
   
   Option A - P12 File:
   - CERT_P12_URL: URL to your .p12 certificate file
   - CERT_PASSWORD: Password for the .p12 file
   
   Option B - CER + KEY Files:
   - CERT_CER_URL: URL to your .cer certificate file
   - CERT_KEY_URL: URL to your .key private key file
   (Will generate P12 with default password: Password@1234)

2. App Store Connect API Variables:
   - APP_STORE_CONNECT_API_KEY_PATH: URL to your .p8 API key file
   - APP_STORE_CONNECT_KEY_IDENTIFIER: Your API key ID
   - APP_STORE_CONNECT_ISSUER_ID: Your issuer ID

3. Provisioning Profile:
   - PROFILE_URL: URL to your .mobileprovision file

4. App Configuration:
   - BUNDLE_ID: Your app's bundle identifier
   - PROFILE_TYPE: app-store, ad-hoc, enterprise, or development (default: app-store)

📝 Usage Examples:

Example 1: Using P12 file
export CERT_P12_URL="https://example.com/certificate.p12"
export CERT_PASSWORD="your_password"
export APP_STORE_CONNECT_API_KEY_PATH="https://example.com/AuthKey.p8"
export APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
export PROFILE_URL="https://example.com/profile.mobileprovision"
export BUNDLE_ID="com.example.app"
export PROFILE_TYPE="app-store"

Example 2: Using CER + KEY files
export CERT_CER_URL="https://example.com/certificate.cer"
export CERT_KEY_URL="https://example.com/private.key"
export APP_STORE_CONNECT_API_KEY_PATH="https://example.com/AuthKey.p8"
export APP_STORE_CONNECT_KEY_IDENTIFIER="YOUR_KEY_ID"
export APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"
export PROFILE_URL="https://example.com/profile.mobileprovision"
export BUNDLE_ID="com.example.app"
export PROFILE_TYPE="ad-hoc"

🚀 Running the Workflow:

1. Certificate Validation Only:
   ./lib/scripts/ios/comprehensive_certificate_validation.sh

2. Full IPA Export with Certificate Validation:
   ./lib/scripts/ios/ipa_export_with_certificate_validation.sh

📊 What the Workflow Does:

1. Downloads and validates certificate files
2. Sets up dedicated keychain for certificates
3. Installs certificates with proper permissions
4. Validates App Store Connect API credentials
5. Extracts UUID from mobileprovision file
6. Creates ExportOptions.plist with UUID
7. Builds and archives the app
8. Exports IPA from archive
9. Optionally uploads to App Store Connect

🔧 Troubleshooting:

- If P12 validation fails, check the password
- If CER+KEY conversion fails, ensure files are valid
- If API key download fails, check the URL
- If UUID extraction fails, check mobileprovision file
- If IPA export fails, check bundle identifier match

EOF
}

# Function to run example with P12 file
run_p12_example() {
    log_info "🔧 Running P12 File Example..."
    
    # Set example environment variables for P12
    export CERT_P12_URL="https://example.com/certificate.p12"
    export CERT_PASSWORD="example_password"
    export APP_STORE_CONNECT_API_KEY_PATH="https://example.com/AuthKey.p8"
    export APP_STORE_CONNECT_KEY_IDENTIFIER="EXAMPLE_KEY_ID"
    export APP_STORE_CONNECT_ISSUER_ID="example-issuer-id"
    export PROFILE_URL="https://example.com/profile.mobileprovision"
    export BUNDLE_ID="com.example.app"
    export PROFILE_TYPE="app-store"
    
    log_info "📋 Example P12 Configuration:"
    log_info "   - CERT_P12_URL: $CERT_P12_URL"
    log_info "   - CERT_PASSWORD: $CERT_PASSWORD"
    log_info "   - BUNDLE_ID: $BUNDLE_ID"
    log_info "   - PROFILE_TYPE: $PROFILE_TYPE"
    
    log_warn "⚠️ This is an example - replace URLs with your actual certificate URLs"
    log_info "💡 To run with real certificates, set the environment variables and run:"
    log_info "   ./lib/scripts/ios/comprehensive_certificate_validation.sh"
}

# Function to run example with CER + KEY files
run_cer_key_example() {
    log_info "🔧 Running CER + KEY Files Example..."
    
    # Set example environment variables for CER + KEY
    export CERT_CER_URL="https://example.com/certificate.cer"
    export CERT_KEY_URL="https://example.com/private.key"
    export APP_STORE_CONNECT_API_KEY_PATH="https://example.com/AuthKey.p8"
    export APP_STORE_CONNECT_KEY_IDENTIFIER="EXAMPLE_KEY_ID"
    export APP_STORE_CONNECT_ISSUER_ID="example-issuer-id"
    export PROFILE_URL="https://example.com/profile.mobileprovision"
    export BUNDLE_ID="com.example.app"
    export PROFILE_TYPE="ad-hoc"
    
    log_info "📋 Example CER + KEY Configuration:"
    log_info "   - CERT_CER_URL: $CERT_CER_URL"
    log_info "   - CERT_KEY_URL: $CERT_KEY_URL"
    log_info "   - BUNDLE_ID: $BUNDLE_ID"
    log_info "   - PROFILE_TYPE: $PROFILE_TYPE"
    log_info "   - Default P12 Password: Password@1234"
    
    log_warn "⚠️ This is an example - replace URLs with your actual certificate URLs"
    log_info "💡 To run with real certificates, set the environment variables and run:"
    log_info "   ./lib/scripts/ios/comprehensive_certificate_validation.sh"
}

# Function to show validation steps
show_validation_steps() {
    log_info "🔍 Certificate Validation Steps:"
    
    cat << EOF

1. 📥 Download Certificate Files
   - Downloads P12, CER, KEY, or mobileprovision files from URLs
   - Validates file integrity and size
   - Retries failed downloads

2. 🔐 Setup Keychain
   - Creates dedicated iOS build keychain
   - Configures keychain settings
   - Sets proper permissions

3. 🔍 Validate P12 Certificate
   - Tests P12 file with provided password
   - Supports both legacy and modern OpenSSL modes
   - Validates certificate format

4. 🔄 Convert CER + KEY to P12 (if needed)
   - Combines CER and KEY files into P12 format
   - Uses default password: Password@1234
   - Validates converted P12 file

5. 📦 Install Certificate
   - Imports certificate into keychain
   - Sets key partition list for access
   - Configures code signing permissions

6. 🔐 Validate App Store Connect API
   - Downloads and validates .p8 API key
   - Checks API key format and permissions
   - Prepares for App Store Connect upload

7. 📱 Process Provisioning Profile
   - Downloads mobileprovision file
   - Extracts UUID using security and plutil
   - Installs profile in correct location

8. ✅ Validate Code Signing
   - Checks for code signing identities
   - Verifies iOS distribution certificates
   - Confirms signing capability

9. 📝 Create Export Configuration
   - Generates ExportOptions.plist with UUID
   - Configures for specified profile type
   - Sets up manual signing with UUID

10. 🏗️ Build and Archive
    - Cleans and builds Flutter app
    - Creates Xcode archive
    - Prepares for IPA export

11. 📱 Export IPA
    - Exports IPA from archive
    - Uses UUID-based signing
    - Creates final IPA file

12. ☁️ Upload (Optional)
    - Uploads to App Store Connect
    - Uses API key authentication
    - Handles upload verification

EOF
}

# Function to show error handling
show_error_handling() {
    log_info "🚨 Error Handling and Troubleshooting:"
    
    cat << EOF

❌ Common Errors and Solutions:

1. "No code signing data provided"
   - Ensure either CERT_P12_URL or CERT_CER_URL+CERT_KEY_URL is set
   - Check that URLs are accessible

2. "P12 certificate validation failed"
   - Verify CERT_PASSWORD is correct
   - Check P12 file is not corrupted
   - Try different password formats

3. "Failed to convert CER+KEY to P12"
   - Ensure CER and KEY files are valid
   - Check file permissions
   - Verify OpenSSL is installed

4. "Failed to download API key"
   - Check APP_STORE_CONNECT_API_KEY_PATH URL
   - Verify network connectivity
   - Ensure API key file exists

5. "Failed to extract UUID from mobileprovision"
   - Check PROFILE_URL is accessible
   - Verify mobileprovision file is valid
   - Ensure security and plutil tools are available

6. "No code signing identities found"
   - Verify certificate installation succeeded
   - Check keychain permissions
   - Ensure certificate is for iOS distribution

7. "Failed to export IPA from archive"
   - Check bundle identifier matches provisioning profile
   - Verify ExportOptions.plist is correct
   - Ensure archive was created successfully

🔧 Debug Commands:

# Check certificate installation
security find-identity -v -p codesigning ios-build.keychain

# Validate P12 file
openssl pkcs12 -in certificate.p12 -noout -passin pass:your_password

# Extract mobileprovision UUID
security cms -D -i profile.mobileprovision | plutil -extract UUID xml1 -o - -

# Check provisioning profiles
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# Validate ExportOptions.plist
plutil -lint ios/export_options/ExportOptions.plist

EOF
}

# Main function
main() {
    case "${1:-help}" in
        "help"|"-h"|"--help")
            show_usage
            ;;
        "p12"|"p12-example")
            run_p12_example
            ;;
        "cer-key"|"cer-key-example")
            run_cer_key_example
            ;;
        "steps"|"validation-steps")
            show_validation_steps
            ;;
        "errors"|"troubleshooting")
            show_error_handling
            ;;
        *)
            log_error "❌ Unknown option: $1"
            log_info "💡 Use 'help' to see available options"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 