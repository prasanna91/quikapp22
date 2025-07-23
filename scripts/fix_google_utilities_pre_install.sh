#!/usr/bin/env bash

# GoogleUtilities Pre-Install Header Fix
# This script fixes GoogleUtilities header files BEFORE CocoaPods installation
# to prevent file reference errors during pod install

set -e

echo "🔧 [PRE_INSTALL] GoogleUtilities Pre-Install Header Fix"
echo "🔍 [PRE_INSTALL] This script runs BEFORE pod install to prevent file reference errors"

# Check if we're in the iOS directory
if [ ! -d "ios" ]; then
    echo "❌ [PRE_INSTALL] Error: Not in iOS directory"
    exit 1
fi

cd ios

# Check if Pods directory exists (from previous install)
if [ -d "Pods/GoogleUtilities" ]; then
    echo "🔍 [PRE_INSTALL] Found existing GoogleUtilities pod, fixing headers..."
    
    GOOGLE_UTILITIES_PATH="Pods/GoogleUtilities"
    
    # Define the problematic headers and their expected locations
    declare -a header_names=(
        "IsAppEncrypted.h"
        "GULUserDefaults.h"
        "GULSceneDelegateSwizzler.h"
        "GULReachabilityChecker.h"
        "GULNetworkURLSession.h"
        "GULAppDelegateSwizzler.h"
        "GULApplication.h"
        "GULReachabilityChecker+Internal.h"
        "GULReachabilityMessageCode.h"
        "GULNetwork.h"
        "GULNetworkConstants.h"
        "GULNetworkLoggerProtocol.h"
        "GULNetworkMessageCode.h"
        "GULMutableDictionary.h"
        "GULNetworkInternal.h"
        "GULLogger.h"
        "GULLoggerLevel.h"
        "GULLoggerCodes.h"
        "GULAppEnvironmentUtil.h"
        "GULKeychainStorage.h"
        "GULKeychainUtils.h"
        "GULNetworkInfo.h"
        "GULNSData+zlib.h"
        "GULAppDelegateSwizzler_Private.h"
        "GULSceneDelegateSwizzler_Private.h"
    )
    
    declare -a expected_paths=(
        "third_party/IsAppEncrypted/Public/IsAppEncrypted.h"
        "GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"
        "GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULSceneDelegateSwizzler.h"
        "GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkURLSession.h"
        "GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULAppDelegateSwizzler.h"
        "GoogleUtilities/AppDelegateSwizzler/Public/GoogleUtilities/GULApplication.h"
        "GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityChecker+Internal.h"
        "GoogleUtilities/Reachability/Public/GoogleUtilities/GULReachabilityMessageCode.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetwork.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkConstants.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkLoggerProtocol.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkMessageCode.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULMutableDictionary.h"
        "GoogleUtilities/Network/Public/GoogleUtilities/GULNetworkInternal.h"
        "GoogleUtilities/Logger/Public/GoogleUtilities/GULLogger.h"
        "GoogleUtilities/Logger/Public/GoogleUtilities/GULLoggerLevel.h"
        "GoogleUtilities/Common/Public/GoogleUtilities/GULLoggerCodes.h"
        "GoogleUtilities/Environment/Public/GoogleUtilities/GULAppEnvironmentUtil.h"
        "GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainStorage.h"
        "GoogleUtilities/Environment/Public/GoogleUtilities/GULKeychainUtils.h"
        "GoogleUtilities/Environment/Public/GoogleUtilities/GULNetworkInfo.h"
        "GoogleUtilities/NSData+zlib/Public/GoogleUtilities/GULNSData+zlib.h"
        "GoogleUtilities/AppDelegateSwizzler/Internal/Public/GoogleUtilities/GULAppDelegateSwizzler_Private.h"
        "GoogleUtilities/AppDelegateSwizzler/Internal/Public/GoogleUtilities/GULSceneDelegateSwizzler_Private.h"
    )
    
    echo "🔍 [PRE_INSTALL] Processing ${#header_names[@]} headers..."
    
    # Process each header
    for i in "${!header_names[@]}"; do
        header_name="${header_names[$i]}"
        expected_path="${expected_paths[$i]}"
        
        echo "🔍 [PRE_INSTALL] Processing ${header_name}..."
        
        # Find the actual header file
        actual_header=$(find "$GOOGLE_UTILITIES_PATH" -name "$header_name" -type f 2>/dev/null | head -1)
        
        if [ -n "$actual_header" ]; then
            echo "  ✅ [PRE_INSTALL] Found ${header_name} at: ${actual_header}"
            
            # Create target directory
            target_dir="$GOOGLE_UTILITIES_PATH/$(dirname "$expected_path")"
            target_file="$GOOGLE_UTILITIES_PATH/$expected_path"
            
            # Create directory if it doesn't exist
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                echo "    ✅ [PRE_INSTALL] Created directory: $target_dir"
            fi
            
            # Copy or create symbolic link
            if [ ! -f "$target_file" ]; then
                if cp "$actual_header" "$target_file" 2>/dev/null; then
                    echo "    ✅ [PRE_INSTALL] Copied ${header_name} to: $target_file"
                else
                    # Try symbolic link as fallback
                    if ln -sf "$actual_header" "$target_file" 2>/dev/null; then
                        echo "    ✅ [PRE_INSTALL] Created symbolic link for ${header_name} to: $target_file"
                    else
                        echo "    ❌ [PRE_INSTALL] Failed to copy or link ${header_name}"
                    fi
                fi
            else
                echo "    ✅ [PRE_INSTALL] ${header_name} already exists at: $target_file"
            fi
        else
            echo "  ⚠️ [PRE_INSTALL] Could not find ${header_name}"
        fi
    done
    
    echo "✅ [PRE_INSTALL] Pre-install header fix completed"
else
    echo "ℹ️ [PRE_INSTALL] No existing GoogleUtilities pod found, will fix after installation"
fi

echo "✅ [PRE_INSTALL] GoogleUtilities pre-install fix completed" 