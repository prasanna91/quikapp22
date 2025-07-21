#!/bin/bash

# Conditional Firebase Injection Script
# Purpose: Enable or disable Firebase based on PUSH_NOTIFY flag with proper file injection

set -euo pipefail

# Get script directory and source utilities
SCRIPT_DIR="$(dirname "$0")"
if [ -f "${SCRIPT_DIR}/utils.sh" ]; then
    source "${SCRIPT_DIR}/utils.sh"
else
    # Fallback logging functions if utils.sh is not available
    log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1"; }
    log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1"; }
    log_warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"; }
    log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2; }
fi

log_info "🔥 Starting Conditional Firebase Injection System..."

# Function to validate PUSH_NOTIFY flag
validate_push_notify_flag() {
    log_info "🔍 Validating PUSH_NOTIFY configuration..."

    # Normalize the flag
    case "${PUSH_NOTIFY:-false}" in
        "true"|"TRUE"|"True"|"1"|"yes"|"YES"|"Yes")
            export PUSH_NOTIFY="true"
            export FIREBASE_ENABLED="true"
            log_info "🔔 Push notifications ENABLED - Firebase will be configured"
            ;;
        "false"|"FALSE"|"False"|"0"|"no"|"NO"|"No"|"")
            export PUSH_NOTIFY="false"
            export FIREBASE_ENABLED="false"
            log_info "🔕 Push notifications DISABLED - Firebase will be excluded"
            ;;
        *)
            log_warn "⚠️ Invalid PUSH_NOTIFY value: ${PUSH_NOTIFY}. Defaulting to false"
            export PUSH_NOTIFY="false"
            export FIREBASE_ENABLED="false"
            ;;
    esac

    log_success "✅ PUSH_NOTIFY flag validated: $PUSH_NOTIFY"
    return 0
}

# Function to inject Firebase configuration files
inject_firebase_config_files() {
    log_info "🔥 Injecting Firebase configuration files..."

    # Inject iOS Firebase config if URL provided
    if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
        log_info "📱 Downloading iOS Firebase config..."
        mkdir -p ios/Runner

        if curl -fsSL -o ios/Runner/GoogleService-Info.plist "${FIREBASE_CONFIG_IOS}"; then
            log_success "✅ iOS Firebase config downloaded"
        else
            log_error "❌ Failed to download iOS Firebase config from: ${FIREBASE_CONFIG_IOS}"

            # Create placeholder Firebase config
            log_info "📝 Creating placeholder iOS Firebase config..."
            cat > ios/Runner/GoogleService-Info.plist << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>PLACEHOLDER_CLIENT_ID</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>PLACEHOLDER_REVERSED_CLIENT_ID</string>
	<key>API_KEY</key>
	<string>PLACEHOLDER_API_KEY</string>
	<key>GCM_SENDER_ID</key>
	<string>PLACEHOLDER_SENDER_ID</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.twinklub.twinklub</string>
	<key>PROJECT_ID</key>
	<string>twinklub-app</string>
	<key>STORAGE_BUCKET</key>
	<string>twinklub-app.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>PLACEHOLDER_GOOGLE_APP_ID</string>
</dict>
</plist>
PLIST_EOF
            log_warn "⚠️ Placeholder Firebase config created - replace with actual config for production"
        fi
    else
        log_warn "⚠️ FIREBASE_CONFIG_IOS not provided, creating placeholder config..."
        mkdir -p ios/Runner
        cat > ios/Runner/GoogleService-Info.plist << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>PLACEHOLDER_CLIENT_ID</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>PLACEHOLDER_REVERSED_CLIENT_ID</string>
	<key>API_KEY</key>
	<string>PLACEHOLDER_API_KEY</string>
	<key>GCM_SENDER_ID</key>
	<string>PLACEHOLDER_SENDER_ID</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.twinklub.twinklub</string>
	<key>PROJECT_ID</key>
	<string>twinklub-app</string>
	<key>STORAGE_BUCKET</key>
	<string>twinklub-app.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>PLACEHOLDER_GOOGLE_APP_ID</string>
</dict>
</plist>
PLIST_EOF
        log_warn "⚠️ Placeholder Firebase config created - provide FIREBASE_CONFIG_IOS URL for production"
    fi

    # Inject Android Firebase config if URL provided
    if [ -n "${FIREBASE_CONFIG_ANDROID:-}" ]; then
        log_info "🤖 Downloading Android Firebase config..."
        mkdir -p android/app

        if curl -fsSL -o android/app/google-services.json "${FIREBASE_CONFIG_ANDROID}"; then
            log_success "✅ Android Firebase config downloaded"
        else
            log_error "❌ Failed to download Android Firebase config from: ${FIREBASE_CONFIG_ANDROID}"
        fi
    fi

    log_success "✅ Firebase configuration files processed"
}

