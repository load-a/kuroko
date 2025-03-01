# frozen_string_literal: true

require_relative 'cpu_display'
# Executes code
class CPU
  include CPUDisplay

  USER_PROMPT = '[User] << '
  KURO_PROMPT = '[Kuro] >> '

  attr_accessor :rom, :ram, :symbol_table

  def initialize(rom, symbol_table, writes)
    self.rom = rom
    self.symbol_table = symbol_table
    self.ram = Array.new(256, 0)

    self.stack_pointer = 255

    writes.each do |address, value|
      ram[ram_address(address)] = value
    end
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
  end

  def execute_instruction # @note: All arithmetic or logic instructions must have SYMBOL verbs
    return perform_math_or_logic if instruction.verb.is_a? Symbol

    case instruction.verb
    when *%w[move save load swap]
      perform_memory_operation
    when 'text'
      store_text
    when 'out', 'prnt'
      print_text
    when 'in'
      receive_text
    when 'nin'
      receive_number
    when 'nout', 'tlly'
      print_number
    when 'nwln'
      puts
    when 'post'
      print KURO_PROMPT
    when 'pic'
      take_picture
    when 'comp'
      set_comparison_flags(ram_value(instruction.direct_object) - ram_value(instruction.indirect_object))
    when *%w[pos zero neg]
      self.program_counter += case instruction.verb
                              when 'pos'
                                flag_register & 32 > 0 ? ram_value(instruction.direct_object) - 1 : 0
                              when 'zero'
                                flag_register & 16 > 0 ? ram_value(instruction.direct_object) - 1 : 0
                              when 'neg'
                                flag_register & 2 > 0 ? ram_value(instruction.direct_object) - 1 : 0 
                              end
    when *%w[jgt jge jeq jle jlt jump]
      perform_jump
    when *%w[push pop dump rstr]
      perform_stack_operation
    when *%w[call rtrn]
      perform_subroutine_operation
    end
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
    elsif instruction.verb == :rand
      destination = ram_address(instruction.direct_object)
      return write_to_ram(destination, rand(0..255))
    else 
      raise "Unaccounted for Verb Symbol Detected #{instruction.verb} \n#{instruction.to_s}"
    end

    set_flags(result)
    write_to_ram(destination, result)
  end

  def perform_memory_operation
    source = ram_value(instruction.direct_object)
    target = ram_address(instruction.direct_object)

    destination = ram_address(instruction.indirect_object)

    case instruction.verb
    when 'move', 'save'
      write_to_ram(destination, source)
    when 'load'
      write_to_ram(target, ram_value(instruction.indirect_object))
    when 'swap'
      raise "Cannot write to PC, SP or FLAG Registers " if [target, destination].any? { |item| item.between?(7, 9) }
      ram[target], ram[destination] = ram[destination], ram[target]
    end
  end

  def perform_stack_operation
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
  end

  def push_stack(value)
    ram[stack_pointer] = value
    self.stack_pointer -= 1
  end

  def pop_stack(location)
    self.stack_pointer += 1
    write_to_ram(location, ram[stack_pointer])
  end

  def perform_subroutine_operation
    if instruction.verb == 'call'
      destination = instruction.direct_object.value

      push_stack(instruction.indirect_object.value)

      self.program_counter = destination - 1
    else
      self.stack_pointer += 1
      self.program_counter = ram[stack_pointer]
    end
  end

  def perform_jump
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
  end

  def store_text
    string = instruction.indirect_object.value[1..-2]
    position = ram_address(instruction.direct_object)

    string.each_byte do |byte|
      write_to_ram(position, byte)
      position += 1
    end

    write_to_ram(position, 0)
  end

  def print_text
    char_limit = ram_value(instruction.indirect_object)

    if instruction.direct_object.type == :string
      return puts instruction.direct_object.value[1..char_limit] if instruction.verb == 'out'

      return print instruction.direct_object.value[1..char_limit]
    end

    position = ram_address(instruction.direct_object)
    char_count = 0
    offset = 0

    print KURO_PROMPT unless instruction.verb == 'prnt'
    return if instruction.verb == 'post'

    loop do
      break if ram[position + offset].zero? || char_count == char_limit

      char = ram[ram_address(instruction.direct_object) + offset].chr
      print char
      char_count += 1
      offset += 1
    end

    puts if instruction.verb == 'out'
  end

  def receive_text
    destination = ram_address(instruction.direct_object)
    limit = ram_value(instruction.indirect_object)
    offset = 0

    ARGV.clear
    print USER_PROMPT

    chars = gets.chomp.bytes[0..limit]
    chars.each_with_index do |byte, offset|
      write_to_ram(destination + offset, byte)
    end
  end

  def receive_number
    destination = ram_address(instruction.direct_object)

    ARGV.clear
    print USER_PROMPT

    number = gets.chomp.to_i

    if number.negative?
      number = number.clamp(-128, 127)
    else
      number %= 256
    end

    write_to_ram(destination, number)
  end

  def print_number
    position = ram_address(instruction.direct_object)
    puts KURO_PROMPT unless instruction.verb == 'tlly'
    print ram[position]
    puts if instruction.verb == 'nout'
  end

  def take_picture
    formats = {
      hex:      0b11,
      decimal:  0b10,
      octal:    0b01,
      binary:   0b00
    }
    images = {
      registers:   0b0001,
      flags:       0b0010,
      stack:       0b0100,
      ram:         0b1000,
    }

    # RAM format is top nibble: first two bits for addresses...
    address = instruction.direct_object.value & 0b11000000
    # ...second two for values.
    values = instruction.direct_object.value & 0b00110000
    # Image itself is bottom nibble.
    image = instruction.direct_object.value & 0b00001111

    puts '- - -', "PICTURE of ##{program_counter - 1} #{rom[program_counter - 1].to_s}:"

    view_registers if image & 1 == images[:registers]
    view_status if image & 2 == images[:flags]
    view_stack if image & 4 == images[:stack]
    view_ram(formats.key(address >> 6), formats.key(values >> 4)) if image & 8 == images[:ram]
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

  # Returns the RAM Address of a token
  def ram_address(token)
    return token.sub(/[@$]/, '').to_i if token.is_a? String
    
    case token.type
    when :register, :variable
      address = lookup(token.value)
      token.subtype == :direct ? address : ram[address]
    when :address
      token.subtype == :direct ? token.value : ram[token.value]
    end
  end

  # Looks up its entry in the Symbol Table
  def lookup(entry)
    raise "Entry not found: #{entry} \n#{instruction}" unless symbol_table[entry]
    symbol_table[entry].sub(/[$]/, '').to_i
  end

  # Returns the value of an address in RAM
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
      raise "Token's RAM value not accounted for: #{token}"
    end
  end

  def write_to_ram(address, value)
    raise "Cannot write to PC, SP or FLAG Registers: \n$#{address} =/= #{value} \n#{instruction}" if address.between?(7, 9)
    raise "Cannot write into Stack, \n$#{address} =/= #{value} \n#{instruction}" if address >= 240
    ram[address] = value
  end
end
