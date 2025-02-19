# frozen_string_literal: true
# @Note Every incoming node value should be a string; only convert from string at the very end of an operation
#   Exceptions: When defaulting the limit on an IO operation (parser, likely)

require_relative 'cpu_display'

class CPU 
  include CPUDisplay

  # Present in CPUDisplay; Copied here for clarity
  # REGISTERS = {
  #   a_register: 0,
  #   b_register: 1,
  #   c_register: 2,
  #   h_register: 3,
  #   l_register: 4,
  #   i_register: 5,
  #   j_register: 6,
  #   program_counter: 7,
  #   stack_pointer: 8,
  #   flag_register: 9,
  # }

  attr_accessor :ram, :symbol_table, :rom

  def initialize(rom, symbol_table)
    self.rom = rom
    rom << Parser::ExitNode.new unless rom.last.is_a? Parser::ExitNode # Allows HALT to be optional

    self.symbol_table = symbol_table
    self.ram = Array.new(256, 0) # Registers are implicitly set to zero
    self.stack_pointer = 255
  end

  # Define getters and setters for each register
  REGISTERS.each do |name, index|
    define_method(name) { ram[index] }
    define_method("#{name}=") { |value| ram[index] = value }
  end

  def this_instruction
    rom[program_counter]
  end

  def execute
    until this_instruction.is_a? Parser::ExitNode do 

      if this_instruction.is_a? Parser::BinaryOperationNode
        perform_binary_operation
      elsif this_instruction.is_a? Parser::UnaryOperationNode
        destination = get_address(this_instruction.destination) || REGISTERS[:a_register]
        ram[destination] = (ram[destination] ^ 0xff) & 0xff
      elsif this_instruction.is_a? Parser::MemoryNode
        perform_memory_operation
      elsif this_instruction.is_a? Parser::IONode
        perform_io_instruction
      elsif this_instruction.is_a? Parser::CompareNode
        source1 = get_value(this_instruction.source1)
        source2 = get_value(this_instruction.source2)
        result = source1 - source2

        set_flags(result)

        self.flag_register += 16 if source1 == source2
        self.flag_register += 32 if source1 > source2
      elsif this_instruction.is_a? Parser::JumpNode
        perform_jump_instruction
      elsif this_instruction.is_a? Parser::StackNode
        case this_instruction.action
        when 'push'
          ram[stack_pointer] = get_value(this_instruction.target)
          self.stack_pointer -= 1
        when 'pop'
          self.stack_pointer += 1
          ram[get_address(this_instruction.target)] = ram[stack_pointer]
        when 'dump'
          REGISTERS.each do |name, address|
            break if %i[program_counter stack_pointer flag_register].include? name
            ram[stack_pointer] = lookup("$#{address}")
            self.stack_pointer -= 1
          end
        when 'rstr'
          register = 6

          7.times do 
            self.stack_pointer += 1
            ram[register] = ram[stack_pointer]
            register -= 1
          end
        end
      elsif this_instruction.is_a? Parser::RoutineNode
        if this_instruction.call.nil?
          self.stack_pointer += 1
          goto = ram[stack_pointer]
          self.program_counter = goto - 1
        else
          goto = this_instruction.call
          ram[stack_pointer] = this_instruction.return
          self.stack_pointer -= 1
          self.program_counter = goto - 1
        end
      else
        raise "Not implemented: #{this_instruction.class}"
      end

      next_instruction
    end
  end

  def perform_binary_operation
    source_value = get_value(this_instruction.source)

    operation = this_instruction.operation

    destination_value = get_value(this_instruction.destination, a_register)
    destination_address = get_address(this_instruction.destination) || get_address(REGISTERS[:a_register])

    raise "Cannot write to Addresses $7-$9" if destination_address.between?(7, 9)

    result =  if %i[<< >>].include? operation
                destination_value.send(operation, source_value)
              else
                source_value.send(operation, destination_value)
              end

    set_flags(result)

    ram[destination_address] = result % 256
  ensure
    # puts "SV: #{source_value}, OP: #{operation}, DV: #{destination_value}, DA: #{destination_address}"
  end

  def perform_memory_operation
    source_value = get_value(this_instruction.source)
    source_address = get_address(this_instruction.source)
    operation = this_instruction.operation
    destination_address = get_address(this_instruction.destination) || REGISTERS[:a_register]

    raise "Cannot write to Addresses $7-$9" if destination_address.between?(7, 9)

    case operation
    when 'move', 'load'
      ram[destination_address] = source_value
    when 'save'
      ram[source_address] = ram[destination_address]
    when 'swap'
      ram[source_address], ram[destination_address] = ram[destination_address], ram[source_address]
    end    
  end

  def perform_io_instruction

    operation = this_instruction.operation
    destination_address = get_address(this_instruction.destination)
    modifier = get_value(this_instruction.modifier)

    if operation == 'text'
      raise "Invalid String Address: $#{destination_address} \n#{this_instruction}" if destination_address < 10
      chars = modifier.bytes
      chars.each_with_index do |byte, offset|
        ram[destination_address + offset] = byte
      end
    elsif operation == 'out'
      limit = 0
      offset = 0

      loop do
        break if ram[destination_address + offset].zero? || limit == modifier.to_i

        char = ram[destination_address + offset].chr
        print char
        limit += 1
        offset += 1
      end
      puts 
    elsif operation == 'in'
      ARGV.clear
      print ">> "
      chars = gets.chomp.bytes[0..limit]
      chars.each_with_index do |byte, offset|
        ram[destination_address + offset] = byte
      end
    end
  end

  def perform_jump_instruction
    comparison = this_instruction.check
    source = get_value(this_instruction.source)
    target = get_value(this_instruction.target)

    if this_instruction.source == :flag_register
      instruction_offset = this_instruction.destination.to_i - 1

      case comparison
      when :==
        self.program_counter += instruction_offset if flag_register.odd?
      when :>
        self.program_counter += instruction_offset if (flag_register & 0b00000011) == 0
      when :<
        self.program_counter += instruction_offset if (flag_register & 0b00000010) == 2
      else
        raise "Invalid Flag state detected. #{flag_register.to_s(8)}"
      end
    else
      destination_address = find_subroutine(this_instruction.destination) - 1 # PC is incremented before execution
      self.program_counter = destination_address if source.send comparison, target
    end
  end

  def find_subroutine(entry)
    subroutine_name = entry.sub(':', '')

    raise "Entry not found: #{entry}" if symbol_table[subroutine_name].nil?

    symbol_table[subroutine_name]
  end

  def find_variable(entry)
    raise "Entry not found: #{entry}" if symbol_table[entry].nil?
    get_value(symbol_table[entry])
  end

  # Receives some kind of object and attempts to return its RAM value or literal value
  def get_value(item, default = nil)
    if item.is_a? Integer
      item = item.clamp(-128, 127) if item.negative?
      return item
    end

    return default if item == :default
    return lookup(item.to_sym) if item.is_a?(Symbol) || item.include?('register')

    if item.start_with?('+', '-') || item.to_i.to_s == item
      item.to_i.negative? ? item.to_i.clamp(-128, 127) : item.to_i
    elsif item.start_with?('@', '$')
      lookup(item)
    elsif this_instruction.operation == 'text'
      item
    else
      raise "Cannot get value from #{item} <class: #{item.class}>"
    end
  end

  # Receives an address or reference pointer and returns the corresponding RAM value
  def lookup(item)
    return ram[get_address(REGISTERS.fetch(item.to_sym))] if item =~ /register/
    if item =~ /[@$][_a-z]/i
      return ram[ram[get_address(symbol_table[item.sub('$', '')])]] if item.include? '@'
      puts "HERE"
      return ram[get_address(symbol_table[item.sub('$', '')])] if item.include? '$'
    end

    number = extract_number(item)

    raise "Address out of bounds #{item} -> #{this_instruction}" if number >= ram.length

    item.include?('$') ? ram[number] : ram[ram[number]]
  end

  # Receives a register name or address string; returns the corresponding ram index
  def get_address(value)
    return nil if value == :default
    return value if value.is_a? Integer
    return extract_number(REGISTERS[value.to_sym]) if value =~ /register/

    value = symbol_table[value.sub(/[@$]/, '')] if value =~ /[@$][_a-z]/i

    value.include?('@') ? ram[extract_number(value)].to_i : extract_number(value)
  end

  # Sets status flags based on the result value of a given operation
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

  # Removes the address tags from an address or reference string and returns its integer value
  def extract_number(item)
    return item if item.is_a? Integer
    item.sub(/[@$]/, '').to_i 
  end

  def next_instruction
    self.program_counter += 1 
  end
end
