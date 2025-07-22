#!/bin/bash

# iOS Workflow Conformance Verification Script
# Verifies that all scripts referenced in codemagic.yaml exist in the ios-workflow directory

set -euo pipefail

echo "🔍 iOS Workflow Conformance Verification"
echo "========================================"

# Scripts referenced in codemagic.yaml
declare -a required_scripts=(
    "validate-workflow.sh"
    "pre-build.sh"
    "build.sh"
    "post-build.sh"
    "bundle-executable-fix.sh"
    "app-store-connect-fix.sh"
    "app-store-validation.sh"
    "testflight-upload.sh"
    "branding_assets.sh"
    "inject_info_plist.sh"
    "main.sh"
    "improved_ipa_export.sh"
    "archive_structure_fix.sh"
    "enhanced_bundle_executable_fix.sh"
    "fix_app_store_connect_issues.sh"
)

# Check each required script
missing_scripts=()
existing_scripts=()

for script in "${required_scripts[@]}"; do
    if [ -f "lib/scripts/ios-workflow/$script" ]; then
        echo "✅ $script - EXISTS"
        existing_scripts+=("$script")
    else
        echo "❌ $script - MISSING"
        missing_scripts+=("$script")
    fi
done

echo ""
echo "📊 Summary:"
echo "==========="
echo "✅ Existing scripts: ${#existing_scripts[@]}"
echo "❌ Missing scripts: ${#missing_scripts[@]}"

if [ ${#missing_scripts[@]} -gt 0 ]; then
    echo ""
    echo "❌ Missing scripts that need to be created:"
    for script in "${missing_scripts[@]}"; do
        echo "   - $script"
    done
    exit 1
else
    echo ""
    echo "🎉 All required scripts exist! iOS workflow is fully conformant."
    exit 0
fi 