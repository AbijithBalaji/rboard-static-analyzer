require_relative 'base_validator'

# I2C-specific validator based on RBoard firmware i2c.c
class I2CValidator < BaseValidator
  def initialize
    super("I2C")
  end

  def initialize_constraints
    # Real I2C pins from i2c.c firmware implementation
    # PIC32MX170F256B uses I2C2 module only: SCL=B3, SDA=B2
    # Fixed pins, 100kHz frequency only
    @constraints = {
      [2, 3] => { function: "SCL", module: "I2C2", register: "RB3" },   # B3 = SCL
      [2, 2] => { function: "SDA", module: "I2C2", register: "RB2" }    # B2 = SDA
    }
  end

  def get_pin_info(port_pin)
    info = @constraints[port_pin]
    return "" unless info
    " (I2C2 #{info[:function]}, #{info[:register]})"
  end

  # Get available I2C functions
  def get_available_functions
    @constraints.values.map { |info| info[:function] }.sort
  end

  # Check if specific I2C function is available
  def function_available?(function)
    @constraints.values.any? { |info| info[:function] == function }
  end

  # Get pin for specific I2C function
  def get_pin_for_function(function)
    @constraints.find { |port_pin, info| info[:function] == function }&.first
  end

  # I2C-specific validation
  def validate_pin(port_pin, line_number)
    result = super(port_pin, line_number)
    
    # Add I2C-specific warnings
    if result[:valid] && @constraints[port_pin]
      info = @constraints[port_pin]
      if info[:function] == "SCL" || info[:function] == "SDA"
        result[:warnings] ||= []
        result[:warnings] << "Line #{line_number}: I2C requires both SCL (B3) and SDA (B2) pins for proper operation"
        result[:warnings] << "Line #{line_number}: I2C2 module operates at 100kHz only"
      end
    end
    
    result
  end
end
