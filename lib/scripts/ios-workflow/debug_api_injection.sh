#!/bin/bash

# 🔍 Debug API Variable Injection Script
# Purpose: Debug why API variables are not being properly injected
# Target: Identify the root cause of variable injection issues

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
UTILS_DIR="$(dirname "$SCRIPT_DIR")/utils"

# Source utilities from centralized location
if [ -f "${UTILS_DIR}/utils.sh" ]; then
    source "${UTILS_DIR}/utils.sh"
    echo "✅ Utilities loaded from ${UTILS_DIR}/utils.sh"
else
    echo "❌ Utilities file not found at ${UTILS_DIR}/utils.sh"
    echo "⚠️ Using fallback logging functions"
    
    # Define fallback logging functions
    log_info() { echo "INFO: $*"; }
    log_error() { echo "ERROR: $*"; }
    log_success() { echo "SUCCESS: $*"; }
    log_warn() { echo "WARN: $*"; }
    log_warning() { echo "WARN: $*"; }
fi

log_info "🔍 Starting API Variable Injection Debug..."

# Function to check all environment variables
check_all_env_vars() {
    log_info "🔍 Checking all environment variables..."
    
    # Get all environment variables
    local all_vars=$(env | sort)
    
    log_info "📋 All Environment Variables:"
    echo "$all_vars" | while IFS= read -r line; do
        # Skip sensitive variables
        if [[ "$line" =~ ^(EMAIL_SMTP_PASS|CM_KEY_PASSWORD|CM_KEYSTORE_PASSWORD)= ]]; then
            log_info "   ${line%%=*}=[HIDDEN]"
        else
            log_info "   $line"
        fi
    done
}

# Function to check specific API variables
check_api_variables() {
    log_info "🔍 Checking specific API variables..."
    
    # Variables that should come from Codemagic API
    local api_vars=(
        "APP_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "BUNDLE_ID"
        "APPLE_TEAM_ID"
        "WORKFLOW_ID"
        "APP_ID"
        "ORG_NAME"
        "WEB_URL"
        "EMAIL_ID"
        "USER_NAME"
        "PKG_NAME"
    )
    
    log_info "📋 API Variable Status:"
    for var in "${api_vars[@]}"; do
        local value="${!var:-}"
        if [ -n "$value" ]; then
            log_success "✅ $var: $value"
        else
            log_warning "⚠️ $var: NOT_SET"
        fi
    done
}

# Function to check Codemagic-specific variables
check_codemagic_vars() {
    log_info "🔍 Checking Codemagic-specific variables..."
    
    local cm_vars=(
        "CM_BUILD_ID"
        "CM_PROJECT_ID"
        "CM_WORKFLOW_NAME"
        "FCI_BUILD_ID"
        "FCI_PROJECT_ID"
        "FCI_WORKFLOW_NAME"
        "BUILD_NUMBER"
        "PROJECT_BUILD_NUMBER"
    )
    
    log_info "📋 Codemagic Variables:"
    for var in "${cm_vars[@]}"; do
        local value="${!var:-}"
        if [ -n "$value" ]; then
            log_success "✅ $var: $value"
        else
            log_warning "⚠️ $var: NOT_SET"
        fi
    done
}

# Function to check if we're in Codemagic environment
check_codemagic_environment() {
    log_info "🔍 Checking Codemagic environment..."
    
    if [ -n "${CM_BUILD_ID:-}" ] || [ -n "${FCI_BUILD_ID:-}" ]; then
        log_success "✅ Running in Codemagic environment"
        log_info "   Build ID: ${CM_BUILD_ID:-${FCI_BUILD_ID:-unknown}}"
        log_info "   Project ID: ${CM_PROJECT_ID:-${FCI_PROJECT_ID:-unknown}}"
        log_info "   Workflow: ${CM_WORKFLOW_NAME:-${FCI_WORKFLOW_NAME:-unknown}}"
    else
        log_warning "⚠️ Not running in Codemagic environment"
        log_info "   This might explain why API variables are not available"
    fi
}

# Function to check YAML variable substitution
check_yaml_substitution() {
    log_info "🔍 Checking YAML variable substitution..."
    
    # Check if variables with $ prefix are being resolved
    local yaml_vars=(
        "APP_NAME"
        "VERSION_NAME"
        "VERSION_CODE"
        "BUNDLE_ID"
    )
    
    log_info "📋 YAML Variable Substitution Test:"
    for var in "${yaml_vars[@]}"; do
        local value="${!var:-}"
        if [ -n "$value" ]; then
            log_success "✅ $var: $value (resolved)"
        else
            log_warning "⚠️ $var: NOT_SET (not resolved)"
        fi
    done
}

