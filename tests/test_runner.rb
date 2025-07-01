#!/usr/bin/env ruby

# Comprehensive test suite for RBoard Static Analyzer
# Runs all tests and example analyses to verify functionality

# Ensure we're in the project root directory
project_root = File.expand_path("..", __dir__)
Dir.chdir(project_root)

puts "=" * 60
puts "RBoard Static Analyzer - Comprehensive Test Suite"
puts "Running from: #{Dir.pwd}"
puts "=" * 60

success_count = 0
total_tests = 0

def run_test(description, command)
  puts "\n--- #{description} ---"
  result = system(command)
  if result
    puts "✓ PASSED"
    return true
  else
    puts "✗ FAILED"
    return false
  end
end

# Test 1: Core modular analyzer
total_tests += 1
if run_test("Core Modular Analyzer Test", "ruby tests/test_modular_analyzer.rb > nul 2>&1")
  success_count += 1
end

# Test 2: I2C validator
total_tests += 1
if run_test("I2C Validator Test", "ruby tests/test_i2c_validator.rb > nul 2>&1")
  success_count += 1
end

# Test 3: SPI validator
total_tests += 1
if run_test("SPI Validator Test", "ruby tests/test_spi_validator.rb > nul 2>&1")
  success_count += 1
end

# Test 4: UART validator
total_tests += 1
if run_test("UART Validator Test", "ruby tests/test_uart_validator.rb > nul 2>&1")
  success_count += 1
end

# Test 5: Valid configuration analysis
total_tests += 1
if run_test("Valid Configuration Analysis", "ruby rboard_analyzer.rb examples/valid_configuration.rb > nul 2>&1")
  success_count += 1
end

# Test 6: Conflict detection (should fail, so invert result)
total_tests += 1
puts "\n--- Conflict Detection Test (should detect conflicts) ---"
result = system("ruby rboard_analyzer.rb examples/comprehensive_test.rb > nul 2>&1")
if !result  # Should fail due to conflicts
  puts "✓ PASSED (correctly detected conflicts)"
  success_count += 1
else
  puts "✗ FAILED (should have detected conflicts)"
end

# Test 7: Smart sensor system conflicts (should fail)
total_tests += 1
puts "\n--- Smart Sensor System Test (should detect conflicts) ---"
result = system("ruby rboard_analyzer.rb examples/smart_sensor_system.rb > nul 2>&1")
if !result  # Should fail due to conflicts
  puts "✓ PASSED (correctly detected conflicts)"
  success_count += 1
else
  puts "✗ FAILED (should have detected conflicts)"
end

# Summary
puts "\n" + "=" * 60
puts "TEST SUMMARY"
puts "=" * 60
puts "Total tests: #{total_tests}"
puts "Passed: #{success_count}"
puts "Failed: #{total_tests - success_count}"
puts "Success rate: #{(success_count.to_f / total_tests * 100).round(1)}%"

if success_count == total_tests
  puts "\n🎉 ALL TESTS PASSED! Project is ready for publication."
  exit 0
else
  puts "\n❌ Some tests failed. Please review the issues above."
  exit 1
end
