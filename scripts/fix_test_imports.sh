#!/bin/bash
set -euo pipefail

# Logging functions
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIX] $1"; }
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIX] 🔍 $1"; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIX] ✅ $1"; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIX] ⚠️ $1"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [TEST_FIX] ❌ $1"; }

log "🧪 Fixing Test File Imports"

# Get the current package name from pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    PACKAGE_NAME=$(grep "^name:" pubspec.yaml | sed 's/name: //' | tr -d ' ')
    log_info "Package name from pubspec.yaml: $PACKAGE_NAME"
else
    log_error "pubspec.yaml not found"
    exit 1
fi

# Fix test/widget_test.dart
if [ -f "test/widget_test.dart" ]; then
    log_info "Fixing test/widget_test.dart"
    
    # Create backup
    cp test/widget_test.dart test/widget_test.dart.bak
    
    # Update the import statement
    sed -i '' "s/import 'package:quikapp22\/main.dart';/import 'package:$PACKAGE_NAME\/main.dart';/g" test/widget_test.dart
    
    # Check if the file was updated
    if grep -q "package:$PACKAGE_NAME/main.dart" test/widget_test.dart; then
        log_success "✅ Updated test/widget_test.dart import"
    else
        log_warning "⚠️ Failed to update test/widget_test.dart import"
    fi
else
    log_warning "⚠️ test/widget_test.dart not found"
fi

# Fix any other test files that might exist
find test/ -name "*.dart" -type f | while read -r test_file; do
    if [ "$test_file" != "test/widget_test.dart" ]; then
        log_info "Fixing $test_file"
        
        # Create backup
        cp "$test_file" "$test_file.bak"
        
        # Update any quikapp22 imports
        sed -i '' "s/package:quikapp22/package:$PACKAGE_NAME/g" "$test_file"
        
        log_success "✅ Updated $test_file"
    fi
done

# Also fix any lib/ files that might have hardcoded imports
find lib/ -name "*.dart" -type f | while read -r dart_file; do
    if grep -q "package:quikapp22" "$dart_file"; then
        log_info "Fixing $dart_file"
        
        # Create backup
        cp "$dart_file" "$dart_file.bak"
        
        # Update any quikapp22 imports
        sed -i '' "s/package:quikapp22/package:$PACKAGE_NAME/g" "$dart_file"
        
        log_success "✅ Updated $dart_file"
    fi
done

log_success "✅ Test file imports fixed successfully"
exit 0 