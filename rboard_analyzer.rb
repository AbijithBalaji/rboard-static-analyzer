# Enhanced Phase 1: RBoard Hardware-Accurate Pin Usage Tracker
# Based on actual RBoard firmware implementation

class RBoardHardwareTracker
  def initialize
    @pin_usage = {}  # Stores: pin_number => {peripheral: 'GPIO', line: 1}
    @errors = []     # Stores validation errors
    @warnings = []   # Stores warnings
    
    # Real RBoard hardware constraints from firmware
    initialize_hardware_constraints
  end

  private

  def initialize_hardware_constraints
    # Real ADC pins from adc.c firmware
    @adc_pins = {
      # {port, pin} => ADC_channel
      [1, 0] => 0,   # AN0=RA0
      [1, 1] => 1,   # AN1=RA1  
      [2, 0] => 2,   # AN2=RB0
      [2, 1] => 3,   # AN3=RB1
      [2, 2] => 4,   # AN4=RB2
      [2, 3] => 5,   # AN5=RB3
      [2, 15] => 9,  # AN9=RB15
      [2, 14] => 10, # AN10=RB14
      [2, 13] => 11, # AN11=RB13
      [2, 12] => 12  # AN12=RB12
    }

    # Real PWM pins from pwm.c firmware  
    @pwm_pins = {
      # {port, pin} => {unit, group}
      [1, 0] => {unit: 1, group: "OC1"},   # RPA0
      [2, 3] => {unit: 1, group: "OC1"},   # RPB3
      [2, 4] => {unit: 1, group: "OC1"},   # RPB4
      [2, 15] => {unit: 1, group: "OC1"},  # RPB15
      [2, 7] => {unit: 1, group: "OC1"},   # RPB7
      [1, 1] => {unit: 2, group: "OC2"},   # RPA1
      [2, 5] => {unit: 2, group: "OC2"},   # RPB5
      [2, 1] => {unit: 2, group: "OC2"},   # RPB1
      [2, 11] => {unit: 2, group: "OC2"},  # RPB11
      [2, 8] => {unit: 2, group: "OC2"},   # RPB8
      [1, 2] => {unit: 4, group: "OC4"},   # RPA2
      [2, 6] => {unit: 4, group: "OC4"},   # RPB6
      [1, 4] => {unit: 4, group: "OC4"},   # RPA4
      [2, 13] => {unit: 4, group: "OC4"},  # RPB13
      [2, 2] => {unit: 4, group: "OC4"},   # RPB2
      [1, 3] => {unit: 3, group: "OC3"},   # RPA3
      [2, 14] => {unit: 3, group: "OC3"},  # RPB14
      [2, 0] => {unit: 3, group: "OC3"},   # RPB0
      [2, 10] => {unit: 3, group: "OC3"},  # RPB10
      [2, 9] => {unit: 3, group: "OC3"}    # RPB9
    }

    # Pin number to port/pin mapping (from gpio.c)
    @pin_to_port = {}
    (0..4).each { |pin| @pin_to_port[pin] = [1, pin] }      # Port A (RA0-RA4) 
    (5..20).each { |pin| @pin_to_port[pin] = [2, pin-5] }   # Port B (RB0-RB15)
  end

  public

  # Convert pin number or string to [port, pin_num]
  def normalize_pin(pin)
    if pin.is_a?(String)
      # Handle RBoard pin strings like "A0", "B3", etc.
      if pin.match(/^([AB])(\d+)$/i)
        port_letter = $1.upcase
        pin_num = $2.to_i
        port = (port_letter == 'A') ? 1 : 2
        
        # Validate pin exists
        if port == 1 && pin_num > 4
          raise "Invalid pin #{pin}: Port A only has pins 0-4"
        elsif port == 2 && pin_num > 15
          raise "Invalid pin #{pin}: Port B only has pins 0-15" 
        end
        
        return [port, pin_num]
      else
        raise "Invalid pin string format: #{pin}. Use format like 'A0', 'B3'"
      end
    else
      pin_num = pin.to_i
      unless @pin_to_port[pin_num]
        raise "Invalid pin number: #{pin_num}. Valid range: 0-20"
      end
      return @pin_to_port[pin_num]
    end
  end

  # Check if peripheral can use this pin
  def validate_peripheral_pin(port_pin, peripheral, line_number)
    port, pin = port_pin
    
    case peripheral.upcase
    when "ADC"
      unless @adc_pins[port_pin]
        @errors << "Line #{line_number}: Pin [#{port},#{pin}] cannot be used for ADC. Valid ADC pins: #{adc_pins_list}"
        return false
      end
    when "PWM"  
      unless @pwm_pins[port_pin]
        @errors << "Line #{line_number}: Pin [#{port},#{pin}] cannot be used for PWM. Valid PWM pins: #{pwm_pins_list}"
        return false
      end
    end
    
    true
  end

  # Register pin usage with hardware validation
  def use_pin(pin, peripheral, line_number)
    begin
      port_pin = normalize_pin(pin)
      port, pin_num = port_pin
      
      # Hardware-specific validation
      return false unless validate_peripheral_pin(port_pin, peripheral, line_number)
      
      # Check if pin is already used
      if @pin_usage[port_pin]
        existing = @pin_usage[port_pin]
        @errors << "Line #{line_number}: Pin [#{port},#{pin_num}] already used by #{existing[:peripheral]} on line #{existing[:line]}"
        return false
      end

      # Register the pin usage
      @pin_usage[port_pin] = {
        peripheral: peripheral,
        line: line_number,
        original_pin: pin,
        port: port,
        pin_num: pin_num
      }
      
      puts "[INFO] Pin [#{port},#{pin_num}] registered for #{peripheral} on line #{line_number}"
      true
      
    rescue => e
      @errors << "Line #{line_number}: #{e.message}"
      false
    end
  end

  # Helper methods for error messages
  def adc_pins_list
    @adc_pins.keys.map { |port, pin| "[#{port},#{pin}]" }.join(", ")
  end

  def pwm_pins_list  
    @pwm_pins.keys.map { |port, pin| "[#{port},#{pin}]" }.join(", ")
  end

  # Get validation errors
  def get_errors
    @errors
  end

  # Get warnings
  def get_warnings
    @warnings
  end

  # Check if validation passed
  def valid?
    @errors.empty?
  end

  # Print comprehensive summary
  def print_summary
    puts "\n=== RBoard Hardware Pin Usage Summary ==="
    if @pin_usage.empty?
      puts "No pins used"
    else
      @pin_usage.each do |(port, pin_num), info|
        pin_desc = "Port #{port == 1 ? 'A' : 'B'}, Pin #{pin_num}"
        hardware_info = ""
        
        if info[:peripheral] == "ADC" && @adc_pins[[port, pin_num]]
          hardware_info = " (ADC Channel #{@adc_pins[[port, pin_num]]})"
        elsif info[:peripheral] == "PWM" && @pwm_pins[[port, pin_num]]  
          pwm_info = @pwm_pins[[port, pin_num]]
          hardware_info = " (#{pwm_info[:group]} Unit #{pwm_info[:unit]})"
        end
        
        puts "[#{port},#{pin_num}]: #{info[:peripheral]} #{hardware_info} (line #{info[:line]})"
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
end

# Test with real RBoard hardware constraints
if __FILE__ == $0
  puts "Testing RBoard Hardware-Accurate Pin Tracker..."
  puts "Based on actual PIC32MX170F256B firmware implementation"
  
  tracker = RBoardHardwareTracker.new
  
  puts "\n--- Testing real hardware constraints ---"
  
  # Valid cases
  tracker.use_pin("A0", "ADC", 1)     # Valid: RA0 is AN0
  tracker.use_pin("B3", "PWM", 2)     # Valid: RB3 is OC1 PWM
  tracker.use_pin("A2", "GPIO", 3)    # Valid: any pin can be GPIO
  
  # Invalid cases
  tracker.use_pin("A0", "PWM", 4)     # Conflict: A0 already used
  tracker.use_pin("A4", "ADC", 5)     # Invalid: RA4 is not an ADC pin  
  tracker.use_pin("B16", "GPIO", 6)   # Invalid: RB16 doesn't exist
  tracker.use_pin(25, "SPI", 7)       # Invalid: pin 25 doesn't exist
  
  tracker.print_summary
end
