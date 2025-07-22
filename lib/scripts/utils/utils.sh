#!/bin/bash

# Simple Utilities Script for iOS Workflow
# Purpose: Provide basic logging and utility functions

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $*"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*"
}

# Utility functions
validate_required_variable() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    if [ -z "$var_value" ]; then
        log_error "Required variable $var_name is not set"
        return 1
    fi
    
    log_info "Variable $var_name is set: $var_value"
    return 0
}

check_file_exists() {
    local file_path="$1"
    local description="${2:-File}"
    
    if [ -f "$file_path" ]; then
        log_success "$description exists: $file_path"
        return 0
    else
        log_error "$description not found: $file_path"
        return 1
    fi
}

check_directory_exists() {
    local dir_path="$1"
    local description="${2:-Directory}"
    
    if [ -d "$dir_path" ]; then
        log_success "$description exists: $dir_path"
        return 0
    else
        log_error "$description not found: $dir_path"
        return 1
    fi
}

run_command() {
    local command="$1"
    local description="${2:-Command}"
    
    log_info "Running: $description"
    if eval "$command"; then
        log_success "$description completed successfully"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# Environment validation
validate_ios_environment() {
    log_info "Validating iOS build environment..."
    
    local required_vars=(
        "BUNDLE_ID"
        "APPLE_TEAM_ID"
        "APP_STORE_CONNECT_KEY_IDENTIFIER"
        "APP_STORE_CONNECT_ISSUER_ID"
        "APP_STORE_CONNECT_API_KEY_URL"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! validate_required_variable "$var"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    log_success "All required environment variables are set"
    return 0
}

# File system utilities
ensure_directory() {
    local dir_path="$1"
    
    if [ ! -d "$dir_path" ]; then
        log_info "Creating directory: $dir_path"
        mkdir -p "$dir_path"
    fi
    
    if [ -d "$dir_path" ]; then
        log_success "Directory ready: $dir_path"
        return 0
    else
        log_error "Failed to create directory: $dir_path"
        return 1
    fi
}

# Xcode utilities
check_xcode_available() {
    if command -v xcodebuild >/dev/null 2>&1; then
        log_success "Xcode is available"
        return 0
    else
        log_error "Xcode is not available"
        return 1
    fi
}

check_flutter_available() {
    if command -v flutter >/dev/null 2>&1; then
        log_success "Flutter is available"
        return 0
    else
        log_error "Flutter is not available"
        return 1
    fi
}

# Export utilities
find_ipa_files() {
    local search_path="${1:-output/ios}"
    
    if [ -d "$search_path" ]; then
        find "$search_path" -name "*.ipa" -type f 2>/dev/null || true
    else
        echo ""
    fi
}

get_ipa_size() {
    local ipa_file="$1"
    
    if [ -f "$ipa_file" ]; then
        stat -f%z "$ipa_file" 2>/dev/null || stat -c%s "$ipa_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
} 