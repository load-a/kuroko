# frozen_string_literal: true

require_relative 'cpu_display'
# Executes code
class CPU
  include CPUDisplay

  attr_accessor :rom, :ram, :symbol_table

  def initialize(rom, symbol_table)
    self.rom = rom
    self.symbol_table = symbol_table
    self.ram = Array.new(256, 0)

    self.stack_pointer = 255
  end

  REGISTERS.each do |name, address|
    address = address.sub(/[@$]/, '').to_i
    define_method(name) { ram[address] }
    define_method("#{name}=") { |value| ram[address] = value }
  end

  def instruction
    rom[program_counter]
  end

  def run
    loop do
      return if instruction.verb == :end || instruction.verb == 'halt'

      execute_instruction

      self.program_counter += 1
    end
  # ensure
  #   view_ram
  end

  def execute_instruction
    if instruction.verb.is_a? Symbol
      perform_math_or_logic
    elsif %w[move save load swap].include? instruction.verb
      source = ram_value(instruction.direct_object)
      destination = ram_address(instruction.indirect_object)

      case instruction.verb
      when 'move'
        ram[destination] = source
      when 'save'
        source = ram_value(instruction.direct_object)
        destination = ram_address(instruction.indirect_object)
        ram[destination] = source
      when 'load'
        destination = ram_address(instruction.direct_object)
        ram[destination] = ram_value(instruction.indirect_object)
      when 'swap'
        operand = ram_address(instruction.direct_object)
        operator = ram_address(instruction.indirect_object)

        ram[operand], ram[operator] = ram[operator], ram[operand]
      end
    elsif instruction.verb == 'text'
      string = instruction.direct_object.value[1..-2]
      position = ram_address(instruction.indirect_object)

      string.each_byte do |byte|
        ram[position] = byte
        position += 1
      end
    elsif instruction.verb == 'out'
      position = ram_address(instruction.direct_object)
      char_limit = ram_value(instruction.indirect_object).to_i
      char_count = 0
      offset = 0

      loop do
        break if ram[position + offset].zero? || char_count == char_limit

        char = ram[ram_address(instruction.direct_object) + offset].chr
        print char
        char_count += 1
        offset += 1
      end

      puts 
    elsif instruction.verb == 'in'
      destination = ram_address(instruction.direct_object)
      limit = ram_value(instruction.indirect_object)
      offset = 0

      ARGV.clear
      print ">> "
      chars = gets.chomp.bytes[0..limit]
      chars.each_with_index do |byte, offset|
        ram[destination + offset] = byte
      end
    elsif instruction.verb == 'pic'
      # Image is bottom nibble; 
      images = {
        registers:   0b0001,
        flags:       0b0010,
        stack:       0b0100,
        ram:         0b1000,
      }

      # Format is top nibble: first two bits address, second two values
      formats = {
        hex:      0b11,
        decimal:  0b10,
        octal:    0b01,
        binary:   0b00
      }

      address = instruction.direct_object.value & 0b11000000
      values = instruction.direct_object.value &  0b00110000
      image = instruction.direct_object.value &   0b00001111

      puts "PICTURE ##{program_counter - 1}. #{rom[program_counter - 1].to_s}:"
      view_registers if image & 1 == images[:registers]
      view_status if image & 2 == images[:flags]
      view_stack if image & 4 == images[:stack]
      view_ram(formats.key(address >> 6), formats.key(values >> 4)) if image & 8 == images[:ram]

    elsif instruction.verb == 'comp'
      result = ram_value(instruction.direct_object) - ram_value(instruction.indirect_object)
      set_comparison_flags(result)
    elsif %w[pos zero neg].include? instruction.verb
      self.program_counter += case instruction.verb
                              when 'pos'
                                flag_register & 32 > 0 ? ram_value(instruction.direct_object) - 1 : 0
                              when 'zero'
                                flag_register & 16 > 0 ? ram_value(instruction.direct_object) - 1 : 0
                              when 'neg'
                                flag_register & 2 > 0 ? ram_value(instruction.direct_object) - 1 : 0 
                              end
    elsif %w[jgt jge jeq jle jlt jump].include? instruction.verb
      location = instruction.direct_object.value

      if instruction.verb == 'jump'
        self.program_counter = location - 1
      else
        comparison = ram_value(instruction.indirect_object) - a_register
        set_comparison_flags(comparison)

        case instruction.verb
        when 'jgt'
          self.program_counter = location - 1 if flag_register & 32 > 0
        when 'jge'
          self.program_counter = location - 1 if flag_register & 48 > 0
        when 'jeq'
          self.program_counter = location - 1 if flag_register & 1 > 0
        when 'jle'
          self.program_counter = location - 1 if flag_register & 3 > 0
        when 'jlt'
          self.program_counter = location - 1 if flag_register & 2 > 0
        end
      end
    elsif %w[push pop dump rstr].include? instruction.verb
      case instruction.verb
      when 'push'
        push_stack ram_value(instruction.direct_object)
      when 'pop'
        pop_stack ram_address(instruction.direct_object)
      when 'dump'
        REGISTERS.each do |name, address|
          break if name == :program_counter
          push_stack(send(name))
        end
      when 'rstr'
        register = 6

        7.times do 
          pop_stack(register)
          register -= 1
        end
      end
    elsif %w[call rtrn].include? instruction.verb
      if instruction.verb == 'call'
        destination = instruction.direct_object.value

        push_stack(instruction.indirect_object.value)

        self.program_counter = destination - 1
      else
        self.stack_pointer += 1
        self.program_counter = ram[stack_pointer]
      end
    end
  end

  def push_stack(value)
    ram[stack_pointer] = value
    self.stack_pointer -= 1
  end

  def pop_stack(location)
    self.stack_pointer += 1
    ram[location] = ram[stack_pointer]
  end

  def perform_math_or_logic
    if %i[+ * & | / % - ^].include? instruction.verb
      operand = ram_value(instruction.direct_object)
      operator = ram_value(instruction.indirect_object)
      destination = ram_address(instruction.indirect_object)

      result = operand.send(instruction.verb, operator)
    elsif %i[inc dec << >>].include? instruction.verb
      operand = ram_value(instruction.indirect_object)
      operator = ram_value(instruction.direct_object)
      destination = ram_address(instruction.direct_object)

      if %i[inc dec].include? instruction.verb
        operation = instruction.verb == :inc ? :+ : :-
      else
        operation = instruction.verb
      end

      result = operator.send(operation, operand)
    elsif instruction.verb == '!'.to_sym
      operand = ram_value(instruction.direct_object)
      destination = ram_address(instruction.direct_object)

      result = ~operand
    else 
      raise "Unaccounted for Verb Symbol Detected #{instruction.verb} \n#{instruction.to_s}"
    end

    set_flags(result)

    ram[destination] = result & 0xFF
  end

  def set_flags(value)
    self.flag_register &= 0b00000000

    # Compare and Condition flags are set externally
    self.flag_register |= 1 if value.zero?
    self.flag_register |= 2 if value.negative?
    self.flag_register |= 4 if value > 255
    self.flag_register |= 8 unless (-128..127).include? value
    self.flag_register |= 64 if (value & 0xFF).to_s(2).count('1').even?
  end

  def set_comparison_flags(difference)
    set_flags(difference)
    if difference.zero?
      self.flag_register |= 16
    elsif difference.positive?
      self.flag_register |= 32
    end
  end

  def ram_address(token)
    case token.type
    when :register, :variable
      address = lookup(token.value)
      token.subtype == :direct ? address : ram[address]
    when :address
      token.subtype == :direct ? token.value : ram[token.value]
    end
  end

  def lookup(entry)
    raise "Entry not found: #{entry} \n#{instruction}" unless symbol_table[entry]
    symbol_table[entry].sub(/[$]/, '').to_i
  end

  def ram_value(token)
    case token.type
    when :number
      token.value
    when :register, :variable
      ram[ram_address(token)]
    when :address
      if token.subtype == :direct
        ram[token.value]
      else
        ram[ram[token.value]]
      end
    else
    end
  end
end
