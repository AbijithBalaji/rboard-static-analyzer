# Standalone test for EnhancedRBoardAnalyzer
require_relative '../lib/enhanced_rboard_analyzer'

puts "=== Testing EnhancedRBoardAnalyzer Standalone ==="

analyzer = EnhancedRBoardAnalyzer.new

# Test 1: Basic enhanced analysis
puts "\n🧪 Test 1: Enhanced Analysis with Firmware Constraints"
test_file = "test_enhanced_standalone.rb"
File.write(test_file, <<~RUBY)
  # Enhanced analysis test
  temp_sensor = ADC.new(pin: "A0")
  led = GPIO.new(pin: "B7", mode: :output)
  pwm = PWM.new(pin: "B4", frequency: 1000)
  
  loop do
    temp = temp_sensor.read
    if temp > 25
      led.write(1)
      pwm.duty_cycle = 50
    else
      led.write(0)
      pwm.duty_cycle = 0
    end
    sleep(0.1)  # 100ms delay
  end
RUBY

result1 = analyzer.analyze_with_firmware_constraints(test_file)
puts "Enhanced analysis result: #{result1}"

# Test 2: Performance prediction
puts "\n🧪 Test 2: Performance Prediction"
result2 = analyzer.predict_performance(test_file)
puts "Performance prediction result: #{result2}"

# Test 3: Real-time constraint validation
puts "\n🧪 Test 3: Real-Time Constraint Validation"
result3 = analyzer.validate_realtime_constraints(test_file, 200) # 200ms limit
puts "Real-time validation (200ms): #{result3}"

result4 = analyzer.validate_realtime_constraints(test_file, 50)  # 50ms limit  
puts "Real-time validation (50ms): #{result4}"

# Test 4: Multi-file project
puts "\n🧪 Test 4: Multi-File Project Analysis"
file1 = "test_module1.rb"
file2 = "test_module2.rb"

File.write(file1, <<~RUBY)
  # Module 1: Sensors
  temp = ADC.new(pin: "A0")
  humid = ADC.new(pin: "A1")
RUBY

File.write(file2, <<~RUBY)
  # Module 2: Actuators  
  fan = PWM.new(pin: "B4")
  pump = PWM.new(pin: "B5")
  led = GPIO.new(pin: "B7")
RUBY

result5 = analyzer.analyze_project_with_firmware([file1, file2])
puts "Multi-file analysis result: #{result5}"

# Cleanup
[test_file, file1, file2].each { |f| File.delete(f) if File.exist?(f) }

puts "\n✅ EnhancedRBoardAnalyzer standalone tests completed!"
