# Phase 1: Pin Usage Tracker
# This tracks which pins are used by which peripherals

class PinUsageTracker
  def initialize
    @pin_usage = {}  # Stores: pin_number => {peripheral: 'GPIO', line: 1}
    @errors = []     # Stores validation errors
  end

  # Convert string pins like "B1" to numbers
  def normalize_pin(pin)
    if pin.is_a?(String)
      # RBoard pin mapping: "B1" = pin 6, "A2" = pin ?
      # For now, let's handle basic cases
      case pin.upcase
      when "B1" then 6
      when "A2" then 7  # Example mapping
      else
        raise "Unknown pin string: #{pin}"
      end
    else
      pin.to_i
    end
  end

  # Check if pin is valid (0-20 for RBoard)
  def valid_pin?(pin_num)
    pin_num >= 0 && pin_num <= 20
  end

  # Register pin usage
  def use_pin(pin, peripheral, line_number)
    pin_num = normalize_pin(pin)
    
    # Check if pin number is valid
    unless valid_pin?(pin_num)
      @errors << "Line #{line_number}: Invalid pin #{pin} (valid range: 0-20)"
      return false
    end

    # Check if pin is already used
    if @pin_usage[pin_num]
      existing = @pin_usage[pin_num]
      @errors << "Line #{line_number}: Pin #{pin_num} already used by #{existing[:peripheral]} on line #{existing[:line]}"
      return false
    end

    # Register the pin usage
    @pin_usage[pin_num] = {
      peripheral: peripheral,
      line: line_number,
      original_pin: pin
    }
    
    puts "[INFO] Pin #{pin_num} registered for #{peripheral} on line #{line_number}"
    true
  end

  # Get current pin usage
  def get_pin_usage
    @pin_usage
  end

  # Get validation errors
  def get_errors
    @errors
  end

  # Check if validation passed
  def valid?
    @errors.empty?
  end

  # Print summary
  def print_summary
    puts "\n=== Pin Usage Summary ==="
    if @pin_usage.empty?
      puts "No pins used"
    else
      @pin_usage.each do |pin, info|
        puts "Pin #{pin}: #{info[:peripheral]} (line #{info[:line]})"
      end
    end

    if @errors.any?
      puts "\n=== Errors ==="
      @errors.each { |error| puts "[ERROR] #{error}" }
    else
      puts "\n[SUCCESS] No pin conflicts detected!"
    end
  end
end

# Test our pin tracker
if __FILE__ == $0
  puts "Testing Pin Usage Tracker..."
  
  tracker = PinUsageTracker.new
  
  # Simulate analyzing Ruby code
  puts "\n--- Simulating code analysis ---"
  tracker.use_pin(1, "GPIO", 1)    # gpio1 = GPIO.new(1, GPIO::OUT)
  tracker.use_pin(2, "ADC", 2)     # adc1 = ADC.new(2)
  tracker.use_pin(1, "PWM", 3)     # pwm1 = PWM.new(1) - This should conflict!
  tracker.use_pin("B1", "UART", 4) # uart1 = UART.new(txd_pin: "B1")
  tracker.use_pin(25, "SPI", 5)    # Invalid pin number
  
  tracker.print_summary
end
