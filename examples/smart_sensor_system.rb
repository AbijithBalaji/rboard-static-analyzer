# RBoard Smart Sensor System Example
# Demonstrates a real-world IoT sensor application

# Sensor Configuration
temperature_adc = ADC.new("A0")    # Temperature sensor
humidity_adc = ADC.new("A1")       # Humidity sensor  
light_adc = ADC.new("B0")          # Light sensor

# Actuator Configuration
fan_pwm = PWM.new("B3")            # Cooling fan control
heater_pwm = PWM.new("B4")         # Heater control

# Status Indicators
status_green = GPIO.new("B7")      # System OK LED
status_red = GPIO.new("B8")        # Error LED
status_blue = GPIO.new("B9")       # Data transmission LED

# Communication Interface
i2c_display_scl = I2C.new("B3")    # OLED display - CONFLICT with fan!
i2c_display_sda = I2C.new("B2")    # OLED display data

# Data Logging
uart_log_tx = UART.new("B4")       # Data logging - CONFLICT with heater!
uart_log_rx = UART.new("A4")       # Data logging receive

# External Memory Interface
spi_flash_clk = SPI.new("B14")     # Flash memory clock
spi_flash_data = SPI.new("B5")     # Flash memory data

# Input Controls
reset_button = GPIO.new("A2")      # Manual reset button
mode_button = GPIO.new("A3")       # Mode selection button

# This configuration has multiple conflicts:
# 1. B3 used by both fan_pwm and i2c_display_scl
# 2. B4 used by both heater_pwm and uart_log_tx
# The static analyzer should detect these conflicts
