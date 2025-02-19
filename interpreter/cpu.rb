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
  end

  def execute_instruction
    if instruction.verb.is_a? Symbol
      perform_math_or_logic
    elsif %w[move save].include? instruction.verb
      source = ram_value(instruction.direct_object)
      destination = ram_address(instruction.indirect_object)

      case instruction.verb
      when 'move'
        ram[destination] = source
      when 'save'
        source = ram_value(instruction.direct_object)
        destination = ram_address(instruction.indirect_object)
        ram[destination] = source
      end
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

      result = operand ^ 0xFF
    else 
      raise "Unaccounted for Verb Symbol Detected #{instruction.verb} \n#{instruction.to_s}"
    end

    set_flags(result)

    ram[destination] = result
  end

  def set_flags(value)
      flag = 0

      flag += 1 if value.zero?
      flag += 2 if value.negative?
      flag += 4 if value > 255
      flag += 8 unless (-128..127).include? value
    # flag += 16 if comparison was true -> SET EXTERNALLY
    # flag += 32 if condition was Greater-Than -> SET EXTERNALLY
      flag += 64 if ('%b' % value).count('1').even?

      self.flag_register = flag
  end

  def ram_address(token)
    case token.type
    when :register
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
    when :register
      ram[ram_address(token)]
    else
    end
  end
end
