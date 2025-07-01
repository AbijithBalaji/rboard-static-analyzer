# Comprehensive tests for the modular RBoard analyzer
require_relative '../lib/rboard_hardware_analyzer'

def test_scenario(name, &block)
  puts "\n" + "="*60
  puts "TEST: #{name}"
  puts "="*60
  
  analyzer = RBoardAnalyzer.new
  block.call(analyzer)
  analyzer.print_summary
end

puts "Testing Modular RBoard Hardware Analyzer"
puts "Based on firmware-extracted constraints"

# Test 1: Valid pin usage (should pass)
test_scenario("Valid pin usage - should pass") do |analyzer|
  analyzer.use_pin("A0", "ADC", 10)    # Valid ADC pin
  analyzer.use_pin("B3", "PWM", 11)    # Valid PWM pin  
  analyzer.use_pin("A2", "GPIO", 12)   # Valid GPIO pin
end

# Test 2: Pin conflicts (should fail)
test_scenario("Pin conflicts - should fail") do |analyzer|
  analyzer.use_pin("A1", "ADC", 20)    # First usage - OK
  analyzer.use_pin("A1", "GPIO", 21)   # Conflict - FAIL
end

# Test 3: Invalid peripheral pins (should fail)
test_scenario("Invalid peripheral-pin combinations") do |analyzer|
  analyzer.use_pin("A4", "ADC", 30)    # RA4 cannot do ADC
  analyzer.use_pin("A3", "PWM", 31)    # RA3 cannot do PWM (no OC unit)
end

# Test 4: Invalid pin numbers (should fail)
test_scenario("Invalid pin numbers") do |analyzer|
  analyzer.use_pin("A5", "GPIO", 40)   # RA5 doesn't exist
  analyzer.use_pin("B16", "GPIO", 41)  # RB16 doesn't exist
  analyzer.use_pin(25, "ADC", 42)      # Pin 25 doesn't exist
end

# Test 5: Unknown peripheral (should fail)
test_scenario("Unknown peripheral") do |analyzer|
  analyzer.use_pin("A0", "UNKNOWN", 50)
end

# Test 6: Pin format variations (should pass)
test_scenario("Different pin formats - should pass") do |analyzer|
  analyzer.use_pin(0, "ADC", 60)       # Numeric pin
  analyzer.use_pin("B1", "PWM", 61)    # String pin
  analyzer.use_pin("RA2", "GPIO", 62)  # Register-style pin
end

# Test 7: I2C validation (should pass with warnings)
test_scenario("I2C usage - should pass with warnings") do |analyzer|
  analyzer.use_pin("B3", "I2C", 70)    # I2C SCL
  analyzer.use_pin("B2", "I2C", 71)    # I2C SDA
end

# Test 8: SPI validation (should pass with warnings)
test_scenario("SPI usage - should pass with warnings") do |analyzer|
  analyzer.use_pin("B5", "SPI", 80)    # SPI1 SDI
  analyzer.use_pin("B14", "SPI", 81)   # SPI1 SCK
end

# Test 9: UART validation (should pass with warnings)
test_scenario("UART usage - should pass with warnings") do |analyzer|
  analyzer.use_pin("B4", "UART", 90)   # UART1 TX
  analyzer.use_pin("A4", "UART", 91)   # UART1 RX
end

puts "\n" + "="*60
puts "MODULAR ARCHITECTURE BENEFITS:"
puts "✓ Each validator is in a separate file"
puts "✓ Easy to add new peripherals (just add new validator)"  
puts "✓ Each component can be tested independently"
puts "✓ Clean separation of concerns"
puts "✓ Firmware-based accuracy"
puts "✓ Now supports: ADC, PWM, GPIO, I2C, SPI, UART"
puts "✓ Communication protocols complete!"
puts "="*60
