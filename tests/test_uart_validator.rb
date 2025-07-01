# Test UART validator specifically  
require_relative '../lib/rboard_hardware_analyzer'

def test_scenario(name, &block)
  puts "\n" + "="*60
  puts "TEST: #{name}"
  puts "="*60
  
  analyzer = RBoardAnalyzer.new
  block.call(analyzer)
  analyzer.print_summary
end

puts "Testing UART Validator - Based on Firmware uart.c"
puts "RBoard has 2 UART units with specific pin assignments"

# Test 1: Valid UART1 pins (should pass with warnings)
test_scenario("Valid UART1 pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("B4", "UART", 10)   # UART1 TX (default)
  analyzer.use_pin("A4", "UART", 11)   # UART1 RX (default)
end

# Test 2: Valid UART2 pins (should pass with warnings)
test_scenario("Valid UART2 pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("B9", "UART", 20)   # UART2 TX (default)
  analyzer.use_pin("B8", "UART", 21)   # UART2 RX (default)
end

# Test 3: Alternative RX pins (should pass with warnings)
test_scenario("Alternative UART RX pins - should pass with warnings") do |analyzer|
  analyzer.use_pin("A2", "UART", 30)   # UART1 RX alternative
  analyzer.use_pin("B1", "UART", 31)   # UART2 RX alternative
end

# Test 4: Invalid UART pin (should fail)
test_scenario("Invalid UART pin - should fail") do |analyzer|
  analyzer.use_pin("A0", "UART", 40)   # A0 cannot do UART
end

# Test 5: UART pin conflict (should fail)
test_scenario("UART pin conflict - should fail") do |analyzer|
  analyzer.use_pin("B4", "PWM", 50)    # B4 used for PWM first
  analyzer.use_pin("B4", "UART", 51)   # Conflict with UART
end

# Test 6: Mixed UART units (should pass)
test_scenario("Mixed UART units - should pass") do |analyzer|
  analyzer.use_pin("B4", "UART", 60)   # UART1 TX
  analyzer.use_pin("B8", "UART", 61)   # UART2 RX
end

puts "\n" + "="*60
puts "UART CONSTRAINTS (from firmware uart.c):"
puts "✓ UART1 TX: B4 (default, remappable)"
puts "✓ UART1 RX: A2, B6, A4, B13, B2 (multiple options)"
puts "✓ UART2 TX: B9 (default, remappable)"
puts "✓ UART2 RX: A1, B5, B1, B11, B8 (multiple options)"
puts "✓ Baud rates: 9600, 19200, 38400, 57600, 115200"
puts "✓ Default: UART1=19200, UART2=9600"
puts "="*60
