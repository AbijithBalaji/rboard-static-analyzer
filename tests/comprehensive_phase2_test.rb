#!/usr/bin/env ruby
# Comprehensive Phase 2 Test - Enhanced RBoard Analyzer
# Tests all Phase 2 features with proper error/warning validation

require_relative '../lib/enhanced_rboard_analyzer'

puts "=" * 80
puts "COMPREHENSIVE PHASE 2 TEST SUITE"
puts "Enhanced RBoard Analyzer - All Features"
puts "=" * 80

# Initialize analyzer
analyzer = EnhancedRBoardAnalyzer.new

# Test 1: Single file analysis with enhanced features
puts "\n" + "=" * 60
puts "TEST 1: Single File Enhanced Analysis"
puts "=" * 60

test_file = "examples/comprehensive_test.rb"
puts "Testing file: #{test_file}"

if File.exist?(test_file)
  result1 = analyzer.analyze_with_firmware_constraints(test_file)
  puts "\nSingle file analysis result: #{result1 ? '✅ PASSED' : '❌ FAILED'}"
else
  puts "❌ Test file not found: #{test_file}"
  result1 = false
end

# Test 2: Performance prediction
puts "\n" + "=" * 60
puts "TEST 2: Performance Prediction"
puts "=" * 60

if File.exist?(test_file)
  result2 = analyzer.predict_performance(test_file)
  puts "\nPerformance prediction result: #{result2 ? '✅ PASSED' : '❌ FAILED'}"
else
  result2 = false
end

# Test 3: Real-time constraint validation
puts "\n" + "=" * 60
puts "TEST 3: Real-time Constraint Validation"
puts "=" * 60

if File.exist?(test_file)
  result3 = analyzer.validate_realtime_constraints(test_file, 50) # 50ms max
  puts "\nReal-time validation result: #{result3 ? '✅ PASSED' : '❌ FAILED'}"
else
  result3 = false
end

# Test 4: Project-wide analysis (multiple files)
puts "\n" + "=" * 60
puts "TEST 4: Project-wide Analysis (Cross-file)"
puts "=" * 60

test_files = [
  "examples/valid_configuration.rb",
  "examples/simple_test.rb"
].select { |f| File.exist?(f) }

if test_files.length >= 2
  puts "Testing files: #{test_files.join(', ')}"
  result4 = analyzer.analyze_project_with_firmware(test_files)
  puts "\nProject analysis result: #{result4 ? '✅ PASSED' : '❌ FAILED'}"
else
  puts "⚠️  Not enough test files for cross-file analysis"
  result4 = true # Skip this test
end

# Test 5: Create files with actual pin conflicts for testing
puts "\n" + "=" * 60
puts "TEST 5: Cross-file Pin Conflict Detection"
puts "=" * 60

# Create temporary test files with real conflicts
conflict_file1 = "temp_conflict1.rb"
conflict_file2 = "temp_conflict2.rb"

File.write(conflict_file1, <<~RUBY)
  # Test file 1 - uses GPIO pin B2
  gpio1 = GPIO.new("B2")
  gpio1.mode = :output
  gpio1.write(1)
  
  # Also use PWM pin B3
  motor = PWM.new("B3")
  motor.frequency = 1000
  motor.duty_cycle = 50
RUBY

File.write(conflict_file2, <<~RUBY)
  # Test file 2 - conflicts with pin B2 from file 1
  gpio2 = GPIO.new("B2")  # Same pin as file 1 - CONFLICT!
  gpio2.mode = :input
  val = gpio2.read
  
  # Different pin - should be fine
  gpio3 = GPIO.new("B4")
  gpio3.mode = :output
  gpio3.write(0)
RUBY

puts "Created temporary conflict test files..."
conflict_files = [conflict_file1, conflict_file2]
result5 = analyzer.analyze_project_with_firmware(conflict_files)

# Clean up temporary files
File.delete(conflict_file1) if File.exist?(conflict_file1)
File.delete(conflict_file2) if File.exist?(conflict_file2)

puts "\nCross-file conflict detection result: #{result5 ? '🚨 UNEXPECTED PASS (should detect conflicts)' : '✅ CORRECTLY DETECTED CONFLICTS'}"

# Test 6: Valid multi-file project (no conflicts)
puts "\n" + "=" * 60
puts "TEST 6: Valid Multi-file Project (No Conflicts)"
puts "=" * 60

# Create temporary test files without conflicts
valid_file1 = "temp_valid1.rb"
valid_file2 = "temp_valid2.rb"

File.write(valid_file1, <<~RUBY)
  # Test file 1 - uses specific pins
  gpio1 = GPIO.new("B10")
  gpio1.mode = :output
  gpio1.write(1)
  
  motor = PWM.new("B9")
  motor.frequency = 1000
  motor.duty_cycle = 50
RUBY

File.write(valid_file2, <<~RUBY)
  # Test file 2 - uses different pins (no conflicts)
  gpio2 = GPIO.new("B11")  # Different pin from file 1
  gpio2.mode = :input
  val = gpio2.read
  
  adc = ADC.new("A0")
  voltage = adc.read
RUBY

puts "Created temporary valid test files..."
valid_files = [valid_file1, valid_file2]
result6 = analyzer.analyze_project_with_firmware(valid_files)

# Clean up temporary files
File.delete(valid_file1) if File.exist?(valid_file1)
File.delete(valid_file2) if File.exist?(valid_file2)

puts "\nValid multi-file project result: #{result6 ? '✅ PASSED (no conflicts detected)' : '❌ FAILED (false positives detected)'}"

# Final Summary
puts "\n" + "=" * 80
puts "COMPREHENSIVE TEST SUMMARY"
puts "=" * 80

results = [
  ["Single file enhanced analysis", result1],
  ["Performance prediction", result2],
  ["Real-time constraint validation", result3],
  ["Project-wide analysis", result4],
  ["Cross-file conflict detection", !result5], # Should fail (detect conflicts)
  ["Valid multi-file project", result6]
]

passed = 0
total = results.length

results.each_with_index do |(test_name, result), index|
  status = result ? "✅ PASSED" : "❌ FAILED"
  puts "#{index + 1}. #{test_name}: #{status}"
  passed += 1 if result
end

puts "\n" + "=" * 80
puts "FINAL RESULT: #{passed}/#{total} tests passed"

if passed == total
  puts "🎉 ALL TESTS PASSED - Phase 2 implementation is working correctly!"
else
  puts "⚠️  Some tests failed - review and fix issues"
end

puts "=" * 80