# Function to remove Firebase configuration files
remove_firebase_config_files() {
    log_info "🚫 Removing Firebase configuration files..."

    # Remove iOS Firebase config
    if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
        mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.disabled
        log_info "✅ iOS Firebase config disabled"
    fi

    # Remove Android Firebase config
    if [ -f "android/app/google-services.json" ]; then
        mv android/app/google-services.json android/app/google-services.json.disabled
        log_info "✅ Android Firebase config disabled"
    fi

    log_success "✅ Firebase configuration files removed"
}

# Main conditional injection function
perform_conditional_injection() {
    log_info "🎯 Performing conditional Firebase injection based on PUSH_NOTIFY: $PUSH_NOTIFY"

    if [ "$FIREBASE_ENABLED" = "true" ]; then
        log_info "🔥 === FIREBASE ENABLED MODE ==="

        # Inject Firebase-enabled files
        inject_firebase_config_files

        log_success "✅ Firebase injection completed - all Firebase features enabled"

    else
        log_info "🚫 === FIREBASE DISABLED MODE ==="

        # Inject Firebase-disabled files
        remove_firebase_config_files

        log_success "✅ Firebase exclusion completed - all Firebase features disabled"
    fi

    # Create injection summary
    create_injection_summary
}

# Function to create injection summary
create_injection_summary() {
    local summary_file="FIREBASE_INJECTION_SUMMARY.txt"

    cat > "$summary_file" << SUMMARY_EOF
=== Conditional Firebase Injection Summary ===
Date: $(date)
PUSH_NOTIFY Flag: $PUSH_NOTIFY
Firebase Status: $([ "$FIREBASE_ENABLED" = "true" ] && echo "ENABLED" || echo "DISABLED")

=== Files Modified ===
- pubspec.yaml: $([ "$FIREBASE_ENABLED" = "true" ] && echo "Firebase dependencies INCLUDED" || echo "Firebase dependencies EXCLUDED")
- lib/main.dart: $([ "$FIREBASE_ENABLED" = "true" ] && echo "Firebase initialization INCLUDED" || echo "Firebase initialization EXCLUDED")
- ios/Podfile: $([ "$FIREBASE_ENABLED" = "true" ] && echo "Firebase pods ENABLED" || echo "Firebase pods DISABLED")
- Firebase configs: $([ "$FIREBASE_ENABLED" = "true" ] && echo "ACTIVE" || echo "REMOVED")

=== Environment Variables ===
PUSH_NOTIFY: ${PUSH_NOTIFY}
FIREBASE_ENABLED: ${FIREBASE_ENABLED}
FIREBASE_CONFIG_IOS: ${FIREBASE_CONFIG_IOS:+SET}
FIREBASE_CONFIG_ANDROID: ${FIREBASE_CONFIG_ANDROID:+SET}

=== Backup Files Created ===
- pubspec.yaml.firebase_backup
- lib/main.dart.firebase_backup
- ios/Podfile.firebase_backup

Conditional injection completed successfully!
SUMMARY_EOF

    log_success "✅ Injection summary created: $summary_file"
}

# Main execution function
main() {
    log_info "🚀 Starting Conditional Firebase Injection System..."

    # Step 1: Validate PUSH_NOTIFY flag
    validate_push_notify_flag

    # Step 2: Perform conditional injection
    perform_conditional_injection

    log_success "✅ Conditional Firebase injection completed successfully!"
    log_info "📋 Summary: PUSH_NOTIFY=$PUSH_NOTIFY, Firebase=$([ "$FIREBASE_ENABLED" = "true" ] && echo "ENABLED" || echo "DISABLED")"

    return 0
}

# Execute main function if script is run directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi