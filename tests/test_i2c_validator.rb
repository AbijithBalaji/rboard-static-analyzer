# Test I2C validator specifically
require_relative '../lib/rboard_analyzer'

def test_scenario(name, &block)
  puts "\n" + "="*60
  puts "TEST: #{name}"
  puts "="*60
  
  analyzer = RBoardAnalyzer.new
  block.call(analyzer)
  analyzer.print_summary
end

puts "Testing I2C Validator - Based on Firmware i2c.c"
puts "RBoard uses I2C2 module: SCL=B3, SDA=B2, 100kHz only"

# Test 1: Valid I2C pin usage (should pass with warnings)
test_scenario("Valid I2C pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("B3", "I2C", 10)    # SCL pin
  analyzer.use_pin("B2", "I2C", 11)    # SDA pin
end

# Test 2: Invalid I2C pin (should fail)
test_scenario("Invalid I2C pin - should fail") do |analyzer|
  analyzer.use_pin("A0", "I2C", 20)    # A0 cannot do I2C
end

# Test 3: I2C pin conflict (should fail)
test_scenario("I2C pin conflict - should fail") do |analyzer|
  analyzer.use_pin("B3", "PWM", 30)    # B3 used for PWM first
  analyzer.use_pin("B3", "I2C", 31)    # Conflict with I2C
end

# Test 4: Only one I2C pin used (should warn)
test_scenario("Incomplete I2C setup - should warn") do |analyzer|
  analyzer.use_pin("B3", "I2C", 40)    # Only SCL, missing SDA
end

puts "\n" + "="*60
puts "I2C CONSTRAINTS (from firmware i2c.c):"
puts "✓ Fixed pins: B3=SCL, B2=SDA only"
puts "✓ Single module: I2C2 only" 
puts "✓ Fixed frequency: 100kHz only"
puts "✓ Requires both SCL and SDA for operation"
puts "="*60
