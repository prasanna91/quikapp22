#!/bin/bash

# 🔧 iOS New Workflow - Main Script
# Comprehensive script for iOS workflow setup, branding, and bundle identifier reporting

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

# Logging functions
log_info() { echo "ℹ️ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
log_success() { echo "✅ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
log_warn() { echo "⚠️ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
log_error() { echo "❌ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

echo ""
echo "🚀 iOS New Workflow - Main Script"
echo "================================================================="
log_info "Starting iOS New Workflow execution..."

# Function to set script permissions (already handled by workflow)
set_script_permissions() {
    log_info "🔧 Verifying script permissions..."
    
    # Check if current script is executable
    if [ -x "$0" ]; then
        log_success "✅ Current script is executable"
    else
        log_warn "⚠️ Current script is not executable, attempting to fix..."
        chmod +x "$0"
        if [ -x "$0" ]; then
            log_success "✅ Script permissions fixed"
        else
            log_error "❌ Failed to set script permissions"
            return 1
        fi
    fi
    
    log_success "✅ Script permissions verified"
}

# Function to setup environment
setup_environment() {
    log_info "🔧 Setting up environment..."
    
    # Display environment information
    log_info "📊 Environment Information:"
    log_info "   - Flutter: $(flutter --version | head -1)"
    log_info "   - Java: $(java -version 2>&1 | head -1)"
    log_info "   - Xcode: $(xcodebuild -version | head -1)"
    log_info "   - CocoaPods: $(pod --version)"
    log_info "   - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
    log_info "   - Working Directory: $(pwd)"
    
    # Set environment variables
    export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
    export ANDROID_ROOT="${ANDROID_ROOT:-android}"
    export ASSETS_DIR="${ASSETS_DIR:-assets}"
    export OUTPUT_DIR="${OUTPUT_DIR:-output/ios}"
    export TEMP_DIR="${TEMP_DIR:-temp}"
    
    # Create necessary directories
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$TEMP_DIR"
    mkdir -p "assets/images"
    
    log_success "✅ Environment setup completed"
}

# Function to clear previous residue
clear_previous_residue() {
    log_info "🧹 Clearing previous residue..."
    
    # Clear Flutter residue
    log_info "   🔄 Clearing Flutter residue..."
    flutter clean 2>/dev/null || true
    rm -rf .dart_tool/ 2>/dev/null || true
    rm -rf build/ 2>/dev/null || true
    rm -rf .flutter-plugins 2>/dev/null || true
    rm -rf .flutter-plugins-dependencies 2>/dev/null || true
    
    # Clear iOS residue
    log_info "   🔄 Clearing iOS residue..."
    rm -rf ios/Pods/ 2>/dev/null || true
    rm -rf ios/build/ 2>/dev/null || true
    rm -rf ios/DerivedData/ 2>/dev/null || true
    rm -rf ios/Runner.xcworkspace/xcuserdata/ 2>/dev/null || true
    rm -rf ios/Runner.xcodeproj/xcuserdata/ 2>/dev/null || true
    rm -rf ios/Runner.xcodeproj/project.xcworkspace/xcuserdata/ 2>/dev/null || true
    
    # Clear CocoaPods residue
    log_info "   🔄 Clearing CocoaPods residue..."
    rm -rf ~/.cocoapods/ 2>/dev/null || true
    rm -rf ios/Podfile.lock 2>/dev/null || true
    
    # Clear output directories
    log_info "   🔄 Clearing output directories..."
    rm -rf output/ios/ 2>/dev/null || true
    rm -rf build/ios/ 2>/dev/null || true
    
    log_success "✅ Previous residue cleared successfully"
}

# Function to setup branding from environment variables
setup_branding() {
    log_info "🎨 Setting up branding from environment variables..."
    
    # Create assets directory if it doesn't exist
    mkdir -p assets/images
    
    # Download logo if LOGO_URL is provided
    if [ -n "${LOGO_URL:-}" ]; then
        log_info "📥 Downloading logo from: $LOGO_URL"
        if curl -fsSL -o "assets/images/logo.png" "$LOGO_URL" 2>/dev/null; then
            log_success "✅ Logo downloaded successfully"
        else
            log_warn "⚠️ Failed to download logo, using default"
        fi
    else
        log_info "ℹ️ No LOGO_URL provided, skipping logo download"
    fi
    
    # Download splash image if SPLASH_URL is provided
    if [ -n "${SPLASH_URL:-}" ]; then
        log_info "📥 Downloading splash image from: $SPLASH_URL"
        if curl -fsSL -o "assets/images/splash.png" "$SPLASH_URL" 2>/dev/null; then
            log_success "✅ Splash image downloaded successfully"
        else
            log_warn "⚠️ Failed to download splash image, using default"
        fi
    else
        log_info "ℹ️ No SPLASH_URL provided, skipping splash image download"
    fi
    
    # Download splash background if SPLASH_BG_URL is provided
    if [ -n "${SPLASH_BG_URL:-}" ]; then
        log_info "📥 Downloading splash background from: $SPLASH_BG_URL"
        if curl -fsSL -o "assets/images/splash_bg.png" "$SPLASH_BG_URL" 2>/dev/null; then
            log_success "✅ Splash background downloaded successfully"
        else
            log_warn "⚠️ Failed to download splash background, using default"
        fi
    else
        log_info "ℹ️ No SPLASH_BG_URL provided, skipping splash background download"
    fi
    
    # Display branding information
    log_info "📋 Branding Information:"
    log_info "   - App Name: ${APP_NAME:-Not set}"
    log_info "   - Bundle ID: ${BUNDLE_ID:-Not set}"
    log_info "   - Logo URL: ${LOGO_URL:-Not set}"
    log_info "   - Splash URL: ${SPLASH_URL:-Not set}"
    log_info "   - Splash BG URL: ${SPLASH_BG_URL:-Not set}"
    
    log_success "✅ Branding setup completed"
}

# Function to run Flutter commands
run_flutter_commands() {
    log_info "📦 Running Flutter commands..."
    
    # Run flutter pub get
    log_info "🔄 Running: flutter pub get"
    if flutter pub get; then
        log_success "✅ flutter pub get completed successfully"
    else
        log_error "❌ flutter pub get failed"
        return 1
    fi
    
    # Run flutter analyze (optional)
    log_info "🔍 Running: flutter analyze"
    flutter analyze || log_warn "⚠️ flutter analyze had issues (continuing)"
    
    log_success "✅ Flutter commands completed"
}

# Function to run CocoaPods commands
run_cocoapods_commands() {
    log_info "📦 Running CocoaPods commands..."
    
    # Navigate to iOS directory
    cd ios
    
    # Run pod install
    log_info "🔄 Running: pod install"
    if pod install; then
        log_success "✅ pod install completed successfully"
    else
        log_error "❌ pod install failed"
        return 1
    fi
    
    # Run pod update (optional)
    log_info "🔄 Running: pod update"
    pod update || log_warn "⚠️ pod update had issues (continuing)"
    
    # Navigate back to project root
    cd ..
    
    log_success "✅ CocoaPods commands completed"
}

# Function to echo bundle identifiers for all frameworks and target
echo_bundle_identifiers() {
    log_info "📱 Echoing bundle identifiers for all frameworks and target..."
    
    echo ""
    echo "🎯 BUNDLE IDENTIFIERS REPORT"
    echo "================================================================="
    
    # Get main app bundle identifier
    if [ -f "ios/Runner/Info.plist" ]; then
        local main_bundle_id=$(plutil -extract CFBundleIdentifier raw "ios/Runner/Info.plist" 2>/dev/null || echo "NOT_FOUND")
        echo "📱 Main App Bundle ID: $main_bundle_id"
    else
        echo "❌ Main app Info.plist not found"
    fi
    
    # Get bundle identifier from project.pbxproj
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        echo ""
        echo "🏗️ Xcode Project Bundle Identifiers:"
        grep -o "PRODUCT_BUNDLE_IDENTIFIER = [^;]*;" "ios/Runner.xcodeproj/project.pbxproj" | while read -r line; do
            echo "   $line"
        done
    else
        echo "❌ Xcode project file not found"
    fi
    
    # Get CocoaPods bundle identifiers
    if [ -d "ios/Pods" ]; then
        echo ""
        echo "📦 CocoaPods Framework Bundle Identifiers:"
        find "ios/Pods" -name "Info.plist" -path "*/Headers/*" | while read -r plist; do
            local framework_name=$(echo "$plist" | sed 's|.*Pods/\([^/]*\).*|\1|')
            local bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "NOT_FOUND")
            echo "   📦 $framework_name: $bundle_id"
        done
    else
        echo "ℹ️ CocoaPods directory not found (run 'pod install' first)"
    fi
    
    # Get installed frameworks bundle identifiers
    if [ -d "ios/Pods" ]; then
        echo ""
        echo "🔧 Installed Framework Bundle Identifiers:"
        find "ios/Pods" -name "*.framework" -type d | while read -r framework; do
            local framework_name=$(basename "$framework" .framework)
            local plist="$framework/Info.plist"
            if [ -f "$plist" ]; then
                local bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || echo "NOT_FOUND")
                echo "   🔧 $framework_name: $bundle_id"
            fi
        done
    fi
    
    # Get Podfile.lock information
    if [ -f "ios/Podfile.lock" ]; then
        echo ""
        echo "📋 Podfile.lock Information:"
        echo "   📄 Podfile.lock exists"
        local pod_count=$(grep -c "PODS:" "ios/Podfile.lock" 2>/dev/null || echo "0")
        echo "   📊 Total pods: $pod_count"
    else
        echo "ℹ️ Podfile.lock not found (run 'pod install' first)"
    fi
    
    echo ""
    echo "================================================================="
    log_success "✅ Bundle identifiers report completed"
}

# Function to display environment variables
display_environment_variables() {
    log_info "📋 Displaying relevant environment variables..."
    
    echo ""
    echo "🔧 ENVIRONMENT VARIABLES"
    echo "================================================================="
    
    # App configuration
    echo "📱 App Configuration:"
    echo "   APP_ID: ${APP_ID:-Not set}"
    echo "   APP_NAME: ${APP_NAME:-Not set}"
    echo "   BUNDLE_ID: ${BUNDLE_ID:-Not set}"
    echo "   VERSION_NAME: ${VERSION_NAME:-Not set}"
    echo "   VERSION_CODE: ${VERSION_CODE:-Not set}"
    
    # Branding configuration
    echo ""
    echo "🎨 Branding Configuration:"
    echo "   LOGO_URL: ${LOGO_URL:-Not set}"
    echo "   SPLASH_URL: ${SPLASH_URL:-Not set}"
    echo "   SPLASH_BG_URL: ${SPLASH_BG_URL:-Not set}"
    echo "   SPLASH_BG_COLOR: ${SPLASH_BG_COLOR:-Not set}"
    echo "   SPLASH_TAGLINE: ${SPLASH_TAGLINE:-Not set}"
    
    # Feature flags
    echo ""
    echo "🔧 Feature Flags:"
    echo "   IS_CHATBOT: ${IS_CHATBOT:-Not set}"
    echo "   IS_SPLASH: ${IS_SPLASH:-Not set}"
    echo "   IS_PULLDOWN: ${IS_PULLDOWN:-Not set}"
    echo "   IS_BOTTOMMENU: ${IS_BOTTOMMENU:-Not set}"
    echo "   IS_LOAD_IND: ${IS_LOAD_IND:-Not set}"
    echo "   IS_DOMAIN_URL: ${IS_DOMAIN_URL:-Not set}"
    echo "   PUSH_NOTIFY: ${PUSH_NOTIFY:-Not set}"
    
    # Permissions
    echo ""
    echo "🔐 Permissions:"
    echo "   IS_CAMERA: ${IS_CAMERA:-Not set}"
    echo "   IS_LOCATION: ${IS_LOCATION:-Not set}"
    echo "   IS_MIC: ${IS_MIC:-Not set}"
    echo "   IS_NOTIFICATION: ${IS_NOTIFICATION:-Not set}"
    echo "   IS_CONTACT: ${IS_CONTACT:-Not set}"
    echo "   IS_BIOMETRIC: ${IS_BIOMETRIC:-Not set}"
    echo "   IS_CALENDAR: ${IS_CALENDAR:-Not set}"
    echo "   IS_STORAGE: ${IS_STORAGE:-Not set}"
    
    # Build configuration
    echo ""
    echo "🏗️ Build Configuration:"
    echo "   WORKFLOW_ID: ${WORKFLOW_ID:-Not set}"
    echo "   OUTPUT_DIR: ${OUTPUT_DIR:-Not set}"
    echo "   PROJECT_ROOT: ${PROJECT_ROOT:-Not set}"
    
    echo ""
    echo "================================================================="
}

# Main execution function
main() {
    log_info "🚀 Starting iOS New Workflow..."
    
    # Step 1: Set script permissions
    set_script_permissions
    
    # Step 2: Setup environment
    setup_environment
    
    # Step 3: Clear previous residue
    clear_previous_residue
    
    # Step 4: Setup branding
    setup_branding
    
    # Step 5: Display environment variables
    display_environment_variables
    
    # Step 6: Run Flutter commands
    run_flutter_commands
    
    # Step 7: Run CocoaPods commands
    run_cocoapods_commands
    
    # Step 8: Echo bundle identifiers
    echo_bundle_identifiers
    
    log_success "🎉 iOS New Workflow completed successfully!"
    log_info "📱 Bundle identifiers have been reported"
    log_info "📦 Flutter and CocoaPods dependencies installed"
    log_info "🎨 Branding assets downloaded"
    log_info "🧹 Previous residue cleared"
    
    echo ""
    echo "✅ WORKFLOW COMPLETED SUCCESSFULLY!"
    echo "================================================================="
}

# Execute main function
main "$@" 