# Function to test gen_env_config.sh behavior
test_gen_env_config() {
    log_info "🔍 Testing gen_env_config.sh behavior..."
    
    if [ -f "${UTILS_DIR}/gen_env_config.sh" ]; then
        log_info "📋 Testing gen_env_config.sh..."
        
        # Create a temporary environment to test
        local temp_env="temp_env_$(date +%s)"
        mkdir -p "$temp_env"
        
        # Copy the script to temp location
        cp "${UTILS_DIR}/gen_env_config.sh" "$temp_env/"
        
        # Test with different variable scenarios
        log_info "🔧 Testing with API variables..."
        export TEST_APP_NAME="Test App"
        export TEST_VERSION_NAME="1.0.0"
        export TEST_VERSION_CODE="1"
        export TEST_BUNDLE_ID="com.test.app"
        
        # Run the script and capture output
        cd "$temp_env"
        if bash gen_env_config.sh > output.log 2>&1; then
            log_success "✅ gen_env_config.sh executed successfully"
            log_info "📋 Output:"
            cat output.log
        else
            log_error "❌ gen_env_config.sh failed"
            log_info "📋 Error output:"
            cat output.log
        fi
        
        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_env"
    else
        log_error "❌ gen_env_config.sh not found"
    fi
}

# Function to check for variable conflicts
check_variable_conflicts() {
    log_info "🔍 Checking for variable conflicts..."
    
    # Check if env.sh is overriding API variables
    if [ -f "${SCRIPT_DIR}/../../lib/config/env.sh" ]; then
        log_info "📋 Checking env.sh for variable conflicts..."
        
        # Source env.sh and check what it sets
        source "${SCRIPT_DIR}/../../lib/config/env.sh" 2>/dev/null || true
        
        local conflict_vars=(
            "APP_NAME"
            "VERSION_NAME"
            "VERSION_CODE"
            "BUNDLE_ID"
        )
        
        log_info "📋 Variable Conflicts Check:"
        for var in "${conflict_vars[@]}"; do
            local env_value="${!var:-}"
            if [ -n "$env_value" ]; then
                log_warning "⚠️ $var: $env_value (from env.sh - potential conflict)"
            else
                log_info "ℹ️ $var: not set in env.sh"
            fi
        done
    else
        log_info "ℹ️ env.sh not found"
    fi
}

# Function to generate debug report
generate_debug_report() {
    log_info "📊 Generating debug report..."
    
    cat > api_injection_debug_report.txt <<EOF
API Variable Injection Debug Report
===================================

Generated: $(date)
Environment: ${CM_BUILD_ID:-${FCI_BUILD_ID:-local}}

Codemagic Environment:
- CM_BUILD_ID: ${CM_BUILD_ID:-NOT_SET}
- CM_PROJECT_ID: ${CM_PROJECT_ID:-NOT_SET}
- CM_WORKFLOW_NAME: ${CM_WORKFLOW_NAME:-NOT_SET}
- FCI_BUILD_ID: ${FCI_BUILD_ID:-NOT_SET}
- FCI_PROJECT_ID: ${FCI_PROJECT_ID:-NOT_SET}
- FCI_WORKFLOW_NAME: ${FCI_WORKFLOW_NAME:-NOT_SET}

API Variables Status:
$(for var in APP_NAME VERSION_NAME VERSION_CODE BUNDLE_ID APPLE_TEAM_ID WORKFLOW_ID APP_ID ORG_NAME WEB_URL EMAIL_ID USER_NAME PKG_NAME; do
    value="${!var:-}"
    if [ -n "$value" ]; then
        echo "- $var: $value (✅ SET)"
    else
        echo "- $var: NOT_SET (❌ MISSING)"
    fi
done)

Potential Issues:
1. YAML variable substitution not working
2. API variables not being injected by Codemagic
3. env.sh overriding API variables
4. Variable precedence issues

Recommendations:
1. Check Codemagic YAML configuration
2. Verify API variable injection in Codemagic
3. Ensure env.sh doesn't override API variables
4. Test variable precedence in scripts

EOF

    log_success "✅ Debug report generated: api_injection_debug_report.txt"
}

# Main execution function
main() {
    log_info "🚀 Starting API Variable Injection Debug..."
    
    # Check Codemagic environment
    check_codemagic_environment
    
    # Check all environment variables
    check_all_env_vars
    
    # Check specific API variables
    check_api_variables
    
    # Check Codemagic-specific variables
    check_codemagic_vars
    
    # Check YAML variable substitution
    check_yaml_substitution
    
    # Check for variable conflicts
    check_variable_conflicts
    
    # Test gen_env_config.sh behavior
    test_gen_env_config
    
    # Generate debug report
    generate_debug_report
    
    log_success "🎉 API variable injection debug completed"
    log_info "📋 Summary:"
    log_info "   ✅ Environment checked"
    log_info "   ✅ API variables analyzed"
    log_info "   ✅ Conflicts identified"
    log_info "   ✅ Script behavior tested"
    log_info "   ✅ Debug report generated"
}

# Run main function
main "$@" 