#!/usr/bin/env bash

# GoogleUtilities Podspec Fix
# This script fixes the GoogleUtilities podspec to prevent file reference errors

set -e

echo "🔧 [PODSPEC_FIX] GoogleUtilities Podspec Fix"
echo "🔍 [PODSPEC_FIX] Fixing GoogleUtilities podspec to prevent file reference errors"

# Change to iOS directory
cd ios

# Check if we have CocoaPods cache
if [ -d "$HOME/.cocoapods/repos/trunk/Specs" ]; then
    COCOAPODS_SPECS_DIR="$HOME/.cocoapods/repos/trunk/Specs"
elif [ -d "$HOME/.cocoapods/repos/master/Specs" ]; then
    COCOAPODS_SPECS_DIR="$HOME/.cocoapods/repos/master/Specs"
else
    echo "ℹ️ [PODSPEC_FIX] CocoaPods specs not found, will fix after download"
    cd ..
    return 0
fi

# Find GoogleUtilities podspec
GOOGLE_UTILS_PODSPEC=$(find "$COCOAPODS_SPECS_DIR" -name "GoogleUtilities.podspec.json" -path "*/8.1.0/*" | head -1)

if [ -n "$GOOGLE_UTILS_PODSPEC" ]; then
    echo "🔍 [PODSPEC_FIX] Found GoogleUtilities podspec: $GOOGLE_UTILS_PODSPEC"
    
    # Create a backup
    cp "$GOOGLE_UTILS_PODSPEC" "$GOOGLE_UTILS_PODSPEC.backup"
    
    # Fix the podspec by removing problematic header file references
    python3 << 'EOF'
import json
import sys

try:
    # Read the podspec
    with open(sys.argv[1], 'r') as f:
        podspec = json.load(f)
    
    print("🔧 [PODSPEC_FIX] Modifying GoogleUtilities podspec...")
    
    # Remove problematic public_header_files patterns
    if 'public_header_files' in podspec:
        original_headers = podspec['public_header_files']
        print(f"  🔍 [PODSPEC_FIX] Original public headers: {original_headers}")
        
        # Filter out problematic patterns
        if isinstance(original_headers, list):
            podspec['public_header_files'] = [h for h in original_headers if 'Public/GoogleUtilities' not in h]
        elif isinstance(original_headers, str):
            if 'Public/GoogleUtilities' in original_headers:
                podspec['public_header_files'] = "GoogleUtilities/**/*.h"
        
        print(f"  ✅ [PODSPEC_FIX] Updated public headers: {podspec['public_header_files']}")
    
    # Check subspecs
    if 'subspecs' in podspec:
        for subspec in podspec['subspecs']:
            if 'public_header_files' in subspec:
                original_headers = subspec['public_header_files']
                print(f"  🔍 [PODSPEC_FIX] Subspec {subspec.get('name', 'unknown')} headers: {original_headers}")
                
                # Filter out problematic patterns
                if isinstance(original_headers, list):
                    subspec['public_header_files'] = [h for h in original_headers if 'Public/GoogleUtilities' not in h]
                elif isinstance(original_headers, str):
                    if 'Public/GoogleUtilities' in original_headers:
                        subspec_name = subspec.get('name', 'Unknown')
                        subspec['public_header_files'] = f"GoogleUtilities/{subspec_name}/**/*.h"
                
                print(f"  ✅ [PODSPEC_FIX] Updated subspec headers: {subspec['public_header_files']}")
    
    # Write the modified podspec
    with open(sys.argv[1], 'w') as f:
        json.dump(podspec, f, indent=2)
    
    print("✅ [PODSPEC_FIX] GoogleUtilities podspec modified successfully")
    
except Exception as e:
    print(f"❌ [PODSPEC_FIX] Error modifying podspec: {e}")
    sys.exit(1)
EOF "$GOOGLE_UTILS_PODSPEC"

    echo "✅ [PODSPEC_FIX] GoogleUtilities podspec fix completed"
else
    echo "ℹ️ [PODSPEC_FIX] GoogleUtilities podspec not found in cache"
fi

cd ..
echo "✅ [PODSPEC_FIX] Podspec fix process completed" 