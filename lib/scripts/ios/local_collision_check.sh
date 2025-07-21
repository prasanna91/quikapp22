#!/bin/bash

# 🔍 LOCAL CFBundleIdentifier Collision Check - PRE-BUILD ANALYSIS
# 🎯 Purpose: Check for collision sources BEFORE building/uploading
# 💥 Strategy: Analyze Xcode project and identify potential problems early
# 🛡️ Prevent upload failures by catching collisions locally

set -euo pipefail

# 🔧 Configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_FILE="${1:-ios/Runner.xcodeproj/project.pbxproj}"
MAIN_BUNDLE_ID="${2:-com.insurancegroupmo.insurancegroupmo}"
PODFILE="${3:-ios/Podfile}"

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
echo "🔍 LOCAL CFBUNDLEIDENTIFIER COLLISION CHECK"
echo "================================================================="
log_info "🚀 PRE-BUILD ANALYSIS: Check for collision sources before building"
log_info "🎯 Target Error ID: 1964e61a-f528-4f82-91a8-90671277fda3"
log_info "💥 Strategy: Find collision sources EARLY to prevent upload failures"
log_info "📱 Main Bundle ID: $MAIN_BUNDLE_ID"
echo ""

# 🔍 Step 1: Validate files exist
log_info "🔍 Step 1: Validating project files..."

if [ ! -f "$PROJECT_FILE" ]; then
    log_error "❌ Project file not found: $PROJECT_FILE"
    echo "💡 Make sure you're running this from the project root"
    exit 1
fi

log_success "✅ Project file found: $PROJECT_FILE"

# 🔍 Step 2: Analyze Xcode project bundle IDs
log_info "🔍 Step 2: Analyzing Xcode project bundle IDs..."

# Extract ALL bundle identifiers from project
ALL_BUNDLE_IDS=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;' "$PROJECT_FILE" | sed 's/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//' | sort)
UNIQUE_BUNDLE_IDS=$(echo "$ALL_BUNDLE_IDS" | sort | uniq)
TOTAL_BUNDLE_IDS=$(echo "$ALL_BUNDLE_IDS" | wc -l | xargs)
UNIQUE_COUNT=$(echo "$UNIQUE_BUNDLE_IDS" | wc -l | xargs)

log_info "📊 Bundle ID analysis:"
log_info "   📦 Total bundle ID references: $TOTAL_BUNDLE_IDS"
log_info "   🆔 Unique bundle IDs: $UNIQUE_COUNT"

