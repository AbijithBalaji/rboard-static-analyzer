# Standalone test for FirmwareAnalyzer
require_relative '../lib/advanced/firmware_analyzer'

# Test FirmwareAnalyzer directly
puts "=== Testing FirmwareAnalyzer Standalone ==="

analyzer = FirmwareAnalyzer.new

# Test 1: Memory analysis
puts "\n🧪 Test 1: Memory Analysis"
test_file = "test_memory_standalone.rb"
File.write(test_file, <<~RUBY)
  # Test memory patterns
  large_data = Array.new(500, 0)
  config = { temp: 25.0, humid: 60.0, message: "Alert!" }
  sensor1 = ADC.new(pin: "A0")
  sensor2 = ADC.new(pin: "A1")
  controller = PWM.new(pin: "B4")
RUBY

result1 = analyzer.analyze_memory_usage(test_file)
puts "Memory analysis result: #{result1}"

# Test 2: Timing analysis  
puts "\n🧪 Test 2: Timing Analysis"
test_file2 = "test_timing_standalone.rb"
File.write(test_file2, <<~RUBY)
  # Test timing patterns
  sensor = ADC.new(pin: "A0")
  
  loop do
    value = sensor.read  # Blocking operation
    sleep(0.1)          # 100ms delay
    puts "Value: \#{value}"
  end
RUBY

result2 = analyzer.analyze_timing_constraints(test_file2)
puts "Timing analysis result: #{result2}"

# Test 3: Firmware compatibility
puts "\n🧪 Test 3: Firmware Compatibility"
pin_usage = {
  [1, 0] => { peripheral: "ADC", line: 1, source: "test.rb" },
  [2, 4] => { peripheral: "PWM", line: 2, source: "test.rb" }  # Console UART pin
}

peripheral_config = [
  { type: "ADC", pin: [1, 0] },
  { type: "PWM", pin: [2, 4] }
]

result3 = analyzer.validate_firmware_compatibility(pin_usage, peripheral_config)
puts "Firmware compatibility result: #{result3}"

# Test 4: Generate report
puts "\n🧪 Test 4: Generate Report"
analyzer.generate_firmware_report

# Cleanup
File.delete(test_file) if File.exist?(test_file)
File.delete(test_file2) if File.exist?(test_file2)

puts "\n✅ FirmwareAnalyzer standalone tests completed!"
