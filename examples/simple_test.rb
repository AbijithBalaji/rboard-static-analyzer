# Simple RBoard test for the static analyzer
# Testing basic peripheral configurations

# Simple ADC usage
adc_sensor = ADC.new("A1")

# Simple PWM usage  
motor = PWM.new("B5")

# Simple GPIO usage
led = GPIO.new("B7")

# This should cause a conflict
conflicting_gpio = GPIO.new("A1")  # A1 already used by ADC
