# Test different scenarios for the Pin Usage Tracker
require_relative 'phase1_pin_tracker'

def test_scenario(name, &block)
  puts "\n" + "="*50
  puts "TEST: #{name}"
  puts "="*50
  
  tracker = PinUsageTracker.new
  block.call(tracker)
  tracker.print_summary
end

# Test 1: No conflicts (should pass)
test_scenario("Valid pin usage - should pass") do |tracker|
  tracker.use_pin(1, "GPIO", 10)
  tracker.use_pin(2, "ADC", 11) 
  tracker.use_pin(3, "PWM", 12)
  tracker.use_pin("B1", "UART", 13)
end

# Test 2: Pin conflict (should fail)
test_scenario("Pin conflict - should fail") do |tracker|
  tracker.use_pin(5, "GPIO", 20)
  tracker.use_pin(7, "SPI", 21)
  tracker.use_pin(5, "I2C", 22)  # Conflict with line 20!
end

# Test 3: Invalid pin numbers (should fail)
test_scenario("Invalid pin numbers - should fail") do |tracker|
  tracker.use_pin(-1, "GPIO", 30)  # Too low
  tracker.use_pin(25, "ADC", 31)   # Too high
  tracker.use_pin(15, "PWM", 32)   # Valid one
end

# Test 4: Mixed valid/invalid (should catch only errors)
test_scenario("Mixed valid and invalid - should catch errors only") do |tracker|
  tracker.use_pin(0, "GPIO", 40)    # Valid: min pin
  tracker.use_pin(20, "ADC", 41)    # Valid: max pin  
  tracker.use_pin(10, "PWM", 42)    # Valid: middle pin
  tracker.use_pin(10, "SPI", 43)    # Invalid: conflict with line 42
  tracker.use_pin(21, "I2C", 44)    # Invalid: out of range
end
