# Comprehensive RBoard Test - demonstrates all peripheral types
# This file shows various RBoard peripheral usage patterns
# The static analyzer will detect pin conflicts and hardware constraints

# ADC Configuration
adc_sensor1 = ADC.new("A0")        # Valid ADC pin
adc_sensor2 = ADC.new("B12")       # Valid ADC pin
adc_sensor3 = ADC.new("A4")        # Invalid - A4 not ADC capable

# PWM Configuration
motor1 = PWM.new("B3")             # Valid PWM pin, OC1
motor2 = PWM.new("B4")             # Valid PWM pin, OC1
servo = PWM.new("A0")              # Conflict - A0 already used by ADC

# GPIO Configuration
led1 = GPIO.new("B7")              # Valid GPIO pin
button = GPIO.new("A2")            # Valid GPIO pin
status_led = GPIO.new("B16")       # Invalid - B16 doesn't exist

# I2C Configuration - Fixed pins only
i2c_device = I2C.new("B3")         # I2C SCL - conflicts with motor1
i2c_data = I2C.new("B2")           # I2C SDA - valid

# SPI Configuration
spi_clock = SPI.new("B14")         # SPI1 SCK - valid
spi_data = SPI.new("B5")           # SPI1 SDI - valid

# UART Configuration
uart_tx = UART.new("B4")           # UART TX - conflicts with motor2
uart_rx = UART.new("A4")           # UART RX - valid

# Complex assignment patterns
temperature_sensor = ADC.new(pin: "B0")  # Named parameter
display = SPI.new("B15", mode: 0)        # Additional parameters

# Variable assignments
sensor_pin = "A1"
pressure_sensor = ADC.new(sensor_pin)    # Variable pin assignment

# Array-style pins (alternative format)
light_sensor = ADC.new([1, 1])           # Port A, Pin 1

puts "RBoard peripheral configuration complete"
puts "Check for hardware conflicts above"
