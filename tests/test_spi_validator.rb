# Test SPI validator specifically
require_relative '../lib/rboard_analyzer'

def test_scenario(name, &block)
  puts "\n" + "="*60
  puts "TEST: #{name}"
  puts "="*60
  
  analyzer = RBoardAnalyzer.new
  block.call(analyzer)
  analyzer.print_summary
end

puts "Testing SPI Validator - Based on Firmware spi.c"
puts "RBoard has 2 SPI units with specific pin assignments"

# Test 1: Valid SPI1 pins (should pass with warnings)
test_scenario("Valid SPI1 pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("B5", "SPI", 10)    # SPI1 SDI (default)
  analyzer.use_pin("B14", "SPI", 11)   # SPI1 SCK (fixed)
end

# Test 2: Valid SPI2 pins (should pass with warnings)
test_scenario("Valid SPI2 pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("A2", "SPI", 20)    # SPI2 SDI (multi-function)
  analyzer.use_pin("B15", "SPI", 21)   # SPI2 SCK (fixed)
end

# Test 3: Invalid SPI pin (should fail)
test_scenario("Invalid SPI pin - should fail") do |analyzer|
  analyzer.use_pin("A0", "SPI", 30)    # A0 cannot do SPI
end

# Test 4: SPI pin conflict (should fail)
test_scenario("SPI pin conflict - should fail") do |analyzer|
  analyzer.use_pin("B5", "PWM", 40)    # B5 used for PWM first
  analyzer.use_pin("B5", "SPI", 41)    # Conflict with SPI
end

# Test 5: Multi-function pin usage (should warn)
test_scenario("Multi-function pin - should warn") do |analyzer|
  analyzer.use_pin("A2", "SPI", 50)    # A2 can be SDI2 or SDO
  analyzer.use_pin("B6", "SPI", 51)    # B6 can be SDI2 or SDO
end

# Test 6: Mixed SPI units (should pass)
test_scenario("Mixed SPI units - should pass") do |analyzer|
  analyzer.use_pin("B5", "SPI", 60)    # SPI1 SDI
  analyzer.use_pin("B15", "SPI", 61)   # SPI2 SCK
  analyzer.use_pin("B13", "SPI", 62)   # Multi-function (SDI2/SDO)
end

puts "\n" + "="*60
puts "SPI CONSTRAINTS (from firmware spi.c):"
puts "✓ SPI1 SDI pins: A1, B1, B5, B8, B11"
puts "✓ SPI2 SDI pins: A2, B2, B6, B13"
puts "✓ SDO pins (both units): A2, A4, B2, B6, B13"
puts "✓ SCK pins: B14 (SPI1), B15 (SPI2) - fixed"
puts "✓ Frequency: 9.77kHz - 5MHz"
puts "✓ Modes: 0-3 (CPOL/CPHA combinations)"
puts "="*60
