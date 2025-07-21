#!/bin/bash

# 🔍 CFBundleIdentifier Collision Diagnostics - DEEP ANALYSIS
# 🎯 Purpose: Identify EXACT collision sources in IPA file
# 💥 Strategy: Comprehensive analysis to understand WHY error IDs keep changing
# 🛡️ Goal: Find ALL collision sources before they reach Apple's validation

set -euo pipefail

# 🔧 Configuration
SCRIPT_DIR="$(dirname "$0")"
IPA_FILE="${1:-output/ios/Runner.ipa}"
MAIN_BUNDLE_ID="${2:-com.insurancegroupmo.insurancegroupmo}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Source utilities if available
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    # Basic logging functions
    log_info() { echo "ℹ️ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
    log_success() { echo "✅ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
    log_warn() { echo "⚠️ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
    log_error() { echo "❌ [$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
fi

echo ""
echo "🔍 CFBUNDLEIDENTIFIER COLLISION DIAGNOSTICS"
echo "================================================================="
log_info "🚀 DEEP ANALYSIS: Identify EXACT collision sources"
log_info "🎯 Error IDs Seen: 882c8a3f, 9e775c2f, d969fe7f, 2f68877e, 78eec16c, 1964e61a"
log_info "💥 Strategy: Find ALL collision sources to stop Apple validation failures"
log_info "📁 IPA File: $IPA_FILE"
log_info "📱 Main Bundle ID: $MAIN_BUNDLE_ID"
echo ""

# 🔍 Step 1: Validate IPA file exists
log_info "🔍 Step 1: Validating IPA file for analysis..."

if [ ! -f "$IPA_FILE" ]; then
    log_error "❌ IPA file not found: $IPA_FILE"
    echo "💡 Make sure the iOS build completed successfully and generated an IPA file"
    exit 1
fi

IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
log_success "✅ IPA file found: $IPA_FILE ($IPA_SIZE)"

# 📦 Step 2: Extract IPA for deep analysis
log_info "📦 Step 2: Extracting IPA for deep collision analysis..."
ANALYSIS_DIR="collision_diagnostics_${TIMESTAMP}"
mkdir -p "$ANALYSIS_DIR"
cd "$ANALYSIS_DIR"

# Extract IPA completely
unzip -q "../$IPA_FILE"
APP_DIR=$(find . -name "*.app" -type d | head -1)

if [ -z "$APP_DIR" ]; then
    log_error "❌ No .app directory found in IPA"
    exit 1
fi

APP_NAME=$(basename "$APP_DIR")
log_success "✅ Extracted IPA, found app: $APP_NAME"

# 🔍 Step 3: COMPREHENSIVE collision analysis
log_info "🔍 Step 3: COMPREHENSIVE collision analysis..."

echo ""
echo "🔍 DETAILED COLLISION ANALYSIS REPORT"
echo "================================================================="
echo "Timestamp: $(date)"
echo "IPA File: $IPA_FILE"
echo "Main Bundle ID: $MAIN_BUNDLE_ID"
echo "App Name: $APP_NAME"
echo ""

# Find ALL Info.plist files in the IPA
log_info "📋 Finding ALL Info.plist files in IPA..."
ALL_PLISTS=$(find . -name "Info.plist" -type f)
TOTAL_PLISTS=$(echo "$ALL_PLISTS" | wc -l | xargs)

log_info "📊 Found $TOTAL_PLISTS Info.plist files"

# Analyze each Info.plist file
echo ""
echo "📋 BUNDLE IDENTIFIER ANALYSIS:"
echo "================================="

COLLISION_COUNT=0
UNIQUE_BUNDLE_IDS=()
COLLISION_SOURCES=()
ALL_BUNDLE_DATA=()

while read -r plist_file; do
    if [ -f "$plist_file" ]; then
        # Extract CFBundleIdentifier
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist_file" 2>/dev/null || echo "")
        
        if [ -n "$bundle_id" ]; then
            relative_path=$(echo "$plist_file" | sed 's|^\./||')
            
            # Store all bundle data for analysis
            ALL_BUNDLE_DATA+=("$bundle_id|$relative_path")
            
            # Check for collision with main bundle ID
            if [ "$bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                COLLISION_COUNT=$((COLLISION_COUNT + 1))
                COLLISION_SOURCES+=("$relative_path")
                echo "💥 COLLISION: $relative_path -> $bundle_id"
            else
                echo "📦 EXTERNAL: $relative_path -> $bundle_id"
            fi
            
            # Track unique bundle IDs
            # shellcheck disable=SC2199
            if [[ ! " ${UNIQUE_BUNDLE_IDS[@]} " =~ " ${bundle_id} " ]]; then
                UNIQUE_BUNDLE_IDS+=("$bundle_id")
            fi
        else
            echo "⚠️ NO BUNDLE ID: $relative_path"
        fi
    fi
done <<< "$ALL_PLISTS"

echo ""
echo "📊 COLLISION SUMMARY:"
echo "====================="
echo "Total Info.plist files: $TOTAL_PLISTS"
echo "Main bundle ID occurrences: $COLLISION_COUNT"
echo "Unique bundle IDs: ${#UNIQUE_BUNDLE_IDS[@]}"
echo ""

if [ "$COLLISION_COUNT" -gt 1 ]; then
    log_error "💥 COLLISION DETECTED: $COLLISION_COUNT instances of '$MAIN_BUNDLE_ID'"
    echo ""
    echo "🔍 COLLISION SOURCES:"
    for source in "${COLLISION_SOURCES[@]}"; do
        echo "   💥 $source"
    done
else
    log_success "✅ NO COLLISIONS: Only 1 instance of '$MAIN_BUNDLE_ID' found"
fi

# 🔍 Step 4: Framework analysis
log_info "🔍 Step 4: Framework analysis..."

echo ""
echo "🔧 FRAMEWORK ANALYSIS:"
echo "======================"

# Find all framework directories
FRAMEWORKS=$(find . -name "*.framework" -type d)
FRAMEWORK_COUNT=$(echo "$FRAMEWORKS" | grep -c . || echo "0")

echo "Framework directories found: $FRAMEWORK_COUNT"

if [ "$FRAMEWORK_COUNT" -gt 0 ]; then
    echo ""
    echo "📦 FRAMEWORKS:"
    while read -r framework; do
        if [ -n "$framework" ]; then
            framework_name=$(basename "$framework")
            framework_path=$(echo "$framework" | sed 's|^\./||')
            echo "   🔧 $framework_name -> $framework_path"
            
            # Check for Info.plist in framework
            framework_plist="$framework/Info.plist"
            if [ -f "$framework_plist" ]; then
                framework_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$framework_plist" 2>/dev/null || echo "")
                if [ -n "$framework_bundle_id" ]; then
                    echo "      📱 Bundle ID: $framework_bundle_id"
                    if [ "$framework_bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                        echo "      💥 COLLISION WITH MAIN APP!"
                    fi
                fi
            fi
        fi
    done <<< "$FRAMEWORKS"
fi

# 🔍 Step 5: App extension analysis
log_info "🔍 Step 5: App extension analysis..."

echo ""
echo "🔌 APP EXTENSION ANALYSIS:"
echo "=========================="

# Find all .appex directories (app extensions)
EXTENSIONS=$(find . -name "*.appex" -type d)
EXTENSION_COUNT=$(echo "$EXTENSIONS" | grep -c . || echo "0")

echo "App extensions found: $EXTENSION_COUNT"

if [ "$EXTENSION_COUNT" -gt 0 ]; then
    echo ""
    echo "🔌 EXTENSIONS:"
    while read -r extension; do
        if [ -n "$extension" ]; then
            extension_name=$(basename "$extension")
            extension_path=$(echo "$extension" | sed 's|^\./||')
            echo "   🔌 $extension_name -> $extension_path"
            
            # Check for Info.plist in extension
            extension_plist="$extension/Info.plist"
            if [ -f "$extension_plist" ]; then
                extension_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$extension_plist" 2>/dev/null || echo "")
                if [ -n "$extension_bundle_id" ]; then
                    echo "      📱 Bundle ID: $extension_bundle_id"
                    if [ "$extension_bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                        echo "      💥 COLLISION WITH MAIN APP!"
                    fi
                fi
            fi
            
            # Check for frameworks within extension
            extension_frameworks=$(find "$extension" -name "*.framework" -type d)
            if [ -n "$extension_frameworks" ]; then
                echo "      🔧 Extension contains frameworks:"
                while read -r ext_framework; do
                    if [ -n "$ext_framework" ]; then
                        ext_framework_name=$(basename "$ext_framework")
                        echo "         📦 $ext_framework_name"
                    fi
                done <<< "$extension_frameworks"
            fi
        fi
    done <<< "$EXTENSIONS"
fi

# 🔍 Step 6: Duplicate bundle ID detection
log_info "🔍 Step 6: Duplicate bundle ID detection..."

echo ""
echo "🔍 DUPLICATE BUNDLE ID ANALYSIS:"
echo "================================"

# Create associative array to count bundle ID occurrences
declare -A bundle_id_counts
declare -A bundle_id_paths

for entry in "${ALL_BUNDLE_DATA[@]}"; do
    bundle_id=$(echo "$entry" | cut -d'|' -f1)
    path=$(echo "$entry" | cut -d'|' -f2)
    
    if [ -n "$bundle_id" ]; then
        bundle_id_counts["$bundle_id"]=$((${bundle_id_counts["$bundle_id"]:-0} + 1))
        if [ -z "${bundle_id_paths["$bundle_id"]:-}" ]; then
            bundle_id_paths["$bundle_id"]="$path"
        else
            bundle_id_paths["$bundle_id"]="${bundle_id_paths["$bundle_id"]}|$path"
        fi
    fi
done

echo "Checking for duplicate bundle IDs..."
DUPLICATES_FOUND=false

for bundle_id in "${!bundle_id_counts[@]}"; do
    count=${bundle_id_counts["$bundle_id"]}
    if [ "$count" -gt 1 ]; then
        echo "💥 DUPLICATE: '$bundle_id' appears $count times"
        IFS='|' read -ra paths <<< "${bundle_id_paths["$bundle_id"]}"
        for path in "${paths[@]}"; do
            echo "   📍 $path"
        done
        DUPLICATES_FOUND=true
        echo ""
    fi
done

if [ "$DUPLICATES_FOUND" = false ]; then
    log_success "✅ NO DUPLICATE BUNDLE IDs FOUND"
else
    log_error "💥 DUPLICATE BUNDLE IDs DETECTED - These are causing Apple validation failures"
fi

# 📋 Step 7: Generate comprehensive diagnostic report
log_info "📋 Step 7: Generating comprehensive diagnostic report..."

DIAGNOSTIC_REPORT="collision_diagnostics_report_${TIMESTAMP}.txt"
cat > "../$DIAGNOSTIC_REPORT" << EOF
🔍 CFBundleIdentifier Collision Diagnostics Report
=================================================
DEEP ANALYSIS - EXACT COLLISION SOURCE IDENTIFICATION
Timestamp: $(date)
IPA File: $IPA_FILE ($IPA_SIZE)
Main Bundle ID: $MAIN_BUNDLE_ID

ERROR ID HISTORY:
- 882c8a3f-6a99-4c5c-bc5e-e8d3ed1cbb46 ✅ (Fixed)
- 9e775c2f-aaf4-45b6-94b5-dee16fc84395 ✅ (Fixed)  
- d969fe7f-7598-47a6-ab32-b16d4f3473f2 ✅ (Fixed)
- 2f68877e-ea5b-4f3c-8a80-9c4e3cac9e89 ✅ (Fixed)
- 78eec16c-d7e3-49fb-958b-631df5a32405 ✅ (Fixed)
- 1964e61a-f528-4f82-91a8-90671277fda3 ❌ (CURRENT)

COLLISION ANALYSIS RESULTS:
============================
Total Info.plist files: $TOTAL_PLISTS
Main bundle ID ('$MAIN_BUNDLE_ID') occurrences: $COLLISION_COUNT
Unique bundle IDs found: ${#UNIQUE_BUNDLE_IDS[@]}
Frameworks found: $FRAMEWORK_COUNT
App extensions found: $EXTENSION_COUNT

COLLISION STATUS: $([ "$COLLISION_COUNT" -gt 1 ] && echo "DETECTED" || echo "NOT DETECTED")
DUPLICATE BUNDLE IDs: $([ "$DUPLICATES_FOUND" = true ] && echo "DETECTED" || echo "NOT DETECTED")

COLLISION SOURCES:
$(for source in "${COLLISION_SOURCES[@]}"; do echo "💥 $source"; done)

RECOMMENDED ACTIONS:
===================
EOF

if [ "$COLLISION_COUNT" -gt 1 ]; then
    cat >> "../$DIAGNOSTIC_REPORT" << EOF
1. 🔧 IMMEDIATE: Apply MEGA NUCLEAR collision elimination
2. ☢️ AGGRESSIVE: Modify ALL bundle IDs in collision sources
3. 🎯 TARGETED: Focus on error ID 1964e61a
4. 🛡️ COMPREHENSIVE: Use universal approach for future protection
EOF
else
    cat >> "../$DIAGNOSTIC_REPORT" << EOF
1. ✅ NO COLLISIONS DETECTED in current IPA
2. 🔍 INVESTIGATE: Collision may be occurring during Apple's validation process
3. 🎯 PREEMPTIVE: Apply universal collision elimination as precaution
4. 🛡️ COMPREHENSIVE: Ensure all edge cases are covered
EOF
fi

cat >> "../$DIAGNOSTIC_REPORT" << EOF

NEXT STEPS:
===========
1. Apply MEGA NUCLEAR collision elimination targeting error ID 1964e61a
2. Use universal approach to handle ANY future error ID
3. Verify no residual collision sources remain
4. Test with Apple's validation process

=================================================
EOF

cd ..
rm -rf "$ANALYSIS_DIR"

log_success "✅ Diagnostic report generated: $DIAGNOSTIC_REPORT"

echo ""
echo "🎉 COLLISION DIAGNOSTICS COMPLETED!"
echo "================================================================="
log_info "🔍 Deep analysis completed - see diagnostic report for details"
log_info "📋 Report: $DIAGNOSTIC_REPORT"

if [ "$COLLISION_COUNT" -gt 1 ]; then
    log_error "💥 COLLISIONS DETECTED: $COLLISION_COUNT instances of main bundle ID"
    log_error "🎯 SOLUTION: Apply MEGA NUCLEAR collision elimination"
    echo ""
    echo "🚨 RECOMMENDED IMMEDIATE ACTION:"
    echo "   Run MEGA NUCLEAR collision elimination targeting error ID 1964e61a"
    echo "   This will eliminate ALL collision sources aggressively"
    exit 1
else
    log_success "✅ NO COLLISIONS FOUND: IPA appears clean"
    log_warn "⚠️ Collision may be happening during Apple validation process"
    echo ""
    echo "💡 RECOMMENDED PREEMPTIVE ACTION:"
    echo "   Apply universal collision elimination as precaution"
    echo "   This will ensure no edge cases cause future collisions"
    exit 0
fi 