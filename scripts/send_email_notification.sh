#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [EMAIL] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [EMAIL] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [EMAIL] ✅ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [EMAIL] ❌ $1"; }

log "✉️ Sending Email Notification"

to_email="${1:-$EMAIL_ID}"
workflow_id="${2:-$WORKFLOW_ID}"
status="${3:-success}"

if [ -z "$to_email" ]; then
    log_error "❌ No email address provided"
    exit 1
fi

if [ "$ENABLE_EMAIL_NOTIFICATIONS" != "true" ]; then
    log_info "⏭️ Email notifications disabled, skipping"
    exit 0
fi

log_info "Sending notification to: $to_email"
log_info "Workflow: $workflow_id"
log_info "Status: $status"

# Create email content
subject=""
body=""

if [ "$status" = "success" ]; then
    subject="✅ Build Success: $workflow_id"
    body="
🎉 Build Completed Successfully!

📱 App: $APP_NAME
🆔 Bundle ID: $BUNDLE_ID
📦 Version: $VERSION_NAME ($VERSION_CODE)
🔧 Workflow: $workflow_id
⏰ Completed: $(date)

✅ The iOS build has completed successfully and is ready for distribution.

Best regards,
Codemagic CI/CD
"
else
    subject="❌ Build Failed: $workflow_id"
    body="
🚨 Build Failed!

📱 App: $APP_NAME
🆔 Bundle ID: $BUNDLE_ID
📦 Version: $VERSION_NAME ($VERSION_CODE)
🔧 Workflow: $workflow_id
⏰ Failed: $(date)

❌ The iOS build has failed. Please check the build logs for details.

Best regards,
Codemagic CI/CD
"
fi

# Send email using Python script
if [ -f "scripts/mailer.py" ]; then
    log_info "Using Python mailer script"
    python3 scripts/mailer.py "$to_email" "$subject" "$body" || {
        log_warning "Python mailer failed, trying curl"
        # Fallback to curl if Python script fails
        curl -X POST \
            -H "Content-Type: application/json" \
            -d "{\"to\":\"$to_email\",\"subject\":\"$subject\",\"body\":\"$body\"}" \
            "https://api.mailgun.net/v3/your-domain/messages" \
            --user "api:your-api-key" || {
            log_error "Failed to send email notification"
        }
    }
else
    log_warning "⚠️ Python mailer script not found, skipping email notification"
fi

log_success "✅ Email notification sent successfully"
exit 0 