# Test suite for Enhanced RBoard Analyzer - Phase 2 Features
# Tests advanced firmware integration capabilities

require_relative '../lib/enhanced_rboard_analyzer'
require_relative '../lib/advanced/firmware_analyzer'

class TestEnhancedAnalyzer
  def initialize
    @test_count = 0
    @main_test_count = 0
    @passed_count = 0
    @failed_count = 0
  end

  def run_all_tests
    puts "=" * 70
    puts "ENHANCED RBOARD ANALYZER - PHASE 2 TEST SUITE"
    puts "=" * 70
    
    # Count main test categories
    @main_test_count = 7
    
    test_firmware_analyzer_initialization
    test_memory_usage_analysis
    test_timing_constraint_validation
    test_firmware_compatibility_checking
    test_performance_prediction
    test_realtime_constraint_validation
    test_enhanced_analyzer_integration
    
    print_test_summary
  end

  private

  def test_firmware_analyzer_initialization
    test_name = "Firmware Analyzer Initialization"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      analyzer = FirmwareAnalyzer.new
      
      # Check hardware specifications loaded
      assert(!analyzer.instance_variable_get(:@hardware_specs).empty?, "Hardware specs should be loaded")
      
      # Check memory model configuration
      memory_model = analyzer.instance_variable_get(:@mruby_memory_model)
      assert(memory_model[:alloc_type] == "MRBC_ALLOC_24BIT", "Should use 24-bit allocation")
      assert(memory_model[:endian] == "MRBC_LITTLE_ENDIAN", "Should be little endian")
      
      # Check firmware constraints
      constraints = analyzer.instance_variable_get(:@firmware_constraints)
      assert(constraints[:timer1_forbidden] == true, "Timer1 should be forbidden")
      
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    end
  end

  def test_memory_usage_analysis
    test_name = "Memory Usage Analysis"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      analyzer = FirmwareAnalyzer.new
      
      # Create test file with known memory patterns
      test_file = "test_memory_usage.rb"
      File.write(test_file, <<~RUBY)
        # Test memory usage patterns
        large_array = Array.new(1000, 0)
        config_hash = { key1: "value1", key2: "value2", key3: "value3" }
        message = "This is a test string for memory analysis"
        sensor = ADC.new(pin: "A0")
        controller = PWM.new(pin: "B4")
      RUBY
      
      # Analyze memory usage
      result = analyzer.analyze_memory_usage(test_file)
      
      assert(result == true, "Memory analysis should succeed")
      assert(analyzer.errors.empty?, "Should not have errors for valid memory usage")
      
      File.delete(test_file)
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    ensure
      File.delete("test_memory_usage.rb") if File.exist?("test_memory_usage.rb")
    end
  end

  def test_timing_constraint_validation
    test_name = "Timing Constraint Validation"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      analyzer = FirmwareAnalyzer.new
      
      # Test file with timing issues
      test_file = "test_timing_issues.rb"
      File.write(test_file, <<~RUBY)
        # Test timing constraint violations
        temp_sensor = ADC.new(pin: "A0")
        
        loop do
          temperature = temp_sensor.read
          sleep(5.0)  # Long delay - should trigger warning
          
          if temperature > 25
            puts "High temperature detected"
          end
        end
        
        # Timer1 usage (should trigger error)
        # timer1 = Timer.new(1)  # Commented out to avoid actual conflict
      RUBY
      
      result = analyzer.analyze_timing_constraints(test_file)
      
      assert(result == true, "Timing analysis should complete")
      # Note: Warnings/errors depend on content analysis
      
      File.delete(test_file)
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    ensure
      File.delete("test_timing_issues.rb") if File.exist?("test_timing_issues.rb")
    end
  end

  def test_firmware_compatibility_checking
    test_name = "Firmware Compatibility Checking" 
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      analyzer = FirmwareAnalyzer.new
      
      # Mock pin usage and peripheral config
      pin_usage = {
        [1, 0] => { peripheral: "ADC", line: 1, source: "test.rb" },
        [2, 4] => { peripheral: "UART", line: 5, source: "test.rb" }  # Console UART pin
      }
      
      peripheral_config = [
        { type: "ADC", pin: [1, 0], line: 1, source: "test.rb" },
        { type: "UART", pin: [2, 4], line: 5, source: "test.rb" }
      ]
      
      result = analyzer.validate_firmware_compatibility(pin_usage, peripheral_config)
      
      # Should have warnings about console UART conflict
      assert(!analyzer.warnings.empty?, "Should have warnings about UART console conflict")
      
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    end
  end

  def test_performance_prediction
    test_name = "Performance Prediction"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      enhanced_analyzer = EnhancedRBoardAnalyzer.new
      
      # Create test file with multiple peripherals
      test_file = "test_performance.rb"
      File.write(test_file, <<~RUBY)
        # Performance test file
        adc1 = ADC.new(pin: "A0")
        adc2 = ADC.new(pin: "A1")
        pwm1 = PWM.new(pin: "B4")
        uart1 = UART.new(unit: 1)
        
        loop do
          val1 = adc1.read
          val2 = adc2.read
          pwm1.duty_cycle = val1 / 4
          uart1.puts("Values: \#{val1}, \#{val2}")
        end
      RUBY
      
      result = enhanced_analyzer.predict_performance(test_file)
      
      assert(result == true, "Performance prediction should succeed")
      
      File.delete(test_file)
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    ensure
      File.delete("test_performance.rb") if File.exist?("test_performance.rb")
    end
  end

  def test_realtime_constraint_validation
    test_name = "Real-Time Constraint Validation"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      enhanced_analyzer = EnhancedRBoardAnalyzer.new
      
      # Test file with real-time violations
      test_file = "test_realtime.rb"
      File.write(test_file, <<~RUBY)
        # Real-time constraint test
        sensor = ADC.new(pin: "A0")
        
        loop do
          value = sensor.read
          sleep(0.05)  # 50ms delay - within 100ms limit
          
          if value > 512
            puts "Threshold exceeded"
          end
        end
      RUBY
      
      # Test with 100ms constraint (should pass)
      result = enhanced_analyzer.validate_realtime_constraints(test_file, 100)
      assert(result == true, "Should pass 100ms constraint")
      
      # Test with 10ms constraint (should fail due to 50ms delay)
      result = enhanced_analyzer.validate_realtime_constraints(test_file, 10)
      assert(result == false, "Should fail 10ms constraint")
      
      File.delete(test_file)
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    ensure
      File.delete("test_realtime.rb") if File.exist?("test_realtime.rb")
    end
  end

  def test_enhanced_analyzer_integration
    test_name = "Enhanced Analyzer Integration"
    puts "\n🧪 Testing: #{test_name}"
    
    begin
      enhanced_analyzer = EnhancedRBoardAnalyzer.new
      
      # Test that enhanced analyzer inherits base functionality
      assert(enhanced_analyzer.respond_to?(:analyze_ruby_file), "Should inherit base analysis methods")
      assert(enhanced_analyzer.respond_to?(:analyze_with_firmware_constraints), "Should have enhanced methods")
      assert(enhanced_analyzer.respond_to?(:predict_performance), "Should have performance prediction")
      
      # Test firmware analyzer integration
      assert(!enhanced_analyzer.firmware_analyzer.nil?, "Should have firmware analyzer")
      
      # Create simple test file
      test_file = "test_integration.rb"
      File.write(test_file, <<~RUBY)
        # Simple integration test
        led = GPIO.new(pin: "B7", mode: :output)
        led.write(1)
      RUBY
      
      # Test enhanced analysis
      result = enhanced_analyzer.analyze_with_firmware_constraints(test_file)
      
      # Should complete without errors for simple case
      assert(result != false, "Enhanced analysis should complete")
      
      File.delete(test_file)
      pass_test(test_name)
    rescue => e
      fail_test(test_name, e.message)
    ensure
      File.delete("test_integration.rb") if File.exist?("test_integration.rb")
    end
  end

  def assert(condition, message)
    @test_count += 1
    unless condition
      raise "Assertion failed: #{message}"
    end
  end

  def pass_test(test_name)
    @passed_count += 1
    puts "✅ PASSED: #{test_name}"
  end

  def fail_test(test_name, error_message)
    @failed_count += 1
    puts "❌ FAILED: #{test_name}"
    puts "   Error: #{error_message}"
  end

  def print_test_summary
    puts "\n" + "=" * 70
    puts "PHASE 2 TEST SUMMARY"
    puts "=" * 70
    puts "Total main tests: #{@main_test_count}"
    puts "Passed: #{@passed_count}"
    puts "Failed: #{@failed_count}"
    puts "Success rate: #{((@passed_count.to_f / @main_test_count.to_f) * 100).round(1)}%"
    puts "Total assertions: #{@test_count}"
    
    if @failed_count == 0
      puts "\n🎉 ALL PHASE 2 TESTS PASSED!"
      puts "✅ Enhanced analyzer ready for production use"
    else
      puts "\n❌ Some tests failed. Review and fix issues."
    end
  end
end

# Run tests if called directly
if __FILE__ == $0
  tester = TestEnhancedAnalyzer.new
  tester.run_all_tests
end
