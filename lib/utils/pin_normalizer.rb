# Pin normalization utility
# Converts various pin formats to standard [port, pin] format

class PinNormalizer
  # Convert pin number or string to [port, pin_num] format
  def self.normalize(pin)
    if pin.is_a?(String)
      normalize_string_pin(pin)
    else
      normalize_number_pin(pin)
    end
  end

  private

  # Handle string pins like "A0", "B3", "RA1", "RB15"
  def self.normalize_string_pin(pin)
    # Handle both "A0" and "RA0" formats
    if pin.match(/^R?([AB])(\d+)$/i)
      port_letter = $1.upcase
      pin_num = $2.to_i
      port = (port_letter == 'A') ? 1 : 2
      
      validate_pin_range(port, pin_num, pin)
      return [port, pin_num]
    else
      raise "Invalid pin string format: #{pin}. Use format like 'A0', 'B3', 'RA1', 'RB15'"
    end
  end

  # Handle numeric pins (0-20 mapping)
  def self.normalize_number_pin(pin)
    pin_num = pin.to_i
    
    # Map pin numbers to port/pin
    if pin_num >= 0 && pin_num <= 4
      return [1, pin_num]  # Port A (RA0-RA4)
    elsif pin_num >= 5 && pin_num <= 20
      return [2, pin_num - 5]  # Port B (RB0-RB15)
    else
      raise "Invalid pin number: #{pin_num}. Valid range: 0-20"
    end
  end

  # Validate pin exists on the hardware
  def self.validate_pin_range(port, pin_num, original_pin)
    if port == 1 && pin_num > 4
      raise "Invalid pin #{original_pin}: Port A only has pins 0-4"
    elsif port == 2 && pin_num > 15
      raise "Invalid pin #{original_pin}: Port B only has pins 0-15"
    end
  end

  # Convert [port, pin] back to string format
  def self.to_string(port_pin)
    port, pin = port_pin
    port_letter = (port == 1) ? 'A' : 'B'
    "#{port_letter}#{pin}"
  end

  # Convert [port, pin] to register name
  def self.to_register(port_pin)
    port, pin = port_pin
    port_letter = (port == 1) ? 'A' : 'B'
    "R#{port_letter}#{pin}"
  end

  # Get all valid pin numbers (0-20)
  def self.get_valid_pin_numbers
    (0..20).to_a
  end

  # Get all valid string formats
  def self.get_valid_pin_strings
    pins = []
    # Port A: A0-A4
    (0..4).each { |i| pins << "A#{i}" }
    # Port B: B0-B15  
    (0..15).each { |i| pins << "B#{i}" }
    pins
  end
end
