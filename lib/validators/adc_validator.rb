require_relative 'base_validator'

# ADC-specific validator based on RBoard firmware adc.c
class ADCValidator < BaseValidator
  def initialize
    super("ADC")
  end

  def initialize_constraints
    # Real ADC pins from adc.c firmware implementation
    # Only these pins have ADC capability on PIC32MX170F256B
    @constraints = {
      [1, 0] => { channel: 0, name: "AN0", register: "RA0" },   # AN0=RA0
      [1, 1] => { channel: 1, name: "AN1", register: "RA1" },   # AN1=RA1  
      [2, 0] => { channel: 2, name: "AN2", register: "RB0" },   # AN2=RB0
      [2, 1] => { channel: 3, name: "AN3", register: "RB1" },   # AN3=RB1
      [2, 2] => { channel: 4, name: "AN4", register: "RB2" },   # AN4=RB2
      [2, 3] => { channel: 5, name: "AN5", register: "RB3" },   # AN5=RB3
      [2, 15] => { channel: 9, name: "AN9", register: "RB15" }, # AN9=RB15
      [2, 14] => { channel: 10, name: "AN10", register: "RB14" }, # AN10=RB14
      [2, 13] => { channel: 11, name: "AN11", register: "RB13" }, # AN11=RB13
      [2, 12] => { channel: 12, name: "AN12", register: "RB12" }  # AN12=RB12
    }
  end

  def get_pin_info(port_pin)
    info = @constraints[port_pin]
    return "" unless info
    " (ADC Channel #{info[:channel]}, #{info[:name]})"
  end

  # Get available ADC channels
  def get_available_channels
    @constraints.values.map { |info| info[:channel] }.sort
  end

  # Check if specific ADC channel is available
  def channel_available?(channel_num)
    @constraints.values.any? { |info| info[:channel] == channel_num }
  end

  # Get pin for specific ADC channel
  def get_pin_for_channel(channel_num)
    @constraints.find { |port_pin, info| info[:channel] == channel_num }&.first
  end
end
