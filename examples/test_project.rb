# Sample RBoard project for testing the static analyzer
# This demonstrates various peripheral usage patterns

# ADC sensor reading
temperature_sensor = ADC.new("A1")
light_sensor = ADC.new(pin: "A2")

# PWM motor control
motor1 = PWM.new("B5", frequency: 1000)
motor2 = PWM.new(pin: "B6", frequency: 1500)

# GPIO digital I/O
led = GPIO.new("B7", mode: "output")
button = GPIO.new(pin: "A3", mode: "input")

# I2C sensor communication
i2c_sensor = I2C.new("A4", "A5")  # SDA, SCL
i2c_display = I2C.new(sda_pin: "B8", scl_pin: "B9")

# SPI display communication
spi_display = SPI.new("B2", "B3", "B4")  # SCK, MOSI, MISO
spi_memory = SPI.new(sck_pin: "B10", mosi_pin: "B11", miso_pin: "B12")

# UART communication
uart1 = UART.new(1)  # Default pins for UART1
uart2 = UART.new(unit: 2, txd_pin: "B14", rxd_pin: "B15")

# Main application loop
loop do
  # Read sensors
  temp = temperature_sensor.read
  light = light_sensor.read
  
  # Control motors based on sensor readings
  if temp > 25
    motor1.duty_cycle = 50
  else
    motor1.duty_cycle = 0
  end
  
  # Update LED based on button
  if button.read == 1
    led.write(1)
  else
    led.write(0)
  end
  
  # Send data via UART
  uart1.puts("Temperature: #{temp}, Light: #{light}")
  
  sleep(0.1)
end
