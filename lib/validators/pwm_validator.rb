require_relative 'base_validator'

# PWM-specific validator based on RBoard firmware pwm.c
class PWMValidator < BaseValidator
  def initialize
    super("PWM")
  end

  def initialize_constraints
    # Real PWM pins from pwm.c firmware implementation  
    # PIC32MX170F256B has 4 Output Compare (OC) units
    @constraints = {
      # OC1 group - can drive any of these pins
      [1, 0] => { unit: 1, group: "OC1", register: "RPA0" },   # RPA0
      [2, 3] => { unit: 1, group: "OC1", register: "RPB3" },   # RPB3
      [2, 4] => { unit: 1, group: "OC1", register: "RPB4" },   # RPB4
      [2, 15] => { unit: 1, group: "OC1", register: "RPB15" }, # RPB15
      [2, 7] => { unit: 1, group: "OC1", register: "RPB7" },   # RPB7

      # OC2 group
      [1, 1] => { unit: 2, group: "OC2", register: "RPA1" },   # RPA1
      [2, 5] => { unit: 2, group: "OC2", register: "RPB5" },   # RPB5
      [2, 1] => { unit: 2, group: "OC2", register: "RPB1" },   # RPB1
      [2, 11] => { unit: 2, group: "OC2", register: "RPB11" }, # RPB11
      [2, 8] => { unit: 2, group: "OC2", register: "RPB8" },   # RPB8

      # OC3 group
      [1, 3] => { unit: 3, group: "OC3", register: "RPA3" },   # RPA3
      [2, 14] => { unit: 3, group: "OC3", register: "RPB14" }, # RPB14
      [2, 0] => { unit: 3, group: "OC3", register: "RPB0" },   # RPB0
      [2, 10] => { unit: 3, group: "OC3", register: "RPB10" }, # RPB10
      [2, 9] => { unit: 3, group: "OC3", register: "RPB9" },   # RPB9

      # OC4 group
      [1, 2] => { unit: 4, group: "OC4", register: "RPA2" },   # RPA2
      [2, 6] => { unit: 4, group: "OC4", register: "RPB6" },   # RPB6
      [1, 4] => { unit: 4, group: "OC4", register: "RPA4" },   # RPA4
      [2, 13] => { unit: 4, group: "OC4", register: "RPB13" }, # RPB13
      [2, 2] => { unit: 4, group: "OC4", register: "RPB2" }    # RPB2
    }
  end

  def get_pin_info(port_pin)
    info = @constraints[port_pin]
    return "" unless info
    " (#{info[:group]} Unit #{info[:unit]})"
  end

  # Get all pins for a specific PWM unit
  def get_pins_for_unit(unit_num)
    @constraints.select { |port_pin, info| info[:unit] == unit_num }.keys
  end

  # Get available PWM units
  def get_available_units
    @constraints.values.map { |info| info[:unit] }.uniq.sort
  end

  # Check if specific PWM unit is available
  def unit_available?(unit_num)
    @constraints.values.any? { |info| info[:unit] == unit_num }
  end
end
