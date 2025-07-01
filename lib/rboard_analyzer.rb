# Main RBoard Hardware Analyzer
# Orchestrates all peripheral validators using modular architecture

require_relative 'validators/base_validator'
require_relative 'validators/adc_validator'
require_relative 'validators/pwm_validator'
require_relative 'validators/gpio_validator'
require_relative 'validators/i2c_validator'
require_relative 'validators/spi_validator'
require_relative 'validators/uart_validator'
require_relative 'utils/pin_normalizer'
require_relative 'ruby_parser'

class RBoardAnalyzer
  attr_reader :pin_usage, :errors, :warnings

  def initialize
    @pin_usage = {}
    @errors = []
    @warnings = []
    @ruby_parser = RubyCodeParser.new
    
    # Initialize modular validators
    @validators = {
      "ADC" => ADCValidator.new,
      "PWM" => PWMValidator.new,
      "GPIO" => GPIOValidator.new,
      "I2C" => I2CValidator.new,
      "SPI" => SPIValidator.new,
      "UART" => UARTValidator.new
      # More validators can be easily added here
    }
  end

  # Register pin usage with validation
  def use_pin(pin, peripheral, line_number)
    begin
      port_pin = PinNormalizer.normalize(pin)
      port, pin_num = port_pin
      
      # Check if pin is already used
      if @pin_usage[port_pin]
        existing = @pin_usage[port_pin]
        @errors << "Line #{line_number}: Pin [#{port},#{pin_num}] already used by #{existing[:peripheral]} on line #{existing[:line]}"
        return false
      end

      # Get appropriate validator
      validator = @validators[peripheral.upcase]
      unless validator
        @errors << "Line #{line_number}: Unknown peripheral: #{peripheral}. Supported: #{supported_peripherals.join(', ')}"
        return false
      end

      # Validate pin for this peripheral
      validation = validator.validate_pin(port_pin, line_number)
      unless validation[:valid]
        @errors << validation[:error]
        return false
      end

      # Handle warnings
      if validation[:warnings] && !validation[:warnings].empty?
        @warnings.concat(validation[:warnings])
      end

      # Register the pin usage
      @pin_usage[port_pin] = {
        peripheral: peripheral.upcase,
        line: line_number,
        original_pin: pin,
        port: port,
        pin_num: pin_num,
        info: validation[:info] || ""
      }
      
      puts "[INFO] Pin [#{port},#{pin_num}] registered for #{peripheral} on line #{line_number}"
      true
      
    rescue => e
      @errors << "Line #{line_number}: #{e.message}"
      false
    end
  end

  # Get list of supported peripherals
  def supported_peripherals
    @validators.keys
  end

  # Check if validation passed
  def valid?
    @errors.empty?
  end

  # Get validator for specific peripheral
  def get_validator(peripheral)
    @validators[peripheral.upcase]
  end

  # Print comprehensive analysis summary
  def print_summary
    puts "\n=== RBoard Hardware Analysis Summary ==="
    puts "Supported peripherals: #{supported_peripherals.join(', ')}"
    puts "Architecture: Modular (#{@validators.size} validators loaded)"
    
    if @pin_usage.empty?
      puts "No pins used"
    else
      puts "\n--- Pin Usage ---"
      @pin_usage.each do |(port, pin_num), info|
        pin_str = PinNormalizer.to_string([port, pin_num])
        register = PinNormalizer.to_register([port, pin_num])
        hardware_info = info[:info]
        puts "#{pin_str} (#{register}): #{info[:peripheral]}#{hardware_info} (line #{info[:line]})"
      end
    end

    if @warnings.any?
      puts "\n=== Warnings ==="
      @warnings.each { |warning| puts "[WARNING] #{warning}" }
    end

    if @errors.any?
      puts "\n=== Errors ==="
      @errors.each { |error| puts "[ERROR] #{error}" }
    else
      puts "\n[SUCCESS] No hardware conflicts detected!"
    end
  end

  # Get hardware capabilities summary
  def print_hardware_info
    puts "\n=== RBoard Hardware Capabilities ==="
    
    @validators.each do |name, validator|
      puts "\n#{name}:"
      if validator.respond_to?(:get_available_channels)
        puts "  Available channels: #{validator.get_available_channels.join(', ')}"
      elsif validator.respond_to?(:get_available_units)
        puts "  Available units: #{validator.get_available_units.join(', ')}"
      end
      puts "  Valid pins: #{validator.get_valid_pins.map { |pp| PinNormalizer.to_string(pp) }.join(', ')}"
    end
  end

  # Reset analyzer state
  def reset
    @pin_usage.clear
    @errors.clear
    @warnings.clear
  end

  # Analyze a Ruby source file for RBoard hardware usage
  def analyze_ruby_file(file_path)
    puts "Analyzing Ruby file: #{file_path}"
    
    # Parse the Ruby file
    unless @ruby_parser.parse_file(file_path)
      @errors.concat(@ruby_parser.get_errors)
      return false
    end
    
    # Get analysis results
    results = @ruby_parser.get_analysis_results()
    
    # Analyze each peripheral type
    analyze_parsed_peripherals(results)
    
    # Generate summary
    generate_file_analysis_summary(file_path, results)
    
    true
  end

  # Analyze multiple Ruby files
  def analyze_ruby_project(file_paths)
    success_count = 0
    
    file_paths.each do |file_path|
      if analyze_ruby_file(file_path)
        success_count += 1
      end
    end
    
    puts "\n=== PROJECT ANALYSIS SUMMARY ==="
    puts "Files analyzed: #{file_paths.length}"
    puts "Successful: #{success_count}"
    puts "Failed: #{file_paths.length - success_count}"
    
    display_cross_file_conflicts
    
    success_count == file_paths.length
  end

  # Display analysis results
  def display_results
    puts "\n=== ANALYSIS RESULTS ==="
    
    if @errors.any?
      puts "\n❌ ERRORS FOUND:"
      @errors.each_with_index do |error, i|
        puts "  #{i+1}. #{error}"
      end
    end
    
    if @warnings.any?
      puts "\n⚠️  WARNINGS:"
      @warnings.each_with_index do |warning, i|
        puts "  #{i+1}. #{warning}"
      end
    end
    
    if @pin_usage.any?
      puts "\n📌 PIN USAGE SUMMARY:"
      @pin_usage.each do |pin_key, usage_info|
        port, pin_num = pin_key
        puts "  Port #{port == 1 ? 'A' : 'B'}, Pin #{pin_num}: #{usage_info[:peripheral]} (#{usage_info[:source]}:#{usage_info[:line]})"
      end
    end
    
    if @errors.empty? && @warnings.empty?
      puts "\n✅ NO ISSUES FOUND - Configuration is valid!"
    end
    
    puts "=" * 50
  end

  # Individual validation methods for each peripheral
  def validate_adc(port, pin, source, line)
    use_pin_advanced([port, pin], "ADC", source, line)
  end

  def validate_pwm(port, pin, source, line)
    use_pin_advanced([port, pin], "PWM", source, line)
  end

  def validate_gpio(port, pin, source, line)
    use_pin_advanced([port, pin], "GPIO", source, line)
  end

  def validate_i2c(sda_port, sda_pin, scl_port, scl_pin, source, line)
    use_pin_advanced([sda_port, sda_pin], "I2C", source, line, "SDA")
    use_pin_advanced([scl_port, scl_pin], "I2C", source, line, "SCL")
  end

  def validate_spi(sck_port, sck_pin, mosi_port, mosi_pin, miso_port, miso_pin, source, line)
    use_pin_advanced([sck_port, sck_pin], "SPI", source, line, "SCK")
    use_pin_advanced([mosi_port, mosi_pin], "SPI", source, line, "MOSI")
    use_pin_advanced([miso_port, miso_pin], "SPI", source, line, "MISO")
  end

  def validate_uart(unit, source, line, txd_pin = nil, rxd_pin = nil)
    validator = @validators["UART"]
    
    if txd_pin && rxd_pin
      use_pin_advanced(txd_pin, "UART", source, line, "TXD")
      use_pin_advanced(rxd_pin, "UART", source, line, "RXD")
    else
      # Use default pins for the UART unit
      default_pins = validator.instance_variable_get(:@default_pins)[unit]
      if default_pins
        use_pin_advanced(default_pins[:tx], "UART", source, line, "TXD")
        use_pin_advanced(default_pins[:rx], "UART", source, line, "RXD")
      else
        @errors << "#{source}:#{line}: Invalid UART unit: #{unit}"
      end
    end
  end

  def use_pin_advanced(port_pin, peripheral, source, line, function = nil)
    # Check if pin is already used
    if @pin_usage[port_pin]
      existing = @pin_usage[port_pin]
      @errors << "#{source}:#{line}: Pin [#{port_pin[0]},#{port_pin[1]}] already used by #{existing[:peripheral]} (#{existing[:source]}:#{existing[:line]})"
      return false
    end

    # Get appropriate validator
    validator = @validators[peripheral.upcase]
    unless validator
      @errors << "#{source}:#{line}: Unsupported peripheral: #{peripheral}"
      return false
    end

    # Validate pin with the peripheral validator
    result = validator.validate_pin(port_pin, line)
    
    if result[:valid]
      @pin_usage[port_pin] = {
        peripheral: peripheral,
        function: function,
        source: source,
        line: line
      }
      
      # Add any warnings from the result
      if result[:warning]
        @warnings << "#{source}:#{line}: #{result[:warning]}"
      end
      
      return true
    else
      @errors << "#{source}:#{line}: #{result[:error]}"
      return false
    end
  end

  private

  def analyze_parsed_peripherals(results)
    # Analyze ADC usage
    results[:adc_calls].each do |call|
      next unless call[:parameters]
      if call[:parameters][0] || call[:parameters][:pin]
        pin_value = call[:parameters][0] || call[:parameters][:pin]
        normalized_pin = normalize_pin_from_parser(pin_value)
        if normalized_pin
          validate_adc(normalized_pin[0], normalized_pin[1], call[:source], call[:line])
        end
      end
    end
    
    # Analyze PWM usage
    results[:pwm_calls].each do |call|
      next unless call[:parameters]
      if call[:parameters][0] || call[:parameters][:pin]
        pin_value = call[:parameters][0] || call[:parameters][:pin]
        normalized_pin = normalize_pin_from_parser(pin_value)
        if normalized_pin
          validate_pwm(normalized_pin[0], normalized_pin[1], call[:source], call[:line])
        end
      end
    end
    
    # Analyze GPIO usage
    results[:gpio_calls].each do |call|
      next unless call[:parameters]
      if call[:parameters][0] || call[:parameters][:pin]
        pin_value = call[:parameters][0] || call[:parameters][:pin]
        normalized_pin = normalize_pin_from_parser(pin_value)
        if normalized_pin
          validate_gpio(normalized_pin[0], normalized_pin[1], call[:source], call[:line])
        end
      end
    end
    
    # Analyze I2C usage
    results[:i2c_calls].each do |call|
      next unless call[:parameters]
      sda_pin = call[:parameters][0] || call[:parameters][:sda_pin]
      scl_pin = call[:parameters][1] || call[:parameters][:scl_pin]
      
      if sda_pin && scl_pin
        sda_normalized = normalize_pin_from_parser(sda_pin)
        scl_normalized = normalize_pin_from_parser(scl_pin)
        
        if sda_normalized && scl_normalized
          validate_i2c(sda_normalized[0], sda_normalized[1], scl_normalized[0], scl_normalized[1], call[:source], call[:line])
        end
      end
    end
    
    # Analyze SPI usage
    results[:spi_calls].each do |call|
      next unless call[:parameters]
      sck_pin = call[:parameters][0] || call[:parameters][:sck_pin]
      mosi_pin = call[:parameters][1] || call[:parameters][:mosi_pin]
      miso_pin = call[:parameters][2] || call[:parameters][:miso_pin]
      
      if sck_pin && mosi_pin && miso_pin
        sck_normalized = normalize_pin_from_parser(sck_pin)
        mosi_normalized = normalize_pin_from_parser(mosi_pin)
        miso_normalized = normalize_pin_from_parser(miso_pin)
        
        if sck_normalized && mosi_normalized && miso_normalized
          validate_spi(sck_normalized[0], sck_normalized[1], 
                      mosi_normalized[0], mosi_normalized[1],
                      miso_normalized[0], miso_normalized[1], call[:source], call[:line])
        end
      end
    end
    
    # Analyze UART usage
    results[:uart_calls].each do |call|
      next unless call[:parameters]
      unit = call[:parameters][0] || call[:parameters][:unit] || 1
      txd_pin = call[:parameters][:txd_pin]
      rxd_pin = call[:parameters][:rxd_pin]
      
      # Use default pins if not specified
      if txd_pin.nil? && rxd_pin.nil?
        validate_uart(unit, call[:source], call[:line])
      else
        txd_normalized = txd_pin ? normalize_pin_from_parser(txd_pin) : nil
        rxd_normalized = rxd_pin ? normalize_pin_from_parser(rxd_pin) : nil
        
        validate_uart(unit, call[:source], call[:line], txd_normalized, rxd_normalized)
      end
    end
  end

  def normalize_pin_from_parser(pin_value)
    case pin_value
    when String
      if pin_value =~ /^([AB])(\d+)$/
        port = $1 == 'A' ? 1 : 2
        pin_num = $2.to_i
        [port, pin_num]
      else
        nil
      end
    when Integer
      [1, pin_value]  # Default to port A
    when Array
      if pin_value.length == 2 && pin_value.all? { |v| v.is_a?(Integer) }
        pin_value
      else
        nil
      end
    else
      nil
    end
  end

  def generate_file_analysis_summary(file_path, results)
    puts "\n--- Analysis Results for #{File.basename(file_path)} ---"
    
    total_peripherals = results[:adc_calls].length + results[:pwm_calls].length + 
                       results[:gpio_calls].length + results[:i2c_calls].length + 
                       results[:spi_calls].length + results[:uart_calls].length
    
    puts "Peripheral instances found: #{total_peripherals}"
    puts "  ADC: #{results[:adc_calls].length}"
    puts "  PWM: #{results[:pwm_calls].length}"
    puts "  GPIO: #{results[:gpio_calls].length}"
    puts "  I2C: #{results[:i2c_calls].length}"
    puts "  SPI: #{results[:spi_calls].length}"
    puts "  UART: #{results[:uart_calls].length}"
    
    if results[:pin_assignments].any?
      puts "\nPin assignments detected:"
      results[:pin_assignments].each do |var_name, pin_info|
        puts "  #{var_name}: #{pin_info[:peripheral] || 'Generic'} on port #{pin_info[:port]}, pin #{pin_info[:pin]}"
      end
    end
  end

  def display_cross_file_conflicts
    # Check for pin conflicts across multiple files
    port_pins = @pin_usage.keys.group_by { |key| key }
    conflicts = port_pins.select { |_, usages| usages.length > 1 }
    
    if conflicts.any?
      puts "\n!!! CROSS-FILE PIN CONFLICTS DETECTED !!!"
      conflicts.each do |port_pin, usages|
        puts "Pin [#{port_pin[0]}, #{port_pin[1]}] used by:"
        usages.each do |usage|
          puts "  - #{usage[:peripheral]} (#{usage[:source]}:#{usage[:line]})"
        end
      end
    end
  end
end