# Check for collisions
COLLISION_COUNT=0
if [ "$TOTAL_BUNDLE_IDS" != "$UNIQUE_COUNT" ]; then
    log_error "💥 COLLISION DETECTED: $(($TOTAL_BUNDLE_IDS - $UNIQUE_COUNT)) duplicate bundle ID references"
    COLLISION_COUNT=$(($TOTAL_BUNDLE_IDS - $UNIQUE_COUNT))
    
    echo ""
    log_error "🔍 COLLISION ANALYSIS:"
    
    # Find which bundle IDs have duplicates
    echo "$ALL_BUNDLE_IDS" | sort | uniq -c | while read count bundle_id; do
        if [ "$count" -gt 1 ]; then
            log_error "   💥 DUPLICATE: '$bundle_id' appears $count times"
            if [ "$bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                log_error "      ⚠️ THIS IS THE MAIN BUNDLE ID - CRITICAL COLLISION!"
            fi
        fi
    done
else
    log_success "✅ NO COLLISIONS: All bundle IDs are unique in Xcode project"
fi

# 🔍 Step 3: Check for main bundle ID occurrences
log_info "🔍 Step 3: Checking main bundle ID occurrences..."

MAIN_BUNDLE_COUNT=$(echo "$ALL_BUNDLE_IDS" | grep -c "$MAIN_BUNDLE_ID" 2>/dev/null || echo "0")
log_info "📱 Main bundle ID '$MAIN_BUNDLE_ID' appears: $MAIN_BUNDLE_COUNT times"

if [ "$MAIN_BUNDLE_COUNT" -gt 1 ]; then
    log_error "💥 CRITICAL: Main bundle ID appears $MAIN_BUNDLE_COUNT times!"
    log_error "🚨 This WILL cause CFBundleIdentifier collision errors"
    
    echo ""
    log_error "🔍 Main bundle ID locations:"
    grep -n "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" | while read line; do
        log_error "   📍 Line: $line"
    done
elif [ "$MAIN_BUNDLE_COUNT" -eq 1 ]; then
    log_success "✅ Main bundle ID appears exactly once (correct)"
else
    log_warn "⚠️ Main bundle ID not found in project (may be set elsewhere)"
fi

# 🔍 Step 4: Check Info.plist files
log_info "🔍 Step 4: Checking Info.plist files..."

INFO_PLISTS=$(find ios -name "Info.plist" -type f 2>/dev/null || true)
PLIST_COUNT=$(echo "$INFO_PLISTS" | grep -c . || echo "0")

if [ "$PLIST_COUNT" -gt 0 ]; then
    log_info "📋 Found $PLIST_COUNT Info.plist files:"
    
    echo "$INFO_PLISTS" | while read plist_file; do
        if [ -f "$plist_file" ]; then
            bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist_file" 2>/dev/null || echo "")
            if [ -n "$bundle_id" ]; then
                log_info "   📦 $plist_file -> $bundle_id"
                if [ "$bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                    log_warn "      💥 USES MAIN BUNDLE ID"
                fi
            else
                log_info "   📦 $plist_file -> (no CFBundleIdentifier)"
            fi
        fi
    done
else
    log_warn "⚠️ No Info.plist files found"
fi

# 🔍 Step 5: Check Podfile for collision prevention
log_info "🔍 Step 5: Checking Podfile for collision prevention..."

if [ -f "$PODFILE" ]; then
    if grep -q "AGGRESSIVE.*COLLISION.*PREVENTION\|post_install.*bundle.*collision\|PRODUCT_BUNDLE_IDENTIFIER.*external" "$PODFILE"; then
        log_success "✅ Podfile contains collision prevention code"
    else
        log_warn "⚠️ Podfile does NOT contain collision prevention code"
        log_warn "🔧 Collision prevention should be added to Podfile"
    fi
else
    log_warn "⚠️ Podfile not found: $PODFILE"
fi

# 🔍 Step 6: Check for framework embedding issues
log_info "🔍 Step 6: Checking for framework embedding issues..."

# Look for Flutter.xcframework references
FLUTTER_FRAMEWORK_REFS=$(grep -c "Flutter\.xcframework\|Flutter\.framework" "$PROJECT_FILE" 2>/dev/null || echo "0")
EMBED_FRAMEWORKS_REFS=$(grep -c "Embed Frameworks" "$PROJECT_FILE" 2>/dev/null || echo "0")

log_info "📦 Framework analysis:"
log_info "   🔧 Flutter framework references: $FLUTTER_FRAMEWORK_REFS"
log_info "   🔗 Embed Frameworks phases: $EMBED_FRAMEWORKS_REFS"

if [ "$FLUTTER_FRAMEWORK_REFS" -gt 2 ] && [ "$EMBED_FRAMEWORKS_REFS" -gt 1 ]; then
    log_warn "⚠️ Multiple Flutter framework references + multiple embed phases"
    log_warn "🔧 This could cause framework embedding collisions"
fi

# 📊 Step 7: Generate recommendations
echo ""
echo "📊 COLLISION CHECK SUMMARY"
echo "================================="
log_info "Bundle ID Status:"
log_info "   📦 Total bundle ID references: $TOTAL_BUNDLE_IDS"
log_info "   🆔 Unique bundle IDs: $UNIQUE_COUNT"
log_info "   💥 Duplicates detected: $COLLISION_COUNT"
log_info "   📱 Main bundle ID occurrences: $MAIN_BUNDLE_COUNT"
log_info "   📋 Info.plist files: $PLIST_COUNT"

echo ""
if [ "$COLLISION_COUNT" -gt 0 ] || [ "$MAIN_BUNDLE_COUNT" -gt 1 ]; then
    log_error "💥 COLLISION RISK: HIGH"
    echo ""
    echo "🚨 IMMEDIATE ACTIONS REQUIRED:"
    echo "1. 🔧 Apply collision prevention scripts BEFORE building"
    echo "2. ☢️ Use MEGA NUCLEAR collision elimination"
    echo "3. 🔍 Run framework embedding fix"
    echo "4. 🛡️ Apply aggressive bundle ID changes"
    echo ""
    echo "📝 Recommended commands:"
    echo "   chmod +x lib/scripts/ios/aggressive_collision_eliminator.sh"
    echo "   ./lib/scripts/ios/aggressive_collision_eliminator.sh '$MAIN_BUNDLE_ID' '$PROJECT_FILE' '1964e61a'"
    echo ""
    echo "   chmod +x lib/scripts/ios/framework_embedding_collision_fix.sh"
    echo "   ./lib/scripts/ios/framework_embedding_collision_fix.sh 'ios/Runner.xcodeproj' 'Flutter.xcframework'"
    
    exit 1
elif [ "$MAIN_BUNDLE_COUNT" -eq 0 ]; then
    log_warn "⚠️ COLLISION RISK: MEDIUM"
    log_warn "🔧 Main bundle ID not found - may be set dynamically"
    echo ""
    echo "💡 RECOMMENDED ACTIONS:"
    echo "1. ✅ Verify bundle ID is set correctly in CI/CD environment"
    echo "2. 🔧 Apply collision prevention as precaution"
    echo "3. 🛡️ Use universal collision prevention"
    
    exit 0
else
    log_success "✅ COLLISION RISK: LOW"
    log_success "🎯 Project appears configured correctly"
    echo ""
    echo "💡 RECOMMENDED ACTIONS:"
    echo "1. ✅ Project looks good for building"
    echo "2. 🛡️ Apply universal collision prevention as insurance"
    echo "3. 🔍 Monitor build process for any issues"
    
    exit 0
fi 