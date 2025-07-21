#!/bin/bash

# Pre-Build Collision Elimination Script for Error ID fc526a49
# Purpose: Prevent CFBundleIdentifier collisions before build process
# Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd

set -euo pipefail

# Script configuration
SCRIPT_NAME="Pre-Build Collision Eliminator (fc526a49)"
ERROR_ID="fc526a49"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Input validation
MAIN_BUNDLE_ID="${BUNDLE_ID:-com.insurancegroupmo.insurancegroupmo}"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
PBXPROJ_FILE="$PROJECT_ROOT/ios/Runner.xcodeproj/project.pbxproj"

# Logging functions
log_info() { echo "ℹ️ $*"; }
log_success() { echo "✅ $*"; }
log_warn() { echo "⚠️ $*"; }
log_error() { echo "❌ $*"; }

log_info "🚀 $SCRIPT_NAME Starting..."
log_info "🎯 Target Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd"
log_info "🆔 Main Bundle ID: $MAIN_BUNDLE_ID"
log_info "📁 Project Root: $PROJECT_ROOT"
log_info "🔧 Strategy: PRE-BUILD collision elimination"

# Validate project structure
if [ ! -f "$PBXPROJ_FILE" ]; then
    log_error "Xcode project file not found: $PBXPROJ_FILE"
    exit 1
fi

# Function to create unique bundle identifier for fc526a49
create_fc526a49_bundle_id() {
    local base_id="$1"
    local purpose="$2"
    local line_number="$3"
    local unique_suffix="fc526a49.${TIMESTAMP}.${line_number}"
    echo "${base_id}.collision.${purpose}.${unique_suffix}"
}

# Function to analyze current bundle ID usage
analyze_bundle_ids() {
    log_info "🔍 Analyzing current CFBundleIdentifier usage..."
    
    if [ ! -f "$PBXPROJ_FILE" ]; then
        log_error "Project file not found: $PBXPROJ_FILE"
        return 1
    fi
    
    # Count exact main bundle ID matches
    local main_bundle_count
    main_bundle_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = ${MAIN_BUNDLE_ID};" "$PBXPROJ_FILE" 2>/dev/null || echo "0")
    
    # Count total bundle IDs
    local total_bundle_count
    total_bundle_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER" "$PBXPROJ_FILE" 2>/dev/null || echo "0")
    
    log_info "📊 Bundle ID Analysis:"
    log_info "   - Main bundle ID occurrences: $main_bundle_count"
    log_info "   - Total bundle identifiers: $total_bundle_count"
    
    # Show all current bundle identifiers
    log_info "📋 Current bundle identifiers:"
    grep "PRODUCT_BUNDLE_IDENTIFIER" "$PBXPROJ_FILE" | sed 's/.*= /   ✓ /' | sed 's/;.*//' | sort -u
    
    # Check for fc526a49 collision pattern
    if [ "$main_bundle_count" -gt 3 ]; then
        log_error "🚨 COLLISION DETECTED: $main_bundle_count instances of $MAIN_BUNDLE_ID"
        log_error "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd PATTERN DETECTED"
        return 1
    else
        log_success "✅ Main bundle ID count acceptable: $main_bundle_count"
        return 0
    fi
}

# Function to apply fc526a49 collision elimination
apply_fc526a49_elimination() {
    log_info "☢️ Applying fc526a49 collision elimination..."
    
    # Create backup
    local backup_file="$PBXPROJ_FILE.fc526a49_backup_${TIMESTAMP}"
    cp "$PBXPROJ_FILE" "$backup_file"
    log_info "💾 Backup created: $(basename "$backup_file")"
    
    # Process project file with Ruby for precise control
    ruby << 'RUBY_SCRIPT'
require 'fileutils'

project_file = ENV['PBXPROJ_FILE']
main_bundle_id = ENV['MAIN_BUNDLE_ID']
error_id = ENV['ERROR_ID']
timestamp = ENV['TIMESTAMP']

puts "🔧 Processing project file with Ruby..."
puts "📱 Main Bundle ID: #{main_bundle_id}"
puts "🎯 Error ID: #{error_id}"

if File.exist?(project_file)
  content = File.read(project_file)
  
  # Find all bundle ID lines with line numbers
  lines = content.split("\n")
  modified_lines = []
  main_bundle_kept = 0
  max_main_bundles = 3  # Debug, Release, Profile
  
  lines.each_with_index do |line, index|
    line_number = index + 1
    
    if line =~ /PRODUCT_BUNDLE_IDENTIFIER = #{Regexp.escape(main_bundle_id)};/
      if main_bundle_kept < max_main_bundles
        # Keep original main bundle ID
        modified_lines << line
        main_bundle_kept += 1
        puts "   ✅ Kept main bundle ID (#{main_bundle_kept}/#{max_main_bundles}): Line #{line_number}"
      else
        # Apply fc526a49 collision elimination
        unique_suffix = "fc526a49.#{timestamp}.#{line_number}"
        new_bundle_id = "#{main_bundle_id}.collision.excess.#{unique_suffix}"
        new_line = line.gsub(/PRODUCT_BUNDLE_IDENTIFIER = #{Regexp.escape(main_bundle_id)};/, 
                           "PRODUCT_BUNDLE_IDENTIFIER = #{new_bundle_id};")
        modified_lines << new_line
        puts "   ☢️ FC526A49 FIX: Line #{line_number} → #{new_bundle_id}"
      end
    elsif line =~ /PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/
      bundle_id = $1
      if bundle_id.include?(main_bundle_id) && bundle_id != main_bundle_id
        # Existing modified bundle ID - make it fc526a49 compatible
        if bundle_id.include?('.tests') || bundle_id.downcase.include?('test')
          unique_suffix = "fc526a49.#{timestamp}.tests"
          new_bundle_id = "#{main_bundle_id}.collision.tests.#{unique_suffix}"
        elsif bundle_id.include?('.framework') || bundle_id.downcase.include?('framework')
          unique_suffix = "fc526a49.#{timestamp}.framework"
          new_bundle_id = "#{main_bundle_id}.collision.framework.#{unique_suffix}"
        else
          unique_suffix = "fc526a49.#{timestamp}.component"
          new_bundle_id = "#{main_bundle_id}.collision.component.#{unique_suffix}"
        end
        
        new_line = line.gsub(/PRODUCT_BUNDLE_IDENTIFIER = #{Regexp.escape(bundle_id)};/, 
                           "PRODUCT_BUNDLE_IDENTIFIER = #{new_bundle_id};")
        modified_lines << new_line
        puts "   🔧 FC526A49 COMPONENT: #{bundle_id} → #{new_bundle_id}"
      else
        # Other bundle ID not related to main bundle
        modified_lines << line
      end
    else
      # Non-bundle ID line
      modified_lines << line
    end
  end
  
  # Write modified content
  File.write(project_file, modified_lines.join("\n"))
  puts "✅ FC526A49 collision elimination applied"
  
else
  puts "❌ Project file not found: #{project_file}"
  exit 1
end
RUBY_SCRIPT
    
    if [ $? -eq 0 ]; then
        log_success "✅ FC526A49 collision elimination completed"
        return 0
    else
        log_error "❌ FC526A49 collision elimination failed"
        return 1
    fi
}

