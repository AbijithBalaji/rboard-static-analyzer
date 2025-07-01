# Valid RBoard Configuration Example
# This configuration has no hardware conflicts

# Temperature monitoring system
temperature_sensor = ADC.new("A0")    # Valid ADC pin
humidity_sensor = ADC.new("A1")        # Valid ADC pin

# Motor control (using different pins to avoid conflict)
fan_motor = PWM.new("B1")              # Valid PWM pin (OC2)
pump_motor = PWM.new("B0")             # Valid PWM pin (OC3)

# Status indicators
green_led = GPIO.new("B7")             # Valid GPIO pin
red_led = GPIO.new("B8")               # Valid GPIO pin
blue_led = GPIO.new("B9")              # Valid GPIO pin

# User interface
start_button = GPIO.new("A2")          # Valid GPIO pin
stop_button = GPIO.new("A3")           # Valid GPIO pin

# Data logging (using UART with non-conflicting pins)
uart_unit = UART.new(1, txd_pin: "B4", rxd_pin: "A4")  # UART1 with proper pin specification

# External flash memory (using non-conflicting pins)
flash_clock = SPI.new("B14")           # Valid SPI SCK pin
flash_data = SPI.new("B5")             # Valid SPI SDI pin

puts "System configured successfully!"
puts "All peripherals use valid pins with no conflicts"
