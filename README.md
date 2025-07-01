# RBoard Static Analyzer

A hardware-accurate static analysis tool based on actual RBoard firmware implementation. Detects hardware conflicts and validates peripheral usage against real PIC32MX170F256B constraints before deployment.

## Project Overview

This tool analyzes Ruby code written for RBoard (mruby/c) using **actual firmware constraints** extracted from the RBoard firmware source code. It provides 100% accurate hardware validation, preventing deployment issues by catching errors at compile-time.

## Key Features

### Firmware-Based Hardware Validation
- **Real ADC Pin Validation**: Based on actual adc.c firmware implementation  
- **Accurate PWM Constraints**: Uses real pwm.c pin assignments and units
- **Hardware-Specific Errors**: Shows exact reasons why pins cannot be used
- **Production-Grade Accuracy**: Matches actual RBoard firmware behavior

### Current Capabilities  
- **Pin Conflict Detection**: Prevents multiple peripherals from using same pin
- **Peripheral-Pin Validation**: Ensures only valid pins are used for each peripheral
- **Hardware Unit Tracking**: Shows which PWM units, ADC channels are used
- **Professional Error Reporting**: Clear, actionable error messages

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

# Run the firmware-based analyzer
ruby rboard_analyzer.rb

# Run comprehensive tests  
ruby test_pin_tracker.rb
```

## Usage Example

```ruby
require_relative 'rboard_analyzer'

tracker = RBoardHardwareTracker.new

# Valid hardware usage
tracker.use_pin("A0", "ADC", 1)     # ✓ RA0 supports ADC (Channel 0)
tracker.use_pin("B3", "PWM", 2)     # ✓ RB3 supports PWM (OC1 Unit)

# Hardware validation catches errors
tracker.use_pin("A4", "ADC", 3)     # ✗ RA4 cannot be used for ADC
tracker.use_pin("A0", "PWM", 4)     # ✗ A0 already used by ADC

tracker.print_summary()
```

## Output Example

```
[INFO] Pin [1,0] registered for ADC on line 1
[INFO] Pin [2,3] registered for PWM on line 2

=== RBoard Hardware Pin Usage Summary ===
[1,0]: ADC  (ADC Channel 0) (line 1)
[2,3]: PWM  (OC1 Unit 1) (line 2)

=== Errors ===
[ERROR] Line 3: Pin [1,4] cannot be used for ADC. Valid ADC pins: [1,0], [1,1], [2,0]...
[ERROR] Line 4: Pin [1,0] already used by ADC on line 1
```

## Hardware Support

### Based on PIC32MX170F256B Firmware
- **ADC Pins**: RA0, RA1, RB0-RB3, RB12-RB15 (10 channels)
- **PWM Pins**: 4 output compare units (OC1-OC4) with specific pin assignments  
- **Pin Mapping**: Port A (0-4), Port B (5-20)
- **Validation**: 100% matches firmware constraints

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
