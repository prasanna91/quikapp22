#!/bin/bash

# Fix env_config.dart syntax script
# This script ensures the env_config.dart file has the correct syntax before build

set -e

echo "🔧 Fixing env_config.dart syntax..."

# Check if the file exists
if [ ! -f "lib/config/env_config.dart" ]; then
    echo "❌ env_config.dart file not found"
    exit 1
fi

# Create a backup
cp lib/config/env_config.dart lib/config/env_config.dart.backup

# Fix the bottommenuItems syntax using sed
sed -i.bak 's/static const String bottommenuItems = "\[.*\]";/static const String bottommenuItems = r"[]";/' lib/config/env_config.dart
sed -i.bak 's/static const String bottommenuItems = '\''\[.*\]'\'';/static const String bottommenuItems = r"[]";/' lib/config/env_config.dart

# Verify the fix
if grep -q 'static const String bottommenuItems = r"[]";' lib/config/env_config.dart; then
    echo "✅ env_config.dart syntax fixed successfully"
else
    echo "❌ Failed to fix env_config.dart syntax"
    # Restore backup
    mv lib/config/env_config.dart.backup lib/config/env_config.dart
    exit 1
fi

# Remove backup files
rm -f lib/config/env_config.dart.bak

echo "✅ env_config.dart syntax fix completed" 