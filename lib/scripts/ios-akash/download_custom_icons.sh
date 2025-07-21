#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log()    { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error()  { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; }
success(){ echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"; }
warning(){ echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }

handle_error() {
    error "Command '$BASH_COMMAND' failed at line $LINENO"
    exit 1
}
trap 'handle_error' ERR

download_custom_icons() {
    local bottom_menu_items="$1"

    if [ -z "$bottom_menu_items" ]; then
        log "No BOTTOMMENU_ITEMS provided, skipping custom icon download"
        return 0
    fi

    log "Processing BOTTOMMENU_ITEMS for custom icons..."

    mkdir -p assets/icons

    # Create a temporary Python script
    cat > /tmp/download_icons.py << 'PYTHON_EOF'
import json
import os
import sys
import requests

bottom_menu_items = sys.argv[1]

try:
    menu_items = json.loads(bottom_menu_items)
    if not isinstance(menu_items, list):
        print("ERROR_INVALID_JSON_ARRAY")
        sys.exit(1)

    downloaded_count = 0
    for item in menu_items:
        if not isinstance(item, dict):
            continue
        icon_data = item.get('icon')
        label = item.get('label', 'unknown')
        if not isinstance(icon_data, dict) or icon_data.get('type') != 'custom':
            continue
        icon_url = icon_data.get('icon_url')
        if not icon_url:
            continue

        label_sanitized = label.lower().replace(' ', '_').replace('-', '_')
        filename = f'{label_sanitized}.svg'
        filepath = f'assets/icons/{filename}'

        if not os.path.exists(filepath):
            try:
                resp = requests.get(icon_url, timeout=30)
                resp.raise_for_status()
                with open(filepath, 'wb') as f:
                    f.write(resp.content)
                downloaded_count += 1
            except Exception:
                continue

    print(f"DOWNLOADED_COUNT:{downloaded_count}")

except json.JSONDecodeError:
    print("ERROR_INVALID_JSON")
    sys.exit(1)
except Exception:
    print("ERROR_PROCESSING")
    sys.exit(1)
PYTHON_EOF

    # Run the Python script
    local output=""
    if python3 /tmp/download_icons.py "$bottom_menu_items" 2>/dev/null; then
        output=$(python3 /tmp/download_icons.py "$bottom_menu_items" 2>/dev/null)
        if [[ "$output" == DOWNLOADED_COUNT:* ]]; then
            local count=${output#DOWNLOADED_COUNT:}
            success "Downloaded $count new custom icon(s)"
            rm -f /tmp/download_icons.py
            return 0
        fi
    fi

    # Clean up and handle errors
    rm -f /tmp/download_icons.py
    
    if [[ "$output" == ERROR_INVALID_JSON* ]]; then
        error "BOTTOMMENU_ITEMS contains invalid JSON"
        return 1
    elif [[ "$output" == ERROR_INVALID_JSON_ARRAY ]]; then
        error "BOTTOMMENU_ITEMS is not a JSON array"
        return 1
    elif [[ "$output" == ERROR_PROCESSING ]]; then
        error "An error occurred processing BOTTOMMENU_ITEMS"
        return 1
    else
        warning "Python script failed, continuing without custom icons"
        return 0
    fi
}

main() {
    log "Starting custom icons download process..."

    if [ "${IS_BOTTOMMENU:-false}" != "true" ]; then
        log "Bottom menu disabled (IS_BOTTOMMENU=false), skipping custom icon download"
        return 0
    fi

    if [ -z "${BOTTOMMENU_ITEMS:-}" ]; then
        warning "BOTTOMMENU_ITEMS environment variable not set"
        log "Skipping custom icon download"
        return 0
    fi

    download_custom_icons "$BOTTOMMENU_ITEMS"

    log "Custom icons download process completed"
}

main "$@"
