require_relative 'base_validator'

# SPI-specific validator based on RBoard firmware spi.c
class SPIValidator < BaseValidator
  def initialize
    super("SPI")
  end

  def initialize_constraints
    # Real SPI pins from spi.c firmware implementation
    # PIC32MX170F256B has 2 SPI units with specific pin assignments
    @constraints = {
      # SPI1 Unit - SDI pins: A1, B1, B5, B8, B11
      [1, 1] => { unit: 1, function: "SDI", register: "RA1" },
      [2, 1] => { unit: 1, function: "SDI", register: "RB1" },
      [2, 5] => { unit: 1, function: "SDI", register: "RB5" },
      [2, 8] => { unit: 1, function: "SDI", register: "RB8" },
      [2, 11] => { unit: 1, function: "SDI", register: "RB11" },
      
      # SPI2 Unit - SDI pins: A2, B2, B6, B13 (excluding overlaps)
      # Note: A2, B2, B6, B13 are SDI2-only pins
      # [1, 2] handled separately as it can be SDI2 or SDO
      # [2, 2] handled separately as it can be SDI2 or SDO  
      # [2, 6] handled separately as it can be SDI2 or SDO
      # [2, 13] handled separately as it can be SDI2 or SDO
      
      # SCK pins (fixed per unit)
      [2, 14] => { unit: 1, function: "SCK", register: "RB14" },
      [2, 15] => { unit: 2, function: "SCK", register: "RB15" },
      
      # Multi-function pins (these can serve multiple roles)
      # A2: SDI2 or SDO
      # A4: SDO only
      # B2: SDI2 or SDO
      # B6: SDI2 or SDO  
      # B13: SDI2 or SDO
    }
    
    # Multi-function pins that need special handling
    @multi_function_pins = {
      [1, 2] => [{ unit: 2, function: "SDI" }, { unit: "1/2", function: "SDO" }],
      [1, 4] => [{ unit: "1/2", function: "SDO" }],
      [2, 2] => [{ unit: 2, function: "SDI" }, { unit: "1/2", function: "SDO" }],
      [2, 6] => [{ unit: 2, function: "SDI" }, { unit: "1/2", function: "SDO" }],
      [2, 13] => [{ unit: 2, function: "SDI" }, { unit: "1/2", function: "SDO" }]
    }
  end

  # Check if a pin can be used by this peripheral
  def can_use_pin?(port_pin)
    @constraints.key?(port_pin) || @multi_function_pins.key?(port_pin)
  end

  def get_pin_info(port_pin)
    if @constraints[port_pin]
      info = @constraints[port_pin]
      " (SPI#{info[:unit]} #{info[:function]}, #{info[:register]})"
    elsif @multi_function_pins[port_pin]
      functions = @multi_function_pins[port_pin].map { |f| "#{f[:function]}" }.join("/")
      " (SPI Multi-function: #{functions})"
    else
      ""
    end
  end

  # Get available SPI units
  def get_available_units
    [1, 2]
  end

  # Check if specific SPI unit is available
  def unit_available?(unit_num)
    [1, 2].include?(unit_num)
  end

  # Get pins for specific SPI unit and function
  def get_pins_for_unit_function(unit_num, function)
    @constraints.select { |port_pin, info| 
      (info[:unit] == unit_num || info[:unit] == "1/2") && info[:function] == function 
    }.keys
  end

  # SPI-specific validation with warnings
  def validate_pin(port_pin, line_number)
    result = super(port_pin, line_number)
    
    # Add SPI-specific warnings
    if result[:valid]
      result[:warnings] ||= []
      
      if @constraints[port_pin]
        info = @constraints[port_pin]
        case info[:function]
        when "SDI"
          result[:warnings] << "Line #{line_number}: SPI#{info[:unit]} requires SDI, SDO, and SCK pins for complete setup"
        when "SCK"
          result[:warnings] << "Line #{line_number}: SCK pin is fixed for SPI#{info[:unit]} (cannot be changed)"
        end
      elsif @multi_function_pins[port_pin]
        result[:warnings] << "Line #{line_number}: Multi-function pin - specify intended use (SDI/SDO)"
      end
      
      # Frequency constraint warning
      result[:warnings] << "Line #{line_number}: SPI frequency range: 9.77kHz - 5MHz only"
    end
    
    result
  end

  # Get default pin configuration for a unit
  def get_default_pins(unit_num)
    case unit_num
    when 1
      { sdi: [2, 5], sdo: [2, 6], sck: [2, 14] }  # B5, B6, B14
    when 2  
      { sdi: [1, 2], sdo: [2, 13], sck: [2, 15] } # A2, B13, B15
    else
      nil
    end
  end
end
