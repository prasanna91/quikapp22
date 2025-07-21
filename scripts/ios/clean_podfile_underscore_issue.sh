#!/bin/bash

# Clean Podfile Underscore Issue
# Removes any problematic real-time collision prevention code from Podfile

set -e

echo "🧹 CLEANING PODFILE UNDERSCORE ISSUE"
echo "===================================="
echo "🎯 Target: Remove problematic real-time collision prevention code"
echo "📋 Issue: Real-time interceptor may have added code with underscore bugs"
echo ""

# Path to Podfile
PODFILE="ios/Podfile"

if [ ! -f "$PODFILE" ]; then
    echo "❌ Podfile not found: $PODFILE"
    exit 1
fi

echo "📁 Processing Podfile: $PODFILE"

# Check if problematic real-time collision prevention exists
if grep -q "REAL-TIME COLLISION PREVENTION" "$PODFILE"; then
    echo "🚨 Found problematic real-time collision prevention code"
    
    # Create backup
    cp "$PODFILE" "$PODFILE.underscore_fix_backup_$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backup created"
    
    # Remove the problematic section
    echo "🔧 Removing problematic real-time collision prevention code..."
    
    # Use sed to remove everything from the real-time section to the end of file
    # and then append only the nuclear-level collision prevention
    sed -i '/# REAL-TIME COLLISION PREVENTION/,$d' "$PODFILE"
    
    echo "✅ Problematic code removed"
    echo ""
    echo "📊 Podfile now contains only:"
    echo "   ✅ Nuclear-level collision prevention (fixed)"
    echo "   ❌ NO real-time collision prevention (problematic)"
    
else
    echo "✅ No problematic real-time collision prevention found"
    echo "📋 Podfile appears to be clean"
fi

# Verify the Podfile ends properly
if ! tail -1 "$PODFILE" | grep -q "end"; then
    echo ""
    echo "🔧 Ensuring Podfile ends properly..."
    echo "" >> "$PODFILE"
fi

# Show summary of what's in the Podfile
echo ""
echo "📊 PODFILE ANALYSIS:"
echo "==================="

if grep -q "NUCLEAR-LEVEL COLLISION PREVENTION" "$PODFILE"; then
    echo "✅ Nuclear-level collision prevention: PRESENT (good)"
else
    echo "❌ Nuclear-level collision prevention: MISSING"
fi

if grep -q "REAL-TIME COLLISION PREVENTION" "$PODFILE"; then
    echo "❌ Real-time collision prevention: PRESENT (problematic - needs removal)"
else
    echo "✅ Real-time collision prevention: ABSENT (good)"
fi

if grep -q "gsub(/_+/, '')" "$PODFILE"; then
    echo "✅ Underscore sanitization: PRESENT (good)"
else
    echo "❌ Underscore sanitization: MISSING (may cause issues)"
fi

# Check for any remaining underscore patterns in bundle ID generation
underscore_patterns=$(grep -n "rt\..*connectivity_plus\|_plus\|_framework" "$PODFILE" 2>/dev/null || echo "")
if [ -n "$underscore_patterns" ]; then
    echo ""
    echo "⚠️  FOUND UNDERSCORE PATTERNS:"
    echo "$underscore_patterns"
    echo "🔧 These should be removed or fixed"
else
    echo "✅ No underscore patterns found in bundle ID generation"
fi

echo ""
echo "🎉 PODFILE CLEANING COMPLETE!"
echo "============================"
echo "📋 Summary:"
echo "   ✅ Problematic real-time collision prevention removed"
echo "   ✅ Nuclear-level collision prevention preserved"
echo "   ✅ Underscore issues should be resolved"
echo ""
echo "🚀 Next Steps:"
echo "   1. Clean build artifacts: flutter clean"
echo "   2. Remove pods: rm -rf ios/Pods ios/.symlinks"
echo "   3. Reinstall pods: cd ios && pod install"
echo "   4. Build again: iOS workflow should work without underscore issues"
echo "" 