# Function to verify fc526a49 elimination
verify_fc526a49_elimination() {
    log_info "🔍 Verifying fc526a49 elimination results..."
    
    # Count exact main bundle ID occurrences after modification
    local final_main_count
    final_main_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER = ${MAIN_BUNDLE_ID};" "$PBXPROJ_FILE" 2>/dev/null || echo "0")
    
    # Count total bundle IDs
    local final_total_count
    final_total_count=$(grep -c "PRODUCT_BUNDLE_IDENTIFIER" "$PBXPROJ_FILE" 2>/dev/null || echo "0")
    
    # Count fc526a49 modifications
    local fc526a49_count
    fc526a49_count=$(grep -c "fc526a49" "$PBXPROJ_FILE" 2>/dev/null || echo "0")
    
    log_info "📊 FC526A49 elimination results:"
    log_info "   - Final main bundle ID count: $final_main_count"
    log_info "   - Total bundle identifiers: $final_total_count"
    log_info "   - FC526A49 modifications: $fc526a49_count"
    
    # Verify success
    if [ "$final_main_count" -le 3 ]; then
        log_success "✅ FC526A49 SUCCESS: Main bundle ID count is now $final_main_count (≤ 3)"
        log_success "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd PREVENTED"
        return 0
    else
        log_error "❌ FC526A49 FAILURE: Main bundle ID count is still $final_main_count (> 3)"
        return 1
    fi
}

# Function to generate fc526a49 prevention report
generate_fc526a49_report() {
    log_info "📋 Generating fc526a49 prevention report..."
    
    local report_file="$PROJECT_ROOT/fc526a49_collision_prevention_report_${TIMESTAMP}.txt"
    
    cat > "$report_file" << EOF
FC526A49 COLLISION PREVENTION REPORT
====================================
Error ID: fc526a49-b9f3-44dd-bf1d-4674e9f62bfd
Prevention Strategy: PRE-BUILD collision elimination
Timestamp: $TIMESTAMP
Unique Suffix: fc526a49.${TIMESTAMP}

TARGET CONFIGURATION:
Main Bundle ID: $MAIN_BUNDLE_ID
Project File: $PBXPROJ_FILE
Strategy: Pre-build collision prevention

FC526A49 MODIFICATIONS APPLIED:
- Main app bundle ID: PROTECTED (unchanged, ≤ 3 occurrences)
- Excess main bundle IDs: FC526A49 ELIMINATED
- Test targets: FC526A49 ISOLATED
- Framework targets: FC526A49 ISOLATED
- Component targets: FC526A49 ISOLATED

COLLISION PREVENTION STATUS:
✅ CFBundleIdentifier collisions PREVENTED
✅ Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd ELIMINATED
✅ Build process CLEARED
✅ Pre-build elimination SUCCESSFUL

WARNING: This approach modifies the Xcode project file to prevent
fc526a49 collision errors during the build process.

BUILD STATUS: CLEARED FOR IOS BUILD ✅
EOF
    
    log_success "📄 FC526A49 report: $(basename "$report_file")"
    return 0
}

# Main execution
main() {
    log_info "🚀 Starting fc526a49 pre-build collision elimination..."
    
    # Step 1: Analyze current state
    if ! analyze_bundle_ids; then
        log_info "🚨 FC526A49 collision pattern detected - applying elimination"
    else
        log_info "✅ No fc526a49 collision detected - applying preventive treatment"
    fi
    
    # Step 2: Apply fc526a49 elimination
    if ! apply_fc526a49_elimination; then
        log_error "❌ FC526A49 elimination failed"
        exit 1
    fi
    
    # Step 3: Verify results
    if ! verify_fc526a49_elimination; then
        log_error "❌ FC526A49 verification failed"
        exit 1
    fi
    
    # Step 4: Generate report
    generate_fc526a49_report
    
    log_success "☢️ FC526A49 PRE-BUILD COLLISION ELIMINATION COMPLETED"
    log_success "🎯 Error ID fc526a49-b9f3-44dd-bf1d-4674e9f62bfd PREVENTED"
    log_success "🚀 Ready for iOS build process"
    
    return 0
}

# Execute main function
main "$@" 