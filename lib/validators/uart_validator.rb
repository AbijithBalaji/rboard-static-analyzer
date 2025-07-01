require_relative 'base_validator'

# UART-specific validator based on RBoard firmware uart.c
class UARTValidator < BaseValidator
  def initialize
    super("UART")
  end

  def initialize_constraints
    # Real UART pins from uart.c firmware implementation
    # PIC32MX170F256B has 2 UART units with specific pin assignments
    @constraints = {
      # UART1 RX pins: A2, B6, A4, B13, B2 (from UART_RXD_PINS table)
      [1, 2] => { unit: 1, function: "RX", register: "RA2" },
      [2, 6] => { unit: 1, function: "RX", register: "RB6" },
      [1, 4] => { unit: 1, function: "RX", register: "RA4" },
      [2, 13] => { unit: 1, function: "RX", register: "RB13" },
      [2, 2] => { unit: 1, function: "RX", register: "RB2" },
      
      # UART2 RX pins: A1, B5, B1, B11, B8 (from UART_RXD_PINS table)
      [1, 1] => { unit: 2, function: "RX", register: "RA1" },
      [2, 5] => { unit: 2, function: "RX", register: "RB5" },
      [2, 1] => { unit: 2, function: "RX", register: "RB1" },
      [2, 11] => { unit: 2, function: "RX", register: "RB11" },
      [2, 8] => { unit: 2, function: "RX", register: "RB8" },
      
      # Default TX pins (from model_dependent.h)
      [2, 4] => { unit: 1, function: "TX", register: "RB4" },  # UART1_TXD_PIN
      [2, 9] => { unit: 2, function: "TX", register: "RB9" }   # UART2_TXD_PIN
    }
    
    # TX pins are remappable on PIC32, but we'll use defaults for simplicity
    # In a full implementation, we'd include all remappable pins
    @default_pins = {
      1 => { tx: [2, 4], rx: [1, 4] },  # UART1: TX=B4, RX=A4
      2 => { tx: [2, 9], rx: [2, 8] }   # UART2: TX=B9, RX=B8
    }
  end

  def get_pin_info(port_pin)
    info = @constraints[port_pin]
    return "" unless info
    " (UART#{info[:unit]} #{info[:function]}, #{info[:register]})"
  end

  # Get available UART units
  def get_available_units
    [1, 2]
  end

  # Check if specific UART unit is available
  def unit_available?(unit_num)
    [1, 2].include?(unit_num)
  end

  # Get pins for specific UART unit and function
  def get_pins_for_unit_function(unit_num, function)
    @constraints.select { |port_pin, info| 
      info[:unit] == unit_num && info[:function] == function 
    }.keys
  end

  # Get default pin configuration for a unit
  def get_default_pins(unit_num)
    @default_pins[unit_num]
  end

  # UART-specific validation with warnings
  def validate_pin(port_pin, line_number)
    result = super(port_pin, line_number)
    
    # Add UART-specific warnings
    if result[:valid] && @constraints[port_pin]
      info = @constraints[port_pin]
      result[:warnings] ||= []
      
      case info[:function]
      when "RX"
        result[:warnings] << "Line #{line_number}: UART#{info[:unit]} requires both TX and RX pins for full duplex communication"
        result[:warnings] << "Line #{line_number}: UART#{info[:unit]} RX pin - multiple options available"
      when "TX"
        result[:warnings] << "Line #{line_number}: UART#{info[:unit]} TX pin - default assignment (remappable on PIC32)"
      end
      
      # Baud rate constraint warnings
      result[:warnings] << "Line #{line_number}: UART supports standard baud rates (9600, 19200, 38400, 57600, 115200)"
      
      # Default configuration warning
      if unit_num = info[:unit]
        defaults = get_default_pins(unit_num)
        result[:warnings] << "Line #{line_number}: UART#{unit_num} defaults: TX=#{defaults[:tx]}, RX=#{defaults[:rx]}"
      end
    end
    
    result
  end

  # Check for complete UART setup
  def validate_complete_setup(used_pins)
    warnings = []
    
    [1, 2].each do |unit|
      tx_pins = used_pins.select { |pin, info| info[:peripheral] == "UART" && @constraints[pin] && @constraints[pin][:unit] == unit && @constraints[pin][:function] == "TX" }
      rx_pins = used_pins.select { |pin, info| info[:peripheral] == "UART" && @constraints[pin] && @constraints[pin][:unit] == unit && @constraints[pin][:function] == "RX" }
      
      if tx_pins.any? && rx_pins.empty?
        warnings << "UART#{unit} has TX pin but no RX pin - receive capability disabled"
      elsif rx_pins.any? && tx_pins.empty?
        warnings << "UART#{unit} has RX pin but no TX pin - transmit capability disabled"
      end
    end
    
    warnings
  end
end
