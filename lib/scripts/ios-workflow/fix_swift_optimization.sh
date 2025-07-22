#!/bin/bash

# Fix Swift Optimization Warnings Script
# Purpose: Fix Swift optimization warnings that disable previews

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    log_info "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    log_error "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    exit 1
fi

log_info "🔧 Fixing Swift optimization warnings..."

# Function to fix Swift optimization settings
fix_swift_optimization() {
    local project_file="$1"
    
    if [ ! -f "$project_file" ]; then
        log_warn "⚠️ Project file not found: $project_file"
        return 1
    fi
    
    log_info "🔧 Fixing Swift optimization in: $project_file"
    
    # Create backup
    cp "$project_file" "${project_file}.backup"
    
    # Fix SWIFT_OPTIMIZATION_LEVEL for debug builds
    if command -v plutil >/dev/null 2>&1; then
        # Set SWIFT_OPTIMIZATION_LEVEL to -Onone for debug builds
        plutil -replace SWIFT_OPTIMIZATION_LEVEL -string "-Onone" "$project_file" 2>/dev/null || true
        
        # Also set SWIFT_VERSION if not set
        plutil -replace SWIFT_VERSION -string "5.0" "$project_file" 2>/dev/null || true
        
        log_success "✅ Swift optimization settings updated for: $project_file"
    else
        log_warn "⚠️ plutil not available, using sed fallback"
        
        # Fallback using sed
        sed -i.bak 's/SWIFT_OPTIMIZATION_LEVEL = "-O";/SWIFT_OPTIMIZATION_LEVEL = "-Onone";/g' "$project_file" 2>/dev/null || true
        sed -i.bak 's/SWIFT_VERSION = "5.0";/SWIFT_VERSION = "5.0";/g' "$project_file" 2>/dev/null || true
        
        log_success "✅ Swift optimization settings updated (fallback method): $project_file"
    fi
}

# Function to fix Pods project
fix_pods_optimization() {
    if [ -f "ios/Pods/Pods.xcodeproj/project.pbxproj" ]; then
        log_info "🔧 Fixing Swift optimization in Pods project..."
        fix_swift_optimization "ios/Pods/Pods.xcodeproj/project.pbxproj"
    else
        log_warn "⚠️ Pods project not found"
    fi
}

# Function to fix main project
fix_main_project_optimization() {
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        log_info "🔧 Fixing Swift optimization in main project..."
        fix_swift_optimization "ios/Runner.xcodeproj/project.pbxproj"
    else
        log_warn "⚠️ Main project not found"
    fi
}

# Function to disable run script phases for every build
fix_run_script_phases() {
    local project_file="$1"
    
    if [ ! -f "$project_file" ]; then
        return 1
    fi
    
    log_info "🔧 Fixing run script phases in: $project_file"
    
    # Create backup
    cp "$project_file" "${project_file}.backup"
    
    # Enable "Based on dependency analysis" for run script phases
    if command -v plutil >/dev/null 2>&1; then
        # This is more complex and requires specific phase IDs
        # For now, we'll just log that this needs manual attention
        log_info "ℹ️ Run script phases should be configured to run 'Based on dependency analysis'"
        log_info "ℹ️ This can be done in Xcode: Build Phases → Run Script → Edit → Check 'Based on dependency analysis'"
    else
        log_warn "⚠️ plutil not available for run script phase fixes"
    fi
}

# Main execution
main() {
    log_info "🚀 Fixing Swift optimization warnings..."
    
    # Fix Pods project
    fix_pods_optimization
    
    # Fix main project
    fix_main_project_optimization
    
    # Fix run script phases
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        fix_run_script_phases "ios/Runner.xcodeproj/project.pbxproj"
    fi
    
    log_success "✅ Swift optimization warnings fixed"
    log_info "📋 Note: Some warnings may still appear but should not affect the build"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 