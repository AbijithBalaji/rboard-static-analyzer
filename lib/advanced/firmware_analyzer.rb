# Advanced Firmware Analyzer
# Deep integration with RBoard firmware constraints and mruby/c runtime

require_relative '../ruby_parser'

class FirmwareAnalyzer
  attr_reader :memory_constraints, :timing_constraints, :errors, :warnings

  def initialize
    @memory_constraints = {}
    @timing_constraints = {}
    @errors = []
    @warnings = []
    
    # PIC32MX170F256B Hardware Specifications
    @hardware_specs = {
      flash_size: 256 * 1024,      # 256KB Flash
      ram_size: 64 * 1024,         # 64KB RAM
      cpu_frequency: 48_000_000,   # 48MHz
      peripheral_bus_freq: 48_000_000, # PBCLK = 48MHz
      max_vm_count: 5,             # From vm_config.h
      max_regs_size: 110,          # From vm_config.h
      max_symbols: 255,            # From vm_config.h
      timer1_reserved: true,       # Timer1 used for mruby/c tick
      interrupt_levels: 7          # PIC32 interrupt priority levels
    }
    
    # MRuby/C Runtime Memory Model (from firmware analysis)
    @mruby_memory_model = {
      alloc_type: "MRBC_ALLOC_24BIT",     # 24-bit addressing
      alignment_32bit: true,               # 32-bit alignment required
      alignment_64bit: true,               # 64-bit alignment required
      endian: "MRBC_LITTLE_ENDIAN",       # Little endian
      float_support: 2,                    # Double precision
      string_support: true,                # String class enabled
      math_support: true,                  # Math class enabled
      tick_unit: 1,                        # 1ms tick unit
      timeslice_ticks: 10                  # 10ms timeslice
    }
    
    # Critical Firmware Constraints
    @firmware_constraints = {
      timer1_forbidden: true,              # Timer1 reserved for mruby/c scheduler
      interrupt_stack_size: 2048,          # Interrupt stack requirement
      minimum_heap_size: 8192,             # Minimum heap for mruby/c
      flash_write_protection: true,        # Flash protection during runtime
      uart_console_reserved: true,         # UART used for console/IDE
      critical_interrupt_levels: [1, 2]    # Levels used by system
    }
  end

  # Analyze memory usage patterns in Ruby code
  def analyze_memory_usage(file_path)
    puts "\n=== Advanced Memory Analysis ==="
    puts "Analyzing: #{File.basename(file_path)}"
    
    unless File.exist?(file_path)
      @errors << "File not found: #{file_path}"
      return false
    end
    
    begin
      content = File.read(file_path)
      memory_analysis = analyze_memory_patterns(content, file_path)
      validate_memory_constraints(memory_analysis)
      
      print_memory_analysis_report(memory_analysis)
      true
    rescue => e
      @errors << "Memory analysis failed: #{e.message}"
      false
    end
  end

  # Analyze timing and interrupt constraints
  def analyze_timing_constraints(file_path)
    puts "\n=== Timing & Interrupt Analysis ==="
    puts "Analyzing: #{File.basename(file_path)}"
    
    unless File.exist?(file_path)
      @errors << "File not found: #{file_path}"
      return false
    end
    
    begin
      content = File.read(file_path)
      timing_analysis = analyze_timing_patterns(content, file_path)
      validate_timing_constraints(timing_analysis)
      
      print_timing_analysis_report(timing_analysis)
      true
    rescue => e
      @errors << "Timing analysis failed: #{e.message}"
      false
    end
  end

  # Check for firmware-level conflicts
  def validate_firmware_compatibility(pin_usage, peripheral_config)
    puts "\n=== Firmware Compatibility Check ==="
    
    compatibility_issues = []
    
    # Check Timer1 usage (reserved for mruby/c)
    if peripheral_config.any? { |p| p[:type] == "TIMER" && p[:unit] == 1 }
      compatibility_issues << {
        severity: :error,
        message: "Timer1 is reserved for mruby/c system tick and cannot be used",
        suggestion: "Use Timer2, Timer3, Timer4, or Timer5 instead"
      }
    end
    
    # Check interrupt priority conflicts
    peripheral_config.each do |config|
      if config[:interrupt_priority] && @firmware_constraints[:critical_interrupt_levels].include?(config[:interrupt_priority])
        compatibility_issues << {
          severity: :warning,
          message: "Interrupt priority #{config[:interrupt_priority]} may conflict with system interrupts",
          suggestion: "Use interrupt priorities 3-7 for application code"
        }
      end
    end
    
    # Check UART console conflicts
    console_uart_pins = [[2, 4], [1, 4]]  # Default console UART pins (RB4, RA4)
    pin_usage.each do |(port, pin), usage|
      if console_uart_pins.include?([port, pin])
        compatibility_issues << {
          severity: :warning,
          message: "Pin [#{port},#{pin}] may conflict with console UART",
          suggestion: "Avoid using console UART pins for other peripherals unless specifically needed"
        }
      end
    end
    
    compatibility_issues.each do |issue|
      case issue[:severity]
      when :error
        @errors << issue[:message] + " - " + issue[:suggestion]
      when :warning
        @warnings << issue[:message] + " - " + issue[:suggestion]
      end
    end
    
    print_compatibility_report(compatibility_issues)
    compatibility_issues.select { |i| i[:severity] == :error }.empty?
  end

  # Analyze mruby bytecode implications (if bytecode file available)
  def analyze_bytecode_constraints(mrb_file_path)
    puts "\n=== MRuby Bytecode Analysis ==="
    
    unless File.exist?(mrb_file_path)
      @warnings << "Bytecode file not found: #{mrb_file_path}"
      return true
    end
    
    begin
      File.open(mrb_file_path, 'rb') do |file|
        # Check RITE header
        header = file.read(4)
        if header != "RITE"
          @errors << "Invalid mruby bytecode file: missing RITE header"
          return false
        end
        
        # Skip to size information (simplified analysis)
        file.seek(8)
        bytecode_size = file.read(4).unpack('L<')[0]  # Little endian 32-bit
        
        puts "Bytecode size: #{bytecode_size} bytes"
        
        # Check against flash constraints
        if bytecode_size > (@hardware_specs[:flash_size] * 0.8)  # Leave 20% for firmware
          @errors << "Bytecode too large: #{bytecode_size} bytes (max ~#{(@hardware_specs[:flash_size] * 0.8).to_i} bytes)"
          return false
        end
        
        if bytecode_size > (@hardware_specs[:flash_size] * 0.6)  # Warning at 60%
          @warnings << "Large bytecode: #{bytecode_size} bytes. Consider optimization."
        end
        
        puts "✓ Bytecode size within flash constraints"
        true
      end
    rescue => e
      @errors << "Bytecode analysis failed: #{e.message}"
      false
    end
  end

  # Generate comprehensive firmware analysis report
  def generate_firmware_report
    puts "\n" + "=" * 60
    puts "ADVANCED FIRMWARE ANALYSIS REPORT"
    puts "=" * 60
    
    puts "\n--- Hardware Specifications ---"
    @hardware_specs.each do |key, value|
      puts "#{key.to_s.ljust(20)}: #{format_spec_value(key, value)}"
    end
    
    puts "\n--- MRuby/C Runtime Configuration ---"
    @mruby_memory_model.each do |key, value|
      puts "#{key.to_s.ljust(20)}: #{value}"
    end
    
    puts "\n--- Firmware Constraints ---"
    @firmware_constraints.each do |key, value|
      puts "#{key.to_s.ljust(20)}: #{value}"
    end
    
    if @errors.any?
      puts "\n--- FIRMWARE COMPATIBILITY ERRORS ---"
      @errors.each_with_index do |error, i|
        puts "#{i+1}. #{error}"
      end
    end
    
    if @warnings.any?
      puts "\n--- FIRMWARE COMPATIBILITY WARNINGS ---"
      @warnings.each_with_index do |warning, i|
        puts "#{i+1}. #{warning}"
      end
    end
    
    if @errors.empty?
      puts "\n✓ FIRMWARE COMPATIBILITY: PASSED"
    else
      puts "\n✗ FIRMWARE COMPATIBILITY: FAILED"
    end
  end

  private

  def analyze_memory_patterns(content, source_file)
    analysis = {
      estimated_ram_usage: 0,
      variable_count: 0,
      string_literals: [],
      array_allocations: [],
      hash_allocations: [],
      object_instantiations: [],
      source_file: source_file
    }
    
    lines = content.split("\n")
    lines.each_with_index do |line, index|
      line_num = index + 1
      
      # Count variable assignments (approximate RAM usage)
      if line =~ /^\s*(\w+)\s*=\s*(.+)$/
        analysis[:variable_count] += 1
        analysis[:estimated_ram_usage] += estimate_variable_memory($2.strip)
      end
      
      # String literals
      line.scan(/"([^"]*)"/) do |match|
        analysis[:string_literals] << { content: match[0], line: line_num }
        analysis[:estimated_ram_usage] += match[0].length + 24  # String object overhead
      end
      
      # Array allocations
      if line =~ /Array\.new|(\[.*\])/
        analysis[:array_allocations] << { line: line_num, content: line.strip }
        analysis[:estimated_ram_usage] += 64  # Base array overhead
      end
      
      # Hash allocations
      if line =~ /Hash\.new|(\{.*\})/
        analysis[:hash_allocations] << { line: line_num, content: line.strip }
        analysis[:estimated_ram_usage] += 128  # Base hash overhead
      end
      
      # Object instantiations
      line.scan(/(\w+)\.new/) do |match|
        analysis[:object_instantiations] << { class: match[0], line: line_num }
        analysis[:estimated_ram_usage] += 48  # Base object overhead
      end
    end
    
    analysis
  end

  def analyze_timing_patterns(content, source_file)
    analysis = {
      delay_calls: [],
      timer_usage: [],
      interrupt_handlers: [],
      blocking_operations: [],
      estimated_execution_time: 0,
      source_file: source_file
    }
    
    lines = content.split("\n")
    lines.each_with_index do |line, index|
      line_num = index + 1
      
      # Delay operations
      if line =~ /(sleep|delay|wait)\s*\(\s*(\d+(?:\.\d+)?)\s*\)/
        delay_ms = $2.to_f
        delay_ms *= 1000 if $1 == 'sleep'  # Convert seconds to ms
        analysis[:delay_calls] << { type: $1, duration_ms: delay_ms, line: line_num }
        analysis[:estimated_execution_time] += delay_ms
      end
      
      # Timer operations
      if line =~ /Timer(\d+)/
        timer_num = $1.to_i
        analysis[:timer_usage] << { timer: timer_num, line: line_num, usage: line.strip }
      end
      
      # Potential blocking operations
      if line =~ /(uart.*read|adc.*read|i2c.*read|spi.*transfer)/i
        analysis[:blocking_operations] << { operation: $1, line: line_num }
        analysis[:estimated_execution_time] += 10  # Estimate 10ms for I/O operations
      end
      
      # Loop operations (potential performance impact)
      if line =~ /(while|for|loop)/
        analysis[:estimated_execution_time] += 5  # Base loop overhead
      end
    end
    
    analysis
  end

  def validate_memory_constraints(analysis)
    # Check RAM usage against hardware limits
    if analysis[:estimated_ram_usage] > (@hardware_specs[:ram_size] * 0.8)
      @errors << "Estimated RAM usage (#{analysis[:estimated_ram_usage]} bytes) exceeds safe limit (#{(@hardware_specs[:ram_size] * 0.8).to_i} bytes)"
    elsif analysis[:estimated_ram_usage] > (@hardware_specs[:ram_size] * 0.6)
      @warnings << "High estimated RAM usage: #{analysis[:estimated_ram_usage]} bytes"
    end
    
    # Check variable count against VM limits
    if analysis[:variable_count] > @hardware_specs[:max_regs_size]
      @errors << "Too many variables (#{analysis[:variable_count]}) - VM register limit is #{@hardware_specs[:max_regs_size]}"
    end
    
    # String memory warnings
    total_string_memory = analysis[:string_literals].sum { |s| s[:content].length + 24 }
    if total_string_memory > 4096  # 4KB string limit
      @warnings << "High string memory usage: #{total_string_memory} bytes"
    end
  end

  def validate_timing_constraints(analysis)
    # Check for Timer1 conflicts
    analysis[:timer_usage].each do |timer_info|
      if timer_info[:timer] == 1
        @errors << "Line #{timer_info[:line]}: Timer1 is reserved for mruby/c system tick"
      end
    end
    
    # Check for excessive delays
    analysis[:delay_calls].each do |delay|
      if delay[:duration_ms] > 1000  # > 1 second
        @warnings << "Line #{delay[:line]}: Long delay (#{delay[:duration_ms]}ms) may affect system responsiveness"
      end
    end
    
    # Check total execution time
    if analysis[:estimated_execution_time] > 10000  # > 10 seconds
      @warnings << "High estimated execution time: #{analysis[:estimated_execution_time]}ms"
    end
    
    # Check blocking operations in loops
    blocking_in_main_loop = analysis[:blocking_operations].any? { |op| op[:line] < 50 }
    if blocking_in_main_loop
      @warnings << "Blocking I/O operations detected in main execution path - consider asynchronous patterns"
    end
  end

  def estimate_variable_memory(value_str)
    case value_str
    when /^\d+$/                    # Integer
      return 16
    when /^\d+\.\d+$/              # Float  
      return 24
    when /^".*"$/                  # String
      return value_str.length + 24
    when /^\[.*\]$/                # Array
      return 64 + (value_str.count(',') * 16)
    when /^\{.*\}$/                # Hash
      return 128 + (value_str.count(',') * 32)
    when /\.new/                   # Object instantiation
      return 48
    else
      return 16  # Default variable overhead
    end
  end

  def format_spec_value(key, value)
    case key
    when :flash_size, :ram_size
      "#{value / 1024}KB (#{value} bytes)"
    when :cpu_frequency, :peripheral_bus_freq
      "#{value / 1_000_000}MHz (#{value} Hz)"
    else
      value.to_s
    end
  end

  def print_memory_analysis_report(analysis)
    puts "\n--- Memory Analysis Results ---"
    puts "Estimated RAM usage: #{analysis[:estimated_ram_usage]} bytes"
    puts "Variable count: #{analysis[:variable_count]}"
    puts "String literals: #{analysis[:string_literals].length}"
    puts "Array allocations: #{analysis[:array_allocations].length}"
    puts "Hash allocations: #{analysis[:hash_allocations].length}"
    puts "Object instantiations: #{analysis[:object_instantiations].length}"
    
    ram_percentage = (analysis[:estimated_ram_usage].to_f / @hardware_specs[:ram_size] * 100).round(2)
    puts "RAM usage: #{ram_percentage}% of available #{@hardware_specs[:ram_size] / 1024}KB"
  end

  def print_timing_analysis_report(analysis)
    puts "\n--- Timing Analysis Results ---"
    puts "Delay calls: #{analysis[:delay_calls].length}"
    puts "Timer usage: #{analysis[:timer_usage].length}"
    puts "Blocking operations: #{analysis[:blocking_operations].length}"
    puts "Estimated execution time: #{analysis[:estimated_execution_time]}ms"
    
    analysis[:timer_usage].each do |timer|
      status = timer[:timer] == 1 ? " ⚠️  RESERVED" : " ✅ Available"
      puts "  Timer#{timer[:timer]} (line #{timer[:line]})#{status}"
    end
  end

  def print_compatibility_report(issues)
    if issues.empty?
      puts "✅ No firmware compatibility issues detected"
    else
      puts "\n--- Firmware Compatibility Issues ---"
      issues.each_with_index do |issue, i|
        icon = issue[:severity] == :error ? "❌" : "⚠️ "
        puts "#{i+1}. #{icon} #{issue[:message]}"
        puts "   💡 #{issue[:suggestion]}"
      end
    end
  end
end
