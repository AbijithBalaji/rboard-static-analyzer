# Enhanced RBoard Analyzer with Advanced Firmware Integration
# Phase 2: Deep firmware integration and advanced analysis capabilities

require_relative 'rboard_hardware_analyzer'
require_relative 'advanced/firmware_analyzer'

class EnhancedRBoardAnalyzer < RBoardAnalyzer
  attr_reader :firmware_analyzer

  def initialize
    super
    @firmware_analyzer = FirmwareAnalyzer.new
    @phase2_features = {
      memory_analysis: true,
      timing_analysis: true,
      firmware_compatibility: true,
      bytecode_analysis: true,
      performance_prediction: true
    }
  end

  # Enhanced analysis with firmware-level validation
  def analyze_with_firmware_constraints(file_path, options = {})
    puts "\n" + "=" * 70
    puts "ENHANCED RBOARD ANALYSIS - Phase 2 Integration"
    puts "Hardware + Firmware + Runtime Constraints"
    puts "=" * 70
    
    # Phase 1: Hardware pin validation (existing functionality)
    puts "\n🔍 Phase 1: Hardware Pin Validation"
    hardware_valid = analyze_ruby_file(file_path)
    
    # Phase 2: Advanced firmware analysis
    puts "\n🚀 Phase 2: Advanced Firmware Analysis"
    
    firmware_results = {}
    
    if @phase2_features[:memory_analysis]
      puts "\n📊 Memory Usage Analysis..."
      firmware_results[:memory] = @firmware_analyzer.analyze_memory_usage(file_path)
    end
    
    if @phase2_features[:timing_analysis]
      puts "\n⏱️  Timing & Interrupt Analysis..."
      firmware_results[:timing] = @firmware_analyzer.analyze_timing_constraints(file_path)
    end
    
    if @phase2_features[:firmware_compatibility]
      puts "\n🔧 Firmware Compatibility Check..."
      firmware_results[:compatibility] = @firmware_analyzer.validate_firmware_compatibility(
        @pin_usage, 
        extract_peripheral_config()
      )
    end
    
    # Bytecode analysis (if .mrb file exists)
    mrb_file = file_path.gsub(/\.rb$/, '.mrb')
    if @phase2_features[:bytecode_analysis] && File.exist?(mrb_file)
      puts "\n📦 Bytecode Analysis..."
      firmware_results[:bytecode] = @firmware_analyzer.analyze_bytecode_constraints(mrb_file)
    end
    
    # Generate comprehensive report
    generate_enhanced_report(hardware_valid, firmware_results, options)
    
    # Return overall validation result
    hardware_valid && firmware_results.values.all? { |result| result != false }
  end

  # Analyze multiple files with cross-file firmware constraints
  def analyze_project_with_firmware(file_paths, options = {})
    puts "\n" + "=" * 80
    puts "ENHANCED PROJECT ANALYSIS - Multi-File Firmware Validation"
    puts "=" * 80
    
    project_results = {
      files: [],
      cross_file_issues: [],
      total_memory_usage: 0,
      total_execution_time: 0,
      firmware_conflicts: [],
      all_pin_usage: {}  # Track pin usage across all files
    }
    
    # Analyze each file individually
    file_paths.each_with_index do |file_path, index|
      puts "\n#{index + 1}/#{file_paths.length}: #{File.basename(file_path)}"
      
      # Create separate analyzer instance for each file to avoid state pollution
      file_analyzer = EnhancedRBoardAnalyzer.new
      
      file_result = {
        path: file_path,
        hardware_valid: false,
        firmware_results: {},
        pin_usage: {},
        memory_usage: 0,
        execution_time: 0
      }
      
      # Hardware analysis
      file_result[:hardware_valid] = file_analyzer.analyze_ruby_file(file_path)
      file_result[:pin_usage] = file_analyzer.pin_usage.dup
      
      # Store pin usage for cross-file analysis
      file_result[:pin_usage].each do |pin_key, usage_info|
        pin_id = "#{pin_key[0]}_#{pin_key[1]}"
        if project_results[:all_pin_usage][pin_id]
          # Only report conflict if it's truly between different files
          existing_source = project_results[:all_pin_usage][pin_id][:source]
          current_source = usage_info[:source]
          
          if existing_source != current_source
            # Real cross-file conflict detected
            project_results[:cross_file_issues] << {
              type: :pin_conflict,
              pin: pin_key,
              files: [existing_source, current_source],
              message: "Pin [#{pin_key[0]}, #{pin_key[1]}] used in multiple files"
            }
          end
        else
          project_results[:all_pin_usage][pin_id] = usage_info.dup
        end
      end
      
      # Firmware analysis
      if @phase2_features[:memory_analysis]
        memory_result = file_analyzer.firmware_analyzer.analyze_memory_usage(file_path)
        file_result[:firmware_results][:memory] = memory_result
        
        # Extract memory usage from firmware analyzer
        if memory_result
          # Access private analysis results (simplified approach)
          file_result[:memory_usage] = estimate_file_memory_usage(file_path)
          project_results[:total_memory_usage] += file_result[:memory_usage]
        end
      end
      
      if @phase2_features[:timing_analysis]
        timing_result = file_analyzer.firmware_analyzer.analyze_timing_constraints(file_path)
        file_result[:firmware_results][:timing] = timing_result
        
        # Extract timing information
        if timing_result
          file_result[:execution_time] = estimate_file_execution_time(file_path)
          project_results[:total_execution_time] += file_result[:execution_time]
        end
      end
      
      project_results[:files] << file_result
    end
    
    # Generate project report
    generate_project_report(project_results, options)
    
    # Return success status - no cross-file issues and all files passed
    project_results[:files].all? { |f| f[:hardware_valid] } && 
    project_results[:cross_file_issues].empty?
  end

  # Performance prediction based on peripheral usage
  def predict_performance(file_path)
    puts "\n🎯 Performance Prediction Analysis"
    puts "=" * 40
    
    # Parse the file to understand peripheral usage patterns
    unless @ruby_parser.parse_file(file_path)
      puts "❌ Could not parse file for performance analysis"
      return false
    end
    
    results = @ruby_parser.get_analysis_results()
    
    performance_metrics = {
      estimated_cpu_usage: 0.0,
      estimated_power_consumption: 0.0,
      estimated_response_time: 0.0,
      bottlenecks: [],
      optimizations: []
    }
    
    # Analyze each peripheral type for performance impact
    analyze_adc_performance(results[:adc_calls], performance_metrics)
    analyze_pwm_performance(results[:pwm_calls], performance_metrics)
    analyze_gpio_performance(results[:gpio_calls], performance_metrics)
    analyze_i2c_performance(results[:i2c_calls], performance_metrics)
    analyze_spi_performance(results[:spi_calls], performance_metrics)
    analyze_uart_performance(results[:uart_calls], performance_metrics)
    
    # Generate performance report
    print_performance_report(performance_metrics)
    
    true
  end

  # Real-time constraint validation
  def validate_realtime_constraints(file_path, max_response_time_ms = 100)
    puts "\n⚡ Real-Time Constraint Validation"
    puts "Maximum allowed response time: #{max_response_time_ms}ms"
    puts "=" * 50
    
    # Analyze timing patterns
    timing_valid = @firmware_analyzer.analyze_timing_constraints(file_path)
    
    # Check against real-time requirements
    realtime_issues = []
    
    # Check for blocking operations
    content = File.read(file_path)
    lines = content.split("\n")
    
    lines.each_with_index do |line, index|
      line_num = index + 1
      
      # Long delays violate real-time constraints
      if line =~ /(sleep|delay)\s*\(\s*(\d+(?:\.\d+)?)\s*\)/
        delay_ms = $2.to_f
        delay_ms *= 1000 if $1 == 'sleep'
        
        if delay_ms > max_response_time_ms
          realtime_issues << {
            line: line_num,
            issue: "Delay #{delay_ms}ms exceeds real-time constraint (#{max_response_time_ms}ms)",
            severity: :error
          }
        end
      end
      
      # Blocking I/O in main loop
      if line =~ /(while.*true|loop\s+do).*(uart.*read|adc.*read)/i
        realtime_issues << {
          line: line_num,
          issue: "Blocking I/O in main loop may violate real-time constraints",
          severity: :warning
        }
      end
    end
    
    # Report results
    if realtime_issues.empty?
      puts "✅ Real-time constraints satisfied"
      return true
    else
      puts "❌ Real-time constraint violations detected:"
      realtime_issues.each do |issue|
        icon = issue[:severity] == :error ? "❌" : "⚠️ "
        puts "  #{icon} Line #{issue[:line]}: #{issue[:issue]}"
      end
      return false
    end
  end

  private

  def extract_peripheral_config
    config = []
    
    @pin_usage.each do |pin_key, usage|
      config << {
        type: usage[:peripheral],
        pin: pin_key,
        line: usage[:line],
        source: usage[:source]
      }
    end
    
    config
  end

  def analyze_cross_file_constraints(project_results)
    # Cross-file analysis is now done during file processing
    # This method is kept for compatibility but doesn't need to do anything
    # as conflicts are detected in analyze_project_with_firmware
  end

  def estimate_file_memory_usage(file_path)
    # Simple memory estimation based on file content
    return 0 unless File.exist?(file_path)
    
    content = File.read(file_path)
    memory_usage = 0
    
    # Count variables, strings, arrays, etc.
    memory_usage += content.scan(/\w+\s*=/).length * 16  # Variables
    memory_usage += content.scan(/"[^"]*"/).sum { |s| s.length + 24 }  # Strings
    memory_usage += content.scan(/Array\.new|\[.*\]/).length * 64  # Arrays
    memory_usage += content.scan(/Hash\.new|\{.*\}/).length * 128  # Hashes
    memory_usage += content.scan(/\w+\.new/).length * 48  # Objects
    
    memory_usage
  end

  def estimate_file_execution_time(file_path)
    # Simple execution time estimation
    return 0 unless File.exist?(file_path)
    
    content = File.read(file_path)
    execution_time = 0
    
    # Look for delay operations
    content.scan(/sleep\s*\(\s*(\d+(?:\.\d+)?)\s*\)/) do |match|
      execution_time += match[0].to_f * 1000  # Convert to ms
    end
    
    content.scan(/delay\s*\(\s*(\d+(?:\.\d+)?)\s*\)/) do |match|
      execution_time += match[0].to_f  # Already in ms
    end
    
    # Add base execution overhead
    execution_time += content.lines.length * 0.1  # 0.1ms per line estimate
    
    execution_time
  end

  def generate_enhanced_report(hardware_valid, firmware_results, options)
    puts "\n" + "=" * 70
    puts "ENHANCED ANALYSIS REPORT"
    puts "=" * 70
    
    # Hardware summary (existing)
    print_summary
    
    # Firmware analysis summary
    @firmware_analyzer.generate_firmware_report
    
    # Overall status
    all_valid = hardware_valid && firmware_results.values.all? { |r| r != false }
    
    puts "\n" + "=" * 70
    puts "OVERALL ANALYSIS RESULT"
    puts "=" * 70
    
    puts "Hardware validation: #{hardware_valid ? '✅ PASSED' : '❌ FAILED'}"
    
    firmware_results.each do |feature, result|
      status = case result
               when true then '✅ PASSED'
               when false then '❌ FAILED'
               else '⚠️  WARNINGS'
               end
      puts "#{feature.to_s.capitalize} analysis: #{status}"
    end
    
    if all_valid
      puts "\n🎉 ENHANCED VALIDATION: ALL CHECKS PASSED"
      puts "✓ Ready for deployment on RBoard hardware"
    else
      puts "\n❌ ENHANCED VALIDATION: ISSUES DETECTED"
      puts "⚠️  Review and fix issues before deployment"
    end
  end

  def generate_project_report(project_results, options)
    puts "\n" + "=" * 80
    puts "PROJECT ANALYSIS REPORT"
    puts "=" * 80
    
    success_count = project_results[:files].count { |f| f[:hardware_valid] }
    total_files = project_results[:files].length
    
    puts "Files analyzed: #{total_files}"
    puts "Hardware validation passed: #{success_count}/#{total_files}"
    
    if project_results[:cross_file_issues].any?
      puts "\n❌ Cross-file issues detected:"
      project_results[:cross_file_issues].each do |issue|
        puts "  - #{issue[:message]} (#{issue[:files].join(' vs ')})"
      end
    else
      puts "\n✅ No cross-file conflicts detected"
    end
    
    puts "\n📊 Project Statistics:"
    puts "Total estimated memory usage: #{project_results[:total_memory_usage]} bytes"
    puts "Total estimated execution time: #{project_results[:total_execution_time].round(1)}ms"
    
    # Per-file breakdown
    puts "\n📁 Per-file breakdown:"
    project_results[:files].each do |file_result|
      filename = File.basename(file_result[:path])
      status = file_result[:hardware_valid] ? "✅" : "❌"
      puts "  #{status} #{filename}: #{file_result[:memory_usage]}B RAM, #{file_result[:execution_time].round(1)}ms"
    end
    
    if success_count == total_files && project_results[:cross_file_issues].empty?
      puts "\n🎉 PROJECT VALIDATION: PASSED"
    else
      puts "\n❌ PROJECT VALIDATION: ISSUES DETECTED"
    end
  end

  def analyze_adc_performance(adc_calls, metrics)
    adc_calls.each do |call|
      metrics[:estimated_cpu_usage] += 5.0  # ADC read ~5% CPU for 10-bit conversion
      metrics[:estimated_power_consumption] += 2.5  # ADC power consumption
      metrics[:estimated_response_time] += 0.1  # 100µs conversion time
    end
    
    if adc_calls.length > 5
      metrics[:bottlenecks] << "High ADC usage (#{adc_calls.length} calls) may impact performance"
      metrics[:optimizations] << "Consider using ADC interrupt mode for better performance"
    end
  end

  def analyze_pwm_performance(pwm_calls, metrics)
    pwm_calls.each do |call|
      metrics[:estimated_cpu_usage] += 2.0  # PWM setup overhead
      metrics[:estimated_power_consumption] += 1.0  # PWM module power
    end
    
    if pwm_calls.length > 4
      metrics[:bottlenecks] << "All PWM units in use - no expansion possible"
    end
  end

  def analyze_gpio_performance(gpio_calls, metrics)
    gpio_calls.each do |call|
      metrics[:estimated_cpu_usage] += 0.5  # Minimal GPIO overhead
      metrics[:estimated_power_consumption] += 0.1  # GPIO power consumption
    end
    
    if gpio_calls.length > 15
      metrics[:optimizations] << "Consider port-based GPIO operations for better performance"
    end
  end

  def analyze_i2c_performance(i2c_calls, metrics)
    i2c_calls.each do |call|
      metrics[:estimated_cpu_usage] += 15.0  # I2C is CPU intensive
      metrics[:estimated_power_consumption] += 5.0  # I2C module power
      metrics[:estimated_response_time] += 10.0  # I2C transaction time
    end
    
    if i2c_calls.length > 2
      metrics[:bottlenecks] << "Multiple I2C operations may cause bus contention"
      metrics[:optimizations] << "Consider I2C transaction batching"
    end
  end

  def analyze_spi_performance(spi_calls, metrics)
    spi_calls.each do |call|
      metrics[:estimated_cpu_usage] += 8.0  # SPI moderate CPU usage
      metrics[:estimated_power_consumption] += 3.0  # SPI module power
      metrics[:estimated_response_time] += 1.0  # Fast SPI transactions
    end
  end

  def analyze_uart_performance(uart_calls, metrics)
    uart_calls.each do |call|
      metrics[:estimated_cpu_usage] += 10.0  # UART moderate CPU usage
      metrics[:estimated_power_consumption] += 4.0  # UART module power
      metrics[:estimated_response_time] += 5.0  # UART transmission time
    end
  end

  def print_performance_report(metrics)
    puts "\n📊 Performance Prediction Results"
    puts "-" * 40
    puts "Estimated CPU usage: #{metrics[:estimated_cpu_usage].round(1)}%"
    puts "Estimated power consumption: #{metrics[:estimated_power_consumption].round(1)} mA"
    puts "Estimated response time: #{metrics[:estimated_response_time].round(2)} ms"
    
    if metrics[:bottlenecks].any?
      puts "\n⚠️  Performance Bottlenecks:"
      metrics[:bottlenecks].each { |b| puts "  - #{b}" }
    end
    
    if metrics[:optimizations].any?
      puts "\n💡 Optimization Suggestions:"
      metrics[:optimizations].each { |o| puts "  - #{o}" }
    end
    
    # Performance rating
    if metrics[:estimated_cpu_usage] < 50
      puts "\n✅ Performance Rating: EXCELLENT"
    elsif metrics[:estimated_cpu_usage] < 75
      puts "\n🟡 Performance Rating: GOOD"
    else
      puts "\n🔴 Performance Rating: POOR - Optimization needed"
    end
  end
end
