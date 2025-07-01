#!/usr/bin/env ruby

# RBoard Static Analyzer - Main Entry Point
# Hardware-accurate static analysis based on actual RBoard firmware

require_relative 'lib/rboard_hardware_analyzer'

def show_usage
  puts "RBoard Static Analyzer - Hardware Validation for Embedded Ruby"
  puts "Usage: ruby rboard_analyzer.rb [options] [files...]"
  puts ""
  puts "Options:"
  puts "  --version              Show version information"
  puts "  --capabilities         Show hardware capabilities"
  puts "  --verbose              Enable verbose output"
  puts "  --help                 Show this help message"
  puts ""
  puts "Examples:"
  puts "  ruby rboard_analyzer.rb my_code.rb"
  puts "  ruby rboard_analyzer.rb project1.rb project2.rb"
  puts "  ruby rboard_analyzer.rb --capabilities"
end

def show_version
  puts "RBoard Static Analyzer v1.0.0"
  puts "Hardware-accurate validation for RBoard embedded systems"
  puts "Based on PIC32MX170F256B firmware constraints"
end

# Process command line arguments
if __FILE__ == $0
  args = ARGV.dup
  verbose = false
  files = []
  
  # Parse arguments
  while arg = args.shift
    case arg
    when '--help', '-h'
      show_usage
      exit 0
    when '--version', '-v'
      show_version
      exit 0
    when '--capabilities', '-c'
      analyzer = RBoardAnalyzer.new
      analyzer.print_hardware_info
      exit 0
    when '--verbose'
      verbose = true
    when /^-/
      puts "Unknown option: #{arg}"
      show_usage
      exit 1
    else
      files << arg
    end
  end
  
  # If no files provided, show demo
  if files.empty?
    puts "=== RBoard Static Analyzer Demo ==="
    puts "Modular Architecture with Firmware-Based Validation"
    puts "=" * 50
    
    analyzer = RBoardAnalyzer.new
    
    puts "\n--- Hardware Capabilities ---"
    analyzer.print_hardware_info
    
    puts "\n--- Demo Pin Validation ---"
    
    # Valid cases
    analyzer.use_pin("A0", "ADC", 1)     # Valid: RA0 is AN0
    analyzer.use_pin("B4", "PWM", 2)     # Valid: RB4 is OC1 PWM
    analyzer.use_pin("A3", "GPIO", 3)    # Valid: any pin can be GPIO
    
    # Invalid cases to test validation
    analyzer.use_pin("A0", "PWM", 4)     # Conflict: A0 already used
    analyzer.use_pin("A4", "ADC", 5)     # Invalid: RA4 is not an ADC pin
    analyzer.use_pin("B16", "GPIO", 6)   # Invalid: RB16 doesn't exist
    analyzer.use_pin(25, "SPI", 7)       # Invalid: SPI not loaded, pin doesn't exist
    
    analyzer.print_summary
    
    puts "\n--- Architecture Benefits ---"
    puts "✓ Modular: Each peripheral in separate file"
    puts "✓ Extensible: Easy to add new peripherals" 
    puts "✓ Testable: Each validator can be tested independently"
    puts "✓ Maintainable: Clear separation of concerns"
    puts "✓ Firmware-based: 100% accurate hardware constraints"
    
    puts "\nTo analyze Ruby files, use: ruby rboard_analyzer.rb your_file.rb"
  else
    # Analyze provided files
    puts "=== RBoard Static Analyzer ==="
    puts "Analyzing Ruby files for hardware conflicts"
    puts "=" * 50
    
    analyzer = RBoardAnalyzer.new
    total_errors = 0
    
    files.each do |file|
      unless File.exist?(file)
        puts "ERROR: File not found: #{file}"
        total_errors += 1
        next
      end
      
      puts "\n--- Analyzing #{file} ---"
      result = analyzer.analyze_ruby_file(file)
      
      if verbose
        puts "Parse result: #{result}"
      end
    end
    
    # Show final summary
    puts "\n" + "=" * 50
    analyzer.print_summary
    
    if analyzer.valid?
      puts "\n✓ Analysis complete: No hardware conflicts detected!"
      exit 0
    else
      puts "\n✗ Analysis complete: Hardware conflicts detected!"
      exit 1
    end
  end
end
