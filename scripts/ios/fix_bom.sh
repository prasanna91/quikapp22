#!/bin/bash

# BOM Fix Script for iOS Build
# Purpose: Fix BOM characters in critical script files

set -e

echo "🧹 Fixing BOM characters in script files..."

# List of critical script files to check
script_files=(
    "lib/scripts/ios/main.sh"
    "lib/scripts/ios/email_notifications.sh"
    "lib/scripts/ios/comprehensive_certificate_validation.sh"
    "lib/scripts/ios/setup_environment.sh"
    "lib/scripts/ios/validate_profile_type.sh"
    "lib/scripts/ios/handle_certificates.sh"
    "lib/scripts/ios/code_signing.sh"
    "lib/scripts/ios/branding.sh"
    "lib/scripts/utils/download_custom_icons.sh"
)

for script_file in "${script_files[@]}"; do
    if [ -f "$script_file" ]; then
        echo "🔍 Checking $script_file..."
        
        # Check if file has BOM using file command
        if command -v file >/dev/null 2>&1; then
            if file "$script_file" 2>/dev/null | grep -q "UTF-8 Unicode (with BOM)"; then
                echo "⚠️ BOM detected in $script_file, removing..."
                # Create a temporary file without BOM
                if tail -c +4 "$script_file" > "${script_file}.tmp" 2>/dev/null; then
                    mv "${script_file}.tmp" "$script_file"
                    chmod +x "$script_file"
                    echo "✅ BOM removed from $script_file"
                else
                    echo "❌ Failed to remove BOM from $script_file"
                    rm -f "${script_file}.tmp" 2>/dev/null
                fi
            fi
        fi
        
        # Check first line for invalid shebang
        if [ -f "$script_file" ]; then
            first_line=$(head -1 "$script_file" 2>/dev/null | tr -d '\r')
            
            # Check if first line doesn't start with proper shebang
            if [[ "$first_line" != "#!/bin/bash"* ]] && [[ "$first_line" != "#!/bin/sh"* ]] && [[ "$first_line" != "#!/usr/bin/env bash"* ]]; then
                echo "⚠️ Invalid shebang detected in $script_file, attempting to fix..."
                
                # Try to find the actual shebang line
                shebang_line=$(grep -m 1 "^#!" "$script_file" 2>/dev/null)
                
                if [ -n "$shebang_line" ]; then
                    # Create a new file starting from the shebang
                    temp_file="${script_file}.tmp"
                    if grep -A 1000 "^#!" "$script_file" > "$temp_file" 2>/dev/null; then
                        if [ -s "$temp_file" ]; then
                            mv "$temp_file" "$script_file"
                            chmod +x "$script_file"
                            echo "✅ Fixed shebang in $script_file"
                        else
                            rm -f "$temp_file"
                            echo "❌ Failed to fix shebang in $script_file - empty result"
                        fi
                    else
                        rm -f "$temp_file"
                        echo "❌ Failed to extract content from $script_file"
                    fi
                else
                    echo "❌ No valid shebang found in $script_file"
                    
                    # Try to create a new file with proper shebang
                    if [ -s "$script_file" ]; then
                        temp_file="${script_file}.tmp"
                        echo "#!/bin/bash" > "$temp_file"
                        echo "" >> "$temp_file"
                        cat "$script_file" >> "$temp_file" 2>/dev/null
                        if [ -s "$temp_file" ]; then
                            mv "$temp_file" "$script_file"
                            chmod +x "$script_file"
                            echo "✅ Created new file with proper shebang for $script_file"
                        else
                            rm -f "$temp_file"
                            echo "❌ Failed to create new file for $script_file"
                        fi
                    fi
                fi
            else
                echo "✅ $script_file has valid shebang"
            fi
        fi
    else
        echo "⚠️ Script file not found: $script_file"
    fi
done

echo "✅ BOM fix completed" 