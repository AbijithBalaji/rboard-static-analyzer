# Ruby code parser for RBoard static analysis
# Extracts peripheral usage from Ruby code without executing it

class RubyCodeParser
  def initialize
    @peripheral_calls = []
    @pin_assignments = {}
    @variable_assignments = {}
    @errors = []
  end

  # Parse a Ruby file and extract peripheral usage
  def parse_file(file_path)
    unless File.exist?(file_path)
      @errors << "File not found: #{file_path}"
      return false
    end

    begin
      content = File.read(file_path)
      parse_content(content, file_path)
      true
    rescue => e
      @errors << "Error reading #{file_path}: #{e.message}"
      false
    end
  end

  # Parse Ruby code content
  def parse_content(content, source_name = "<string>")
    @current_source = source_name
    @current_line = 0
    
    # Split into lines for line-by-line analysis
    lines = content.split("\n")
    
    lines.each_with_index do |line, index|
      @current_line = index + 1
      parse_line(line.strip)
    end
  end

  # Get all detected peripheral calls
  def get_peripheral_calls
    @peripheral_calls
  end

  # Get all detected pin assignments
  def get_pin_assignments
    @pin_assignments
  end

  # Get parsing errors
  def get_errors
    @errors
  end

  # Get analysis results formatted for the static analyzer
  def get_analysis_results
    {
      adc_calls: filter_calls("ADC"),
      pwm_calls: filter_calls("PWM"),
      gpio_calls: filter_calls("GPIO"),
      i2c_calls: filter_calls("I2C"),
      spi_calls: filter_calls("SPI"),
      uart_calls: filter_calls("UART"),
      pin_assignments: @pin_assignments,
      errors: @errors
    }
  end

  private

  def parse_line(line)
    return if line.empty? || line.start_with?('#')
    
    # Parse variable assignments
    parse_variable_assignment(line)
    
    # Parse peripheral instantiations
    parse_peripheral_new(line)
    
    # Parse method calls on peripherals
    parse_peripheral_method_calls(line)
    
    # Parse direct pin assignments
    parse_pin_assignments(line)
  end

  def parse_variable_assignment(line)
    # Match: variable = value
    if line =~ /^(\w+)\s*=\s*(.+)$/
      var_name = $1
      value = $2.strip
      
      @variable_assignments[var_name] = {
        value: value,
        line: @current_line,
        source: @current_source
      }
    end
  end

  def parse_peripheral_new(line)
    # Match peripheral constructors: ADC.new, PWM.new(pin), etc.
    peripheral_patterns = [
      # ADC.new(pin) or ADC.new(pin: value)
      [/(\w+\s*=\s*)?ADC\.new\s*\(\s*([^)]*)\s*\)/, "ADC"],
      # PWM.new(pin, frequency) or PWM.new(pin: value, frequency: value)
      [/(\w+\s*=\s*)?PWM\.new\s*\(\s*([^)]*)\s*\)/, "PWM"],
      # GPIO.new(pin, mode) or GPIO.new(pin: value, mode: value)
      [/(\w+\s*=\s*)?GPIO\.new\s*\(\s*([^)]*)\s*\)/, "GPIO"],
      # I2C.new(sda_pin, scl_pin) or I2C.new(sda_pin: value, scl_pin: value)
      [/(\w+\s*=\s*)?I2C\.new\s*\(\s*([^)]*)\s*\)/, "I2C"],
      # SPI.new(sck_pin, mosi_pin, miso_pin) or SPI.new(sck_pin: value, ...)
      [/(\w+\s*=\s*)?SPI\.new\s*\(\s*([^)]*)\s*\)/, "SPI"],
      # UART.new(unit) or UART.new(unit: value, txd_pin: value, rxd_pin: value)
      [/(\w+\s*=\s*)?UART\.new\s*\(\s*([^)]*)\s*\)/, "UART"]
    ]
    
    peripheral_patterns.each do |pattern, peripheral_type|
      match = line.match(pattern)
      if match
        variable_name = match[1] ? match[1].gsub(/\s*=\s*$/, '').strip : nil
        parameters = match[2]
        
        call_info = {
          type: peripheral_type,
          variable: variable_name,
          parameters: parse_parameters(parameters),
          line: @current_line,
          source: @current_source,
          raw_line: line
        }
        
        @peripheral_calls << call_info
        
        # Extract pin information
        extract_pins_from_call(call_info)
        break
      end
    end
  end

  def parse_peripheral_method_calls(line)
    # Match method calls on peripheral objects
    # Examples: adc1.read, pwm1.frequency = 1000, gpio1.write(1)
    
    if line =~ /(\w+)\.(\w+)(?:\s*[=\(].*)?/
      object_name = $1
      method_name = $2
      
      # Check if this object was created as a peripheral
      peripheral_var = @peripheral_calls.find { |call| call[:variable] == object_name }
      
      if peripheral_var
        call_info = {
          type: peripheral_var[:type],
          variable: object_name,
          method: method_name,
          line: @current_line,
          source: @current_source,
          raw_line: line
        }
        
        @peripheral_calls << call_info
      end
    end
  end

  def parse_pin_assignments(line)
    # Parse direct pin assignments like: pin = "A1", pin = 5, etc.
    pin_patterns = [
      # String format: "A1", "B12", etc.
      /(\w+)\s*=\s*"([AB]\d+)"/,
      # Array format: [1, 5] for [port, pin]
      /(\w+)\s*=\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/,
      # Integer format: 5 (assuming port A)
      /(\w+)\s*=\s*(\d+)$/
    ]
    
    pin_patterns.each do |pattern|
      if line =~ pattern
        case pattern
        when pin_patterns[0]  # String format
          var_name = $1
          pin_str = $2
          port = pin_str[0] == 'A' ? 1 : 2
          pin_num = pin_str[1..-1].to_i
          
        when pin_patterns[1]  # Array format
          var_name = $1
          port = $2.to_i
          pin_num = $3.to_i
          
        when pin_patterns[2]  # Integer format
          var_name = $1
          port = 1  # Default to port A
          pin_num = $2.to_i
        end
        
        @pin_assignments[var_name] = {
          port: port,
          pin: pin_num,
          line: @current_line,
          source: @current_source
        }
        break
      end
    end
  end

  def parse_parameters(param_string)
    # Simple parameter parsing - handles both positional and keyword arguments
    params = {}
    
    # Split by commas, but be careful with nested structures
    parts = smart_split(param_string)
    
    parts.each_with_index do |part, index|
      part = part.strip
      
      if part.include?(':')
        # Keyword argument: key: value
        key, value = part.split(':', 2)
        params[key.strip.to_sym] = parse_value(value.strip)
      else
        # Positional argument
        params[index] = parse_value(part)
      end
    end
    
    params
  end

  def smart_split(string)
    # Split by comma, but respect brackets and quotes
    return [] if string.nil? || string.empty?
    
    parts = []
    current = ""
    paren_count = 0
    bracket_count = 0
    in_quotes = false
    quote_char = nil
    
    string.each_char do |char|
      case char
      when '"', "'"
        if !in_quotes
          in_quotes = true
          quote_char = char
        elsif char == quote_char
          in_quotes = false
          quote_char = nil
        end
        current += char
      when '('
        paren_count += 1 unless in_quotes
        current += char
      when ')'
        paren_count -= 1 unless in_quotes
        current += char
      when '['
        bracket_count += 1 unless in_quotes
        current += char
      when ']'
        bracket_count -= 1 unless in_quotes
        current += char
      when ','
        if !in_quotes && paren_count == 0 && bracket_count == 0
          parts << current
          current = ""
        else
          current += char
        end
      else
        current += char
      end
    end
    
    parts << current unless current.empty?
    parts.map(&:strip)
  end

  def parse_value(value_str)
    case value_str
    when /^\d+$/
      value_str.to_i
    when /^\d+\.\d+$/
      value_str.to_f
    when /^"(.+)"$/, /^'(.+)'$/
      $1
    when /^\[(.+)\]$/
      # Simple array parsing
      elements = smart_split($1)
      elements.map { |e| parse_value(e) }
    else
      # Check if it's a variable reference
      if @variable_assignments[value_str]
        @variable_assignments[value_str][:value]
      else
        value_str
      end
    end
  end

  def extract_pins_from_call(call_info)
    params = call_info[:parameters]
    
    case call_info[:type]
    when "ADC"
      extract_adc_pins(params, call_info)
    when "PWM"
      extract_pwm_pins(params, call_info)
    when "GPIO"
      extract_gpio_pins(params, call_info)
    when "I2C"
      extract_i2c_pins(params, call_info)
    when "SPI"
      extract_spi_pins(params, call_info)
    when "UART"
      extract_uart_pins(params, call_info)
    end
  end

  def extract_adc_pins(params, call_info)
    pin = params[0] || params[:pin]
    if pin
      normalized_pin = normalize_pin(pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_pin"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "ADC",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
  end

  def extract_pwm_pins(params, call_info)
    pin = params[0] || params[:pin]
    if pin
      normalized_pin = normalize_pin(pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_pin"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "PWM",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
  end

  def extract_gpio_pins(params, call_info)
    pin = params[0] || params[:pin]
    if pin
      normalized_pin = normalize_pin(pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_pin"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "GPIO",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
  end

  def extract_i2c_pins(params, call_info)
    sda_pin = params[0] || params[:sda_pin]
    scl_pin = params[1] || params[:scl_pin]
    
    if sda_pin
      normalized_pin = normalize_pin(sda_pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_sda"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "I2C",
          function: "SDA",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
    
    if scl_pin
      normalized_pin = normalize_pin(scl_pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_scl"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "I2C",
          function: "SCL",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
  end

  def extract_spi_pins(params, call_info)
    sck_pin = params[0] || params[:sck_pin]
    mosi_pin = params[1] || params[:mosi_pin]
    miso_pin = params[2] || params[:miso_pin]
    
    pins = [
      [sck_pin, "SCK"],
      [mosi_pin, "MOSI"],
      [miso_pin, "MISO"]
    ]
    
    pins.each do |pin_value, function|
      if pin_value
        normalized_pin = normalize_pin(pin_value)
        if normalized_pin
          @pin_assignments["#{call_info[:variable]}_#{function.downcase}"] = {
            port: normalized_pin[0],
            pin: normalized_pin[1],
            peripheral: "SPI",
            function: function,
            line: call_info[:line],
            source: call_info[:source]
          }
        end
      end
    end
  end

  def extract_uart_pins(params, call_info)
    txd_pin = params[:txd_pin]
    rxd_pin = params[:rxd_pin]
    
    if txd_pin
      normalized_pin = normalize_pin(txd_pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_txd"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "UART",
          function: "TXD",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
    
    if rxd_pin
      normalized_pin = normalize_pin(rxd_pin)
      if normalized_pin
        @pin_assignments["#{call_info[:variable]}_rxd"] = {
          port: normalized_pin[0],
          pin: normalized_pin[1],
          peripheral: "UART",
          function: "RXD",
          line: call_info[:line],
          source: call_info[:source]
        }
      end
    end
  end

  def normalize_pin(pin_value)
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

  def filter_calls(peripheral_type)
    @peripheral_calls.select { |call| call[:type] == peripheral_type }
  end
end
