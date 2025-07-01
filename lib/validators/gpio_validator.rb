require_relative 'base_validator'

# GPIO validator - accepts any valid pin
# Based on RBoard firmware gpio.c constraints
class GPIOValidator < BaseValidator
  def initialize
    super("GPIO")
  end

  def initialize_constraints
    # GPIO can use any valid pin on PIC32MX170F256B
    @constraints = {}
    
    # Port A pins (RA0-RA4)
    (0..4).each do |pin|
      @constraints[[1, pin]] = { 
        register: "RA#{pin}",
        port: "A",
        capabilities: ["digital_io", "analog_optional"]
      }
    end
    
    # Port B pins (RB0-RB15)  
    (0..15).each do |pin|
      @constraints[[2, pin]] = { 
        register: "RB#{pin}",  
        port: "B",
        capabilities: ["digital_io", "analog_optional"]
      }
    end
  end

  # GPIO can use any valid pin, so override validation
  def can_use_pin?(port_pin)
    @constraints.key?(port_pin)
  end

  def validate_pin(port_pin, line_number)
    unless can_use_pin?(port_pin)
      port, pin = port_pin
      return {
        valid: false,
        error: "Line #{line_number}: Invalid pin [#{port},#{pin}]. Valid ports: A(0-4), B(0-15)"
      }
    end
    
    { valid: true, info: "" }
  end

  def get_pin_info(port_pin)
    info = @constraints[port_pin]
    return "" unless info
    ""  # GPIO doesn't need special info display
  end

  # Get all valid GPIO pins
  def get_all_pins
    @constraints.keys
  end

  # Get pins by port
  def get_port_pins(port_letter)
    port_num = port_letter.upcase == 'A' ? 1 : 2
    @constraints.select { |port_pin, info| port_pin[0] == port_num }.keys
  end
end
