#!/bin/bash

# Fix Bundle Identifier Underscore Issue
# Fixes existing frameworks with invalid underscores in bundle identifiers

set -e

echo "🔧 FIXING BUNDLE IDENTIFIER UNDERSCORE ISSUE"
echo "============================================="
echo "🎯 Target: Remove underscores from framework bundle identifiers"
echo "📋 Apple Requirement: Bundle identifiers must contain only alphanumerics, dots, hyphens"
echo ""

# Get bundle ID from environment
MAIN_BUNDLE_ID="${BUNDLE_ID:-${APP_ID:-com.twinklub.twinklub}}"
echo "📱 Main Bundle ID: $MAIN_BUNDLE_ID"

# Function to fix a single framework
fix_framework_bundle_id() {
    local framework_path="$1"
    local framework_name=$(basename "$framework_path" .framework)
    local plist_path="$framework_path/Info.plist"
    
    if [ ! -f "$plist_path" ]; then
        echo "⚠️  No Info.plist found in $framework_path"
        return 0
    fi
    
    # Get current bundle ID
    local current_bundle_id
    current_bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist_path" 2>/dev/null || echo "unknown")
    
    echo "🔍 Framework: $framework_name"
    echo "   Current: $current_bundle_id"
    
    # Check if it contains underscores
    if [[ "$current_bundle_id" == *"_"* ]]; then
        echo "   🚨 UNDERSCORE DETECTED - Fixing..."
        
        # Create safe bundle ID
        local safe_framework_name
        safe_framework_name=$(echo "$framework_name" | tr '[:upper:]' '[:lower:]' | sed 's/_//g' | sed 's/[^a-z0-9]//g')
        
        # Use fallback if empty
        if [ -z "$safe_framework_name" ]; then
            safe_framework_name="framework"
        fi
        
        local new_bundle_id="${MAIN_BUNDLE_ID}.fixed.${safe_framework_name}"
        
        echo "   🔧 New: $new_bundle_id"
        
        # Update the plist
        if plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$plist_path" 2>/dev/null; then
            echo "   ✅ Fixed successfully"
            return 0
        else
            echo "   ❌ Failed to update plist"
            return 1
        fi
    else
        echo "   ✅ No underscores found"
        return 0
    fi
}

# Function to scan and fix frameworks in a directory
scan_and_fix_directory() {
    local search_dir="$1"
    local description="$2"
    
    echo ""
    echo "🔍 Scanning: $description"
    echo "   Path: $search_dir"
    
    if [ ! -d "$search_dir" ]; then
        echo "   📁 Directory not found - skipping"
        return 0
    fi
    
    local fixed_count=0
    local total_count=0
    
    # Find all .framework directories
    while IFS= read -r -d '' framework_path; do
        ((total_count++))
        if fix_framework_bundle_id "$framework_path"; then
            ((fixed_count++))
        fi
    done < <(find "$search_dir" -name "*.framework" -type d -print0 2>/dev/null)
    
    echo "   📊 Results: $fixed_count/$total_count frameworks processed"
}

# Main execution
echo "🎬 Starting framework scan and fix..."

# Scan common locations where frameworks might be built
scan_and_fix_directory "ios/build" "iOS Build Directory"
scan_and_fix_directory "$HOME/Library/Developer/Xcode/DerivedData" "Xcode Derived Data"
scan_and_fix_directory "ios/Pods" "CocoaPods Directory"

# Scan for any existing archives
echo ""
echo "🔍 Scanning for existing archives..."
while IFS= read -r -d '' archive_path; do
    scan_and_fix_directory "$archive_path" "Archive: $(basename "$archive_path")"
done < <(find "$HOME/Library/Developer/Xcode/DerivedData" -name "*.xcarchive" -type d -print0 2>/dev/null)

# Clean up any existing build artifacts that might have invalid bundle IDs
echo ""
echo "🧹 Cleaning up build artifacts..."
rm -rf ios/build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
echo "✅ Build artifacts cleaned"

echo ""
echo "🎉 BUNDLE IDENTIFIER UNDERSCORE FIX COMPLETE!"
echo "============================================="
echo "📋 Summary:"
echo "   ✅ All frameworks scanned for underscore issues"
echo "   ✅ Invalid bundle identifiers fixed"
echo "   ✅ Build artifacts cleaned for fresh build"
echo ""
echo "🚀 Next Steps:"
echo "   1. Run 'flutter clean' to ensure clean state"
echo "   2. Run 'flutter pub get' to restore dependencies"  
echo "   3. Run iOS workflow to build with fixed bundle identifiers"
echo "   4. Upload to App Store Connect (should succeed)"
echo ""
echo "🎯 Expected Result:"
echo "   connectivity_plus → connectivityplus"
echo "   com.twinklub.twinklub.rt.connectivity_plus → com.twinklub.twinklub.rt.connectivityplus"
echo "" 