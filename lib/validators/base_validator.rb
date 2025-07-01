# Base class for all peripheral validators
# Defines the interface that all validators must implement

class BaseValidator
  attr_reader :name

  def initialize(name)
    @name = name
    @constraints = {}
    initialize_constraints
  end

  # Override this method in subclasses to define peripheral-specific constraints
  def initialize_constraints
    raise NotImplementedError, "Subclasses must implement initialize_constraints"
  end

  # Check if a pin can be used by this peripheral
  def can_use_pin?(port_pin)
    @constraints.key?(port_pin)
  end

  # Validate pin usage for this peripheral
  def validate_pin(port_pin, line_number)
    unless can_use_pin?(port_pin)
      return {
        valid: false,
        error: "Line #{line_number}: Pin #{port_pin} cannot be used for #{@name}. Valid pins: #{valid_pins_list}"
      }
    end
    
    {
      valid: true,
      info: get_pin_info(port_pin),
      warnings: []
    }
  end

  # Get hardware-specific information about a pin
  def get_pin_info(port_pin)
    @constraints[port_pin] || {}
  end

  # Generate list of valid pins for error messages
  def valid_pins_list
    @constraints.keys.map { |port, pin| "[#{port},#{pin}]" }.join(", ")
  end

  # Get all valid pins for this peripheral
  def get_valid_pins
    @constraints.keys
  end

  # Get constraint details for a specific pin
  def get_constraints(port_pin)
    @constraints[port_pin]
  end
end
