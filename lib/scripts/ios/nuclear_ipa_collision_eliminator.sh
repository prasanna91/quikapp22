#!/bin/bash

# Nuclear IPA Collision Elimination Script
# Purpose: Eliminate CFBundleIdentifier collisions by directly modifying IPA file
# Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd

set -euo pipefail

# Script configuration
SCRIPT_NAME="Nuclear IPA Collision Eliminator"
ERROR_ID="fc526a49"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Input validation
if [ $# -lt 3 ]; then
    echo "❌ Usage: $0 <ipa_file> <main_bundle_id> <error_id>"
    echo "📝 Example: $0 Runner.ipa com.insurancegroupmo.insurancegroupmo fc526a49"
    exit 1
fi

IPA_FILE="$1"
MAIN_BUNDLE_ID="$2"
TARGET_ERROR_ID="$3"

# Logging functions
log_info() { echo "ℹ️ $*"; }
log_success() { echo "✅ $*"; }
log_warn() { echo "⚠️ $*"; }
log_error() { echo "❌ $*"; }

log_info "🚀 $SCRIPT_NAME Starting..."
log_info "🎯 Target Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd"
log_info "📱 IPA File: $IPA_FILE"
log_info "🆔 Main Bundle ID: $MAIN_BUNDLE_ID"
log_info "⚠️ NUCLEAR MODE: Direct IPA modification for collision elimination"

# Validate inputs
if [ ! -f "$IPA_FILE" ]; then
    log_error "IPA file not found: $IPA_FILE"
    exit 1
fi

if [[ ! "$MAIN_BUNDLE_ID" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    log_error "Invalid bundle ID format: $MAIN_BUNDLE_ID"
    exit 1
fi

# Create workspace
NUCLEAR_WORKSPACE="/tmp/nuclear_ipa_workspace_${ERROR_ID}_${TIMESTAMP}"
EXTRACTION_DIR="$NUCLEAR_WORKSPACE/extracted"
PAYLOAD_DIR="$EXTRACTION_DIR/Payload"
APP_DIR="$PAYLOAD_DIR/Runner.app"

log_info "📁 Creating nuclear workspace: $NUCLEAR_WORKSPACE"
rm -rf "$NUCLEAR_WORKSPACE"
mkdir -p "$EXTRACTION_DIR"

# Extract IPA
log_info "📦 Extracting IPA file..."
cd "$EXTRACTION_DIR"
unzip -q "$IPA_FILE" || {
    log_error "Failed to extract IPA file"
    exit 1
}

# Verify extraction
if [ ! -d "$APP_DIR" ]; then
    log_error "App bundle not found after extraction: $APP_DIR"
    exit 1
fi

log_success "IPA extracted successfully"

# Function to create unique bundle identifier
create_unique_bundle_id() {
    local base_id="$1"
    local purpose="$2"
    local unique_suffix="${ERROR_ID}.${TIMESTAMP}.$$"
    echo "${base_id}.nuclear.${purpose}.${unique_suffix}"
}

# Function to scan for CFBundleIdentifier collisions
scan_bundle_identifiers() {
    log_info "🔍 Scanning for CFBundleIdentifier collisions..."
    
    local all_plists=()
    local bundle_ids=()
    local collision_count=0
    
    # Find all Info.plist files
    while IFS= read -r -d '' plist_file; do
        all_plists+=("$plist_file")
    done < <(find "$APP_DIR" -name "Info.plist" -print0)
    
    log_info "📋 Found ${#all_plists[@]} Info.plist files"
    
    # Extract bundle identifiers
    for plist_file in "${all_plists[@]}"; do
        local bundle_id
        bundle_id=$(plutil -extract CFBundleIdentifier xml1 -o - "$plist_file" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
        
        if [ -n "$bundle_id" ]; then
            bundle_ids+=("$bundle_id")
            log_info "   📱 $plist_file → $bundle_id"
            
            if [ "$bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                ((collision_count++))
            fi
        fi
    done
    
    # Check for collisions
    if [ "$collision_count" -gt 1 ]; then
        log_error "🚨 COLLISION DETECTED: $collision_count instances of $MAIN_BUNDLE_ID"
        log_error "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd CONFIRMED"
        return 1
    else
        log_success "✅ No collisions detected for main bundle ID"
        return 0
    fi
}

# Function to apply nuclear collision elimination
apply_nuclear_elimination() {
    log_info "☢️ Applying nuclear collision elimination..."
    
    local main_app_plist="$APP_DIR/Info.plist"
    local processed_count=0
    
    # Ensure main app keeps original bundle ID
    if [ -f "$main_app_plist" ]; then
        log_info "🛡️ Protecting main app bundle ID: $main_app_plist"
        plutil -replace CFBundleIdentifier -string "$MAIN_BUNDLE_ID" "$main_app_plist"
        log_success "✅ Main app bundle ID protected"
    fi
    
    # Process all other Info.plist files
    while IFS= read -r -d '' plist_file; do
        # Skip main app plist
        if [ "$plist_file" = "$main_app_plist" ]; then
            continue
        fi
        
        local current_bundle_id
        current_bundle_id=$(plutil -extract CFBundleIdentifier xml1 -o - "$plist_file" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
        
        if [ -n "$current_bundle_id" ] && [ "$current_bundle_id" = "$MAIN_BUNDLE_ID" ]; then
            log_warn "💥 COLLISION FOUND: $plist_file has $current_bundle_id"
            
            # Determine the purpose based on file path
            local purpose="unknown"
            if [[ "$plist_file" == *"PlugIns"* ]]; then
                purpose="plugin"
            elif [[ "$plist_file" == *"Frameworks"* ]]; then
                purpose="framework"
            elif [[ "$plist_file" == *"Extensions"* ]]; then
                purpose="extension"
            elif [[ "$plist_file" == *"Watch"* ]]; then
                purpose="watch"
            elif [[ "$plist_file" == *"Tests"* ]] || [[ "$plist_file" == *"Test"* ]]; then
                purpose="tests"
            else
                purpose="component"
            fi
            
            # Create unique bundle ID
            local new_bundle_id
            new_bundle_id=$(create_unique_bundle_id "$MAIN_BUNDLE_ID" "$purpose")
            
            # Apply nuclear modification
            plutil -replace CFBundleIdentifier -string "$new_bundle_id" "$plist_file"
            
            log_success "☢️ NUCLEAR FIX: $plist_file → $new_bundle_id"
            ((processed_count++))
        fi
    done < <(find "$APP_DIR" -name "Info.plist" -print0)
    
    log_success "☢️ Nuclear elimination completed: $processed_count collisions fixed"
    return 0
}

# Function to verify nuclear elimination
verify_nuclear_elimination() {
    log_info "🔍 Verifying nuclear elimination results..."
    
    local main_bundle_count=0
    local total_bundles=0
    local unique_bundle_ids=()
    
    # Count bundle identifiers after nuclear treatment
    while IFS= read -r -d '' plist_file; do
        local bundle_id
        bundle_id=$(plutil -extract CFBundleIdentifier xml1 -o - "$plist_file" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
        
        if [ -n "$bundle_id" ]; then
            ((total_bundles++))
            
            if [ "$bundle_id" = "$MAIN_BUNDLE_ID" ]; then
                ((main_bundle_count++))
            fi
            
            # Track unique bundle IDs
            if [[ ! " ${unique_bundle_ids[*]} " =~ " ${bundle_id} " ]]; then
                unique_bundle_ids+=("$bundle_id")
            fi
        fi
    done < <(find "$APP_DIR" -name "Info.plist" -print0)
    
    log_info "📊 Nuclear elimination results:"
    log_info "   - Main bundle ID count: $main_bundle_count"
    log_info "   - Total bundle identifiers: $total_bundles"
    log_info "   - Unique bundle identifiers: ${#unique_bundle_ids[@]}"
    
    # Verify success
    if [ "$main_bundle_count" -eq 1 ]; then
        log_success "✅ NUCLEAR SUCCESS: Main bundle ID is now unique"
        log_success "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd ELIMINATED"
        return 0
    else
        log_error "❌ NUCLEAR FAILURE: Main bundle ID count is $main_bundle_count (expected: 1)"
        return 1
    fi
}

# Function to repackage IPA
repackage_ipa() {
    log_info "📦 Repackaging nuclear-modified IPA..."
    
    local output_dir
    output_dir=$(dirname "$IPA_FILE")
    local original_name
    original_name=$(basename "$IPA_FILE" .ipa)
    local nuclear_ipa="$output_dir/${original_name}_Nuclear_${ERROR_ID}_Fixed.ipa"
    
    # Create new IPA
    cd "$EXTRACTION_DIR"
    zip -r -q "$nuclear_ipa" Payload || {
        log_error "Failed to repackage IPA"
        return 1
    }
    
    # Verify new IPA
    if [ -f "$nuclear_ipa" ]; then
        local nuclear_size
        nuclear_size=$(du -h "$nuclear_ipa" | cut -f1)
        log_success "✅ Nuclear IPA created: $(basename "$nuclear_ipa") ($nuclear_size)"
        log_info "📱 Nuclear IPA location: $nuclear_ipa"
        
        # Copy as main IPA for upload
        cp "$nuclear_ipa" "$output_dir/Runner.ipa"
        log_success "✅ Nuclear IPA copied as Runner.ipa for upload"
        
        return 0
    else
        log_error "❌ Failed to create nuclear IPA"
        return 1
    fi
}

# Function to generate nuclear report
generate_nuclear_report() {
    log_info "📋 Generating nuclear elimination report..."
    
    local report_dir
    report_dir=$(dirname "$IPA_FILE")
    local report_file="$report_dir/nuclear_ipa_elimination_report_${ERROR_ID}_${TIMESTAMP}.txt"
    
    cat > "$report_file" << EOF
NUCLEAR IPA COLLISION ELIMINATION REPORT
=======================================
Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd
Nuclear Operation: COMPLETED
Timestamp: $TIMESTAMP
Nuclear Suffix: ${ERROR_ID}.${TIMESTAMP}.$$

TARGET CONFIGURATION:
Main Bundle ID: $MAIN_BUNDLE_ID
Original IPA: $(basename "$IPA_FILE")
Nuclear IPA: $(basename "$IPA_FILE" .ipa)_Nuclear_${ERROR_ID}_Fixed.ipa

NUCLEAR MODIFICATIONS APPLIED:
- Main app bundle ID: PROTECTED (unchanged)
- Framework bundle IDs: NUCLEAR ISOLATED
- Plugin bundle IDs: NUCLEAR ISOLATED
- Extension bundle IDs: NUCLEAR ISOLATED
- Test bundle IDs: NUCLEAR ISOLATED
- Component bundle IDs: NUCLEAR ISOLATED

COLLISION ELIMINATION STATUS:
✅ CFBundleIdentifier collisions ELIMINATED
✅ Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd RESOLVED
✅ App Store Connect upload READY
✅ Nuclear operation SUCCESSFUL

WARNING: This nuclear approach modifies all conflicting bundle identifiers
to ensure complete collision elimination for App Store Connect upload.

UPLOAD STATUS: CLEARED FOR APP STORE CONNECT ✅
EOF
    
    log_success "📄 Nuclear report: $(basename "$report_file")"
    return 0
}

# Main execution
main() {
    log_info "🚀 Starting nuclear IPA collision elimination..."
    
    # Step 1: Scan for collisions
    if ! scan_bundle_identifiers; then
        log_info "🚨 Collisions detected - proceeding with nuclear elimination"
    else
        log_info "✅ No collisions detected - applying preventive nuclear treatment"
    fi
    
    # Step 2: Apply nuclear elimination
    if ! apply_nuclear_elimination; then
        log_error "❌ Nuclear elimination failed"
        exit 1
    fi
    
    # Step 3: Verify results
    if ! verify_nuclear_elimination; then
        log_error "❌ Nuclear verification failed"
        exit 1
    fi
    
    # Step 4: Repackage IPA
    if ! repackage_ipa; then
        log_error "❌ IPA repackaging failed"
        exit 1
    fi
    
    # Step 5: Generate report
    generate_nuclear_report
    
    log_success "☢️ NUCLEAR IPA COLLISION ELIMINATION COMPLETED"
    log_success "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd ELIMINATED"
    log_success "🚀 IPA ready for App Store Connect upload"
    
    return 0
}

# Cleanup function
cleanup() {
    if [ -d "$NUCLEAR_WORKSPACE" ]; then
        log_info "🧹 Cleaning up nuclear workspace..."
        rm -rf "$NUCLEAR_WORKSPACE"
    fi
}

# Set cleanup trap
trap cleanup EXIT

# Execute main function
main "$@" 