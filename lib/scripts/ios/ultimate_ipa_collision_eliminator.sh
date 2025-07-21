#!/bin/bash

# ☢️ ULTIMATE IPA CFBundleIdentifier Collision Eliminator
# 🎯 Target: Error "CFBundleIdentifier Collision" in IPA export phase
# 🚨 Addresses collision during archive and IPA export specifically

set -euo pipefail

echo "☢️ ULTIMATE IPA CFBundleIdentifier Collision Eliminator"
echo "🎯 Target: CFBundleIdentifier collision during IPA export"
echo "💥 Error: 'There is more than one bundle with the CFBundleIdentifier value'"
echo "📦 Working on archive and IPA-level collision elimination"
echo ""

# Get bundle identifier
BUNDLE_ID="${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}"
echo "🎯 Main Bundle ID: $BUNDLE_ID"

# Define paths
ARCHIVE_PATH="ios/build/Runner.xcarchive"
IPA_PATH="output/ios/Runner.ipa"
PAYLOAD_PATH="Runner.app"

echo "🔍 Checking for existing archive..."
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found at: $ARCHIVE_PATH"
    echo "   This script should run after archive creation but before IPA export"
    exit 1
fi

echo "✅ Archive found: $ARCHIVE_PATH"

# Create working directory for collision elimination
WORK_DIR="ipa_collision_fix_$(date +%s)"
mkdir -p "$WORK_DIR"
echo "📁 Working directory: $WORK_DIR"

echo ""
echo "☢️ PHASE 1: Archive Bundle Identifier Audit"
echo "=============================================="

# Function to audit bundle identifiers in archive
audit_archive_bundles() {
    archive_app_path="$ARCHIVE_PATH/Products/Applications/Runner.app"
    
    echo "🔍 Auditing bundle identifiers in archive..."
    
    if [ ! -d "$archive_app_path" ]; then
        echo "❌ Runner.app not found in archive"
        return 1
    fi
    
    # Check main app bundle ID
    if [ -f "$archive_app_path/Info.plist" ]; then
        main_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$archive_app_path/Info.plist" 2>/dev/null || echo "NOT_FOUND")
        echo "📱 Main App Bundle ID: $main_bundle_id"
        
        if [ "$main_bundle_id" != "$BUNDLE_ID" ]; then
            echo "⚠️ Main app bundle ID mismatch!"
            echo "   Expected: $BUNDLE_ID"
            echo "   Found: $main_bundle_id"
            echo "   🔧 Fixing main app bundle ID..."
            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$archive_app_path/Info.plist"
            echo "   ✅ Main app bundle ID corrected"
        fi
    fi
    
    # Check for embedded frameworks and plugins
    frameworks_path="$archive_app_path/Frameworks"
    plugins_path="$archive_app_path/PlugIns"
    
    # Track all bundle IDs to detect collisions
    declare -A bundle_id_map
    collision_count=0
    
    echo ""
    echo "🔍 Scanning for embedded bundles..."
    
    # Check Frameworks
    if [ -d "$frameworks_path" ]; then
        echo "📦 Scanning Frameworks directory..."
        for framework in "$frameworks_path"/*.framework; do
            if [ -d "$framework" ]; then
                framework_name=$(basename "$framework" .framework)
                info_plist="$framework/Info.plist"
                
                if [ -f "$info_plist" ]; then
                    framework_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist" 2>/dev/null || echo "NOT_FOUND")
                    
                    if [ "$framework_bundle_id" != "NOT_FOUND" ]; then
                        echo "   📦 Framework: $framework_name"
                        echo "      Bundle ID: $framework_bundle_id"
                        
                        # Check for collision
                        if [ "$framework_bundle_id" = "$BUNDLE_ID" ]; then
                            echo "      💥 COLLISION DETECTED with main app!"
                            collision_count=$((collision_count + 1))
                            
                            # Generate unique bundle ID for framework
                            unique_id="${BUNDLE_ID}.framework.${framework_name}.$(date +%s)"
                            echo "      🔧 Fixing collision: $unique_id"
                            
                            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $unique_id" "$info_plist"
                            echo "      ✅ Framework bundle ID corrected"
                        fi
                        
                        # Track bundle ID usage
                        if [ -n "${bundle_id_map[$framework_bundle_id]:-}" ]; then
                            echo "      💥 DUPLICATE BUNDLE ID DETECTED!"
                            echo "         Already used by: ${bundle_id_map[$framework_bundle_id]}"
                            collision_count=$((collision_count + 1))
                            
                            # Generate unique bundle ID
                            unique_id="${BUNDLE_ID}.framework.${framework_name}.$(date +%s)"
                            echo "      🔧 Fixing duplicate: $unique_id"
                            
                            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $unique_id" "$info_plist"
                            bundle_id_map[$unique_id]="$framework_name"
                            echo "      ✅ Duplicate bundle ID corrected"
                        else
                            bundle_id_map[$framework_bundle_id]="$framework_name"
                        fi
                    fi
                fi
            fi
        done
    fi
    
    # Check PlugIns (App Extensions)
    if [ -d "$plugins_path" ]; then
        echo "🔌 Scanning PlugIns directory..."
        for plugin in "$plugins_path"/*.appex; do
            if [ -d "$plugin" ]; then
                plugin_name=$(basename "$plugin" .appex)
                info_plist="$plugin/Info.plist"
                
                if [ -f "$info_plist" ]; then
                    plugin_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist" 2>/dev/null || echo "NOT_FOUND")
                    
                    if [ "$plugin_bundle_id" != "NOT_FOUND" ]; then
                        echo "   🔌 Plugin: $plugin_name"
                        echo "      Bundle ID: $plugin_bundle_id"
                        
                        # Check for collision
                        if [ "$plugin_bundle_id" = "$BUNDLE_ID" ]; then
                            echo "      💥 COLLISION DETECTED with main app!"
                            collision_count=$((collision_count + 1))
                            
                            # Generate unique bundle ID for plugin
                            unique_id="${BUNDLE_ID}.plugin.${plugin_name}.$(date +%s)"
                            echo "      🔧 Fixing collision: $unique_id"
                            
                            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $unique_id" "$info_plist"
                            echo "      ✅ Plugin bundle ID corrected"
                        fi
                        
                        # Track bundle ID usage
                        if [ -n "${bundle_id_map[$plugin_bundle_id]:-}" ]; then
                            echo "      💥 DUPLICATE BUNDLE ID DETECTED!"
                            echo "         Already used by: ${bundle_id_map[$plugin_bundle_id]}"
                            collision_count=$((collision_count + 1))
                            
                            # Generate unique bundle ID
                            unique_id="${BUNDLE_ID}.plugin.${plugin_name}.$(date +%s)"
                            echo "      🔧 Fixing duplicate: $unique_id"
                            
                            /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $unique_id" "$info_plist"
                            bundle_id_map[$unique_id]="$plugin_name"
                            echo "      ✅ Duplicate bundle ID corrected"
                        else
                            bundle_id_map[$plugin_bundle_id]="$plugin_name"
                        fi
                    fi
                fi
            fi
        done
    fi
    
    echo ""
    echo "📊 Archive Audit Summary:"
    echo "   Total bundle IDs found: ${#bundle_id_map[@]}"
    echo "   Collisions fixed: $collision_count"
    
    if [ $collision_count -eq 0 ]; then
        echo "   ✅ No collisions detected in archive"
    else
        echo "   ☢️ $collision_count collisions detected and fixed"
    fi
    
    return $collision_count
}

# Run archive audit
audit_archive_bundles
archive_fixes=$?

echo ""
echo "☢️ PHASE 2: IPA Export with Collision Prevention"
echo "================================================"

# Function to create export options plist with collision prevention
create_export_options() {
    export_method="${1:-app-store}"
    team_id="${APPLE_TEAM_ID:-}"
    
    echo "🔧 Creating export options with collision prevention..."
    
    cat > "$WORK_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$export_method</string>
    <key>teamID</key>
    <string>$team_id</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>embedOnDemandResourcesAssetPacksInBundle</key>
    <false/>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>generateAppStoreInformation</key>
    <true/>
    <key>iCloudContainerEnvironment</key>
    <string>Production</string>
</dict>
</plist>
EOF
    
    echo "✅ Export options created: $WORK_DIR/ExportOptions.plist"
}

# Determine export method based on profile type
PROFILE_TYPE="${PROFILE_TYPE:-app-store}"
case "$PROFILE_TYPE" in
    "app-store"|"ad-hoc")
        echo "📤 Export method: $PROFILE_TYPE"
        ;;
    *)
        echo "⚠️ Unknown profile type: $PROFILE_TYPE, defaulting to app-store"
        PROFILE_TYPE="app-store"
        ;;
esac

create_export_options "$PROFILE_TYPE"

echo ""
echo "☢️ PHASE 3: IPA Export with Ultimate Collision Prevention"
echo "=========================================================="

# Create output directory
mkdir -p "output/ios"

echo "🚀 Exporting IPA with collision-safe archive..."
echo "   Archive: $ARCHIVE_PATH"
echo "   Export Options: $WORK_DIR/ExportOptions.plist"
echo "   Output: output/ios/"

# Export IPA using collision-safe archive
if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$WORK_DIR/ExportOptions.plist" \
    -exportPath "output/ios" \
    -allowProvisioningUpdates; then
    
    echo "✅ IPA export completed successfully"
    
    # Verify IPA was created
    if [ -f "output/ios/Runner.ipa" ]; then
        echo "✅ IPA file created: output/ios/Runner.ipa"
        
        # Get IPA file size
        ipa_size=$(ls -lh output/ios/Runner.ipa | awk '{print $5}')
        echo "📦 IPA size: $ipa_size"
        
    else
        echo "❌ IPA file not found after export"
        exit 1
    fi
    
else
    echo "❌ IPA export failed"
    echo "🔍 Checking for additional collision sources..."
    
    # Additional collision debugging
    echo ""
    echo "🔍 Advanced Collision Debugging"
    echo "==============================="
    
    # Check for any remaining bundle ID issues
    find "$ARCHIVE_PATH" -name "Info.plist" -exec echo "📄 {}" \; -exec /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" {} \; 2>/dev/null | grep -E "(\.plist|$BUNDLE_ID)" || true
    
    echo ""
    echo "❌ IPA export failed even after collision fixes"
    echo "   This may indicate a signing or provisioning issue"
    echo "   rather than a bundle ID collision"
    
    exit 1
fi

echo ""
echo "☢️ PHASE 4: Post-Export Validation"
echo "==================================="

# Validate the exported IPA
echo "🔍 Validating exported IPA for bundle ID collisions..."

# Extract IPA for validation
VALIDATION_DIR="$WORK_DIR/ipa_validation"
mkdir -p "$VALIDATION_DIR"

if unzip -q "output/ios/Runner.ipa" -d "$VALIDATION_DIR"; then
    echo "✅ IPA extracted for validation"
    
    # Find all Info.plist files in the extracted IPA
    echo "🔍 Scanning IPA contents for bundle IDs..."
    
    declare -A ipa_bundle_ids
    ipa_collision_count=0
    
    find "$VALIDATION_DIR" -name "Info.plist" -print0 | while IFS= read -r -d '' plist_file; do
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist_file" 2>/dev/null || echo "NOT_FOUND")
        
        if [ "$bundle_id" != "NOT_FOUND" ]; then
            relative_path=${plist_file#$VALIDATION_DIR/}
            echo "   📄 $relative_path: $bundle_id"
            
            # Check for main app bundle ID collision
            if [ "$bundle_id" = "$BUNDLE_ID" ] && [[ "$relative_path" != *"Runner.app/Info.plist" ]]; then
                echo "      💥 COLLISION: Non-main component using main bundle ID!"
                ipa_collision_count=$((ipa_collision_count + 1))
            fi
        fi
    done
    
    if [ $ipa_collision_count -eq 0 ]; then
        echo "✅ IPA validation passed - no bundle ID collisions detected"
    else
        echo "⚠️ IPA validation found $ipa_collision_count potential collisions"
        echo "   However, IPA was successfully exported"
    fi
    
else
    echo "⚠️ Could not extract IPA for validation"
    echo "   IPA export was successful, validation skipped"
fi

echo ""
echo "☢️ ULTIMATE IPA COLLISION ELIMINATOR COMPLETE"
echo "=============================================="
echo "✅ Archive collision fixes: $archive_fixes"
echo "✅ IPA export: SUCCESS"
echo "✅ Bundle ID preservation: $BUNDLE_ID"
echo "📦 Output: output/ios/Runner.ipa"
echo ""
echo "🎯 CFBundleIdentifier collision error should be eliminated"
echo "💥 IPA is ready for distribution or TestFlight upload"

# Cleanup working directory
rm -rf "$WORK_DIR"

echo "✅ Ultimate IPA collision elimination completed successfully" 