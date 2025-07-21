#!/bin/bash

# Dynamic Bundle Identifier Injection for Reusable Projects
# Purpose: Support multiple apps/profiles with different bundle identifiers
# Usage: Automatically injects correct bundle IDs based on environment variables

set -euo pipefail

echo "🔄 DYNAMIC BUNDLE IDENTIFIER INJECTION"
echo "======================================"
echo "🎯 Multi-Profile Reusable Project Support"
echo ""

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] ✅ $*"; }
    log_warn() { echo "[WARN] ⚠️ $*"; }
    log_error() { echo "[ERROR] ❌ $*"; }
fi

# Configuration
PROJECT_ROOT=$(pwd)
IOS_DIR="$PROJECT_ROOT/ios"
PROJECT_FILE="$IOS_DIR/Runner.xcodeproj/project.pbxproj"

# Function to get bundle identifier configuration
get_bundle_config() {
    log_info "📋 Determining bundle identifier configuration..."
    
    # Primary: Use BUNDLE_ID environment variable
    if [ -n "${BUNDLE_ID:-}" ]; then
        MAIN_BUNDLE_ID="$BUNDLE_ID"
        log_info "✅ Using BUNDLE_ID environment variable: $MAIN_BUNDLE_ID"
    else
        # Fallback: Check for common environment variables
        if [ -n "${APP_ID:-}" ]; then
            MAIN_BUNDLE_ID="$APP_ID"
            log_info "✅ Using APP_ID environment variable: $MAIN_BUNDLE_ID"
        elif [ -n "${PRODUCT_BUNDLE_IDENTIFIER:-}" ]; then
            MAIN_BUNDLE_ID="$PRODUCT_BUNDLE_IDENTIFIER"
            log_info "✅ Using PRODUCT_BUNDLE_IDENTIFIER: $MAIN_BUNDLE_ID"
        else
            # Default fallback for development
            MAIN_BUNDLE_ID="com.example.app"
            log_warn "⚠️ No bundle identifier specified, using default: $MAIN_BUNDLE_ID"
            log_warn "   Set BUNDLE_ID environment variable for production builds"
        fi
    fi
    
    # Generate test bundle identifier
    TEST_BUNDLE_ID="${MAIN_BUNDLE_ID}.tests"
    
    log_info "📊 Bundle Identifier Configuration:"
    log_info "   Main App: $MAIN_BUNDLE_ID"
    log_info "   Tests: $TEST_BUNDLE_ID"
    
    # Export for use in other scripts
    export MAIN_BUNDLE_ID
    export TEST_BUNDLE_ID
}

# Function to inject bundle identifiers dynamically
inject_bundle_identifiers() {
    log_info "💉 Injecting dynamic bundle identifiers..."
    
    # Simple but effective approach: replace ALL existing bundle IDs
    # with proper main/test distinction
    
    # First, set everything to main bundle ID
    sed -i.bak "s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;/g" "$PROJECT_FILE"
    
    # Then, fix test target configurations to use test bundle ID
    # Target RunnerTests configurations (look for TEST_HOST pattern)
    sed -i '' '/TEST_HOST.*Runner\.app/,/}/{
        s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = '"$TEST_BUNDLE_ID"';/g
    }' "$PROJECT_FILE"
    
    # Also target any configuration with BUNDLE_LOADER (test configurations)
    sed -i '' '/BUNDLE_LOADER.*TEST_HOST/,/}/{
        s/PRODUCT_BUNDLE_IDENTIFIER = [^;]*;/PRODUCT_BUNDLE_IDENTIFIER = '"$TEST_BUNDLE_ID"';/g
    }' "$PROJECT_FILE"
    
    # Clean up backup
    rm -f "${PROJECT_FILE}.bak"
    
    log_success "✅ Bundle identifiers injected successfully"
}

# Function to validate bundle identifier injection
validate_injection() {
    log_info "🔍 Validating bundle identifier injection..."
    
    # Count occurrences
    local main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $MAIN_BUNDLE_ID;" "$PROJECT_FILE" 2>/dev/null || echo "0")
    local test_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = $TEST_BUNDLE_ID;" "$PROJECT_FILE" 2>/dev/null || echo "0")
    
    log_info "📊 Injection Results:"
    log_info "   Main app configurations: $main_count"
    log_info "   Test configurations: $test_count"
    
    # Show current bundle identifiers
    log_info "📋 Current Bundle Identifiers in Project:"
    grep -n "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | sed 's/^/   /'
    
    # Validation logic
    if [ "$main_count" -ge 1 ] && [ "$test_count" -ge 1 ]; then
        log_success "✅ Bundle identifier injection successful"
        return 0
    else
        log_error "❌ Bundle identifier injection failed"
        log_error "Expected: ≥1 main app configs, ≥1 test configs"
        log_error "Actual: $main_count main, $test_count test"
        return 1
    fi
}

# Main execution function
main() {
    log_info "🚀 Starting Dynamic Bundle Identifier Injection..."
    log_info "🎯 Multi-Profile Reusable Project Support"
    log_info ""
    
    # Check if project file exists
    if [ ! -f "$PROJECT_FILE" ]; then
        log_error "Project file not found: $PROJECT_FILE"
        return 1
    fi
    
    # Step 1: Get configuration
    get_bundle_config
    
    # Step 2: Backup project file
    log_info "📋 Creating project file backup..."
    cp "$PROJECT_FILE" "${PROJECT_FILE}.dynamic_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Step 3: Inject bundle identifiers
    if ! inject_bundle_identifiers; then
        log_error "Failed to inject bundle identifiers"
        return 1
    fi
    
    # Step 4: Validate injection
    if ! validate_injection; then
        log_error "Bundle identifier validation failed"
        return 1
    fi
    
    # Success summary
    log_success "🎉 DYNAMIC BUNDLE IDENTIFIER INJECTION COMPLETE!"
    log_success "=============================================="
    log_info ""
    log_info "📊 CONFIGURATION APPLIED:"
    log_info "   �� Main App: $MAIN_BUNDLE_ID"
    log_info "   🧪 Tests: $TEST_BUNDLE_ID"
    log_info "   🎨 App Name: ${APP_NAME:-$(basename "$MAIN_BUNDLE_ID")}"
    log_info ""
    log_info "🔄 REUSABLE PROJECT READY FOR MULTIPLE APPS:"
    log_info "   ✅ Dynamic bundle identifiers applied"
    log_info "   ✅ Collision prevention active"
    log_info "   ✅ Multi-profile support enabled"
    log_info ""
    log_info "🚀 USAGE FOR DIFFERENT APPS:"
    log_info "   export BUNDLE_ID='com.yourcompany.app1'"
    log_info "   ./lib/scripts/ios/dynamic_bundle_identifier_injection.sh"
    log_info "   # Run ios-workflow"
    log_info ""
    log_info "   export BUNDLE_ID='com.yourcompany.app2'" 
    log_info "   ./lib/scripts/ios/dynamic_bundle_identifier_injection.sh"
    log_info "   # Run ios-workflow"
    log_info ""
    
    return 0
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 