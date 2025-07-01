# RBoard Static Analyzer

A board-specific static analysis tool that extends the mruby compilation process to catch RBoard hardware conflicts before deployment.

## Project Overview

This tool analyzes Ruby code written for RBoard (mruby/c) and detects hardware-related errors at compile-time rather than runtime, saving development time and preventing deployment issues.

## Features

### Phase 1: Static Analysis Framework 
- **Pin Usage Tracker**: Detects pin conflicts and validates pin numbers
- **Pin String Support**: Handles RBoard-specific pin names like "B1", "A2"
- **Clear Error Reporting**: Shows exact line numbers and conflict details

### Planned Features
- **Memory Usage Tracker**: Monitor RAM and resource consumption
- **Frequency Conflict Detection**: Validate PWM and clock frequencies
- **API Validator**: Ensure proper RBoard API usage
- **Rules Engine**: Board-specific hardware constraint validation
- **IDE Integration**: Real-time feedback during development

## Quick Start

```bash
# Clone the repository
git clone https://github.com/AbijithBalaji/rboard-static-analyzer.git
cd rboard-static-analyzer

# Run the demo
ruby phase1_pin_tracker.rb

# Run comprehensive tests
ruby test_pin_tracker.rb
```

## Usage Example

```ruby
require_relative 'phase1_pin_tracker'

tracker = PinUsageTracker.new

# This will pass
tracker.use_pin(1, "GPIO", 1)    # gpio1 = GPIO.new(1, GPIO::OUT)
tracker.use_pin(2, "ADC", 2)     # adc1 = ADC.new(2)

# This will detect a conflict
tracker.use_pin(1, "PWM", 3)     # Pin 1 already used by GPIO!

# This will catch invalid pin
tracker.use_pin(25, "SPI", 4)    # Invalid pin (valid range: 0-20)

tracker.print_summary()
```

## Output Example

```
[INFO] Pin 1 registered for GPIO on line 1
[INFO] Pin 2 registered for ADC on line 2

=== Pin Usage Summary ===
Pin 1: GPIO (line 1)
Pin 2: ADC (line 2)

=== Errors ===
[ERROR] Line 3: Pin 1 already used by GPIO on line 1
[ERROR] Line 4: Invalid pin 25 (valid range: 0-20)
```

## RBoard Hardware Support

- **Valid Pin Range**: 0-20
- **Pin String Mapping**: "B1" → 6, "A2" → 7
- **Supported Peripherals**: GPIO, ADC, PWM, UART, SPI, I2C
- **Board**: RBoard with PIC32MX170F256B

## Development Phases

1. **Phase 1**: Static Analysis Framework (Current)
2. **Phase 2**: Board-Specific Rules Engine
3. **Phase 3**: Integration with mrbc compiler and IDE

## Contributing

This is an academic collaboration project. For contributions or questions, please open an issue or submit a pull request.

## License

MIT License - See LICENSE file for details.

## Related Projects

- [mruby](https://github.com/mruby/mruby) - Lightweight Ruby implementation
- [mruby/c](https://github.com/mrubyc/mrubyc) - mruby for microcontrollers
- [RBoard Documentation](https://yoshihiroogura.github.io/RBoardDocument/)

## Academic Context

This project is part of research into hardware-aware static analysis for embedded Ruby systems, focusing on preventing runtime errors through compile-time validation.
