# frozen_string_literal: true

class CPU 

  REGISTERS = {
    a_register: 0,
    b_register: 1,
    c_register: 2,
    h_register: 3,
    l_register: 4,
    i_register: 5,
    j_register: 6,
    program_counter: 7,
    stack_pointer: 8,
    flag_register: 9,
  }

  attr_accessor :ram, :symbol_table, :rom
  attr_accessor :a_register, :b_register, :c_register, :h_register, :l_register, :i_register, :j_register, 
              :program_counter, :stack_pointer, :flag_register

  def initialize(rom, symbol_table)
    self.rom = rom
    rom << Parser::ExitNode.new unless rom.last.is_a? Parser::ExitNode
    self.symbol_table = symbol_table
    self.ram = Array.new(256, 0)
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
        destination = address(this_instruction.destination) || REGISTERS[:a_register]
        ram[destination] = ram[destination] ^ 0xff
      elsif this_instruction.is_a? Parser::MemoryNode
        perform_memory_operation
      else
        puts "Not implemented: #{this_instruction.class}}"
      end

      next_instruction
    end

    puts ram[...10]
  end

  def perform_binary_operation
    operand = resolve_operand(this_instruction.source)
    operator = resolve_operand(this_instruction.destination, :a_register)
    operation = this_instruction.operation
    destination = address(this_instruction.destination) || REGISTERS[:a_register]

    raise "Cannot write to Addresses $7-$9" if destination.between?(7, 9)

    if %i[- / %].include? operation
      ram[destination] = operator.send(operation, operand)
    else
      ram[destination] = operand.send(operation, operator)
    end
  end

  def perform_memory_operation
    source_value = resolve_operand(this_instruction.source)
    source_address = address(this_instruction.source)
    operation = this_instruction.operation
    destination = address(this_instruction.destination) || REGISTERS[:a_register]

    raise "Cannot write to Addresses $7-$9" if destination.between?(7, 9)

    case operation
    when 'move', 'load'
      ram[destination] = source_value
    when 'save'
      ram[source_address] = ram[destination]
    when 'swap'
      ram[source_address], ram[destination] = ram[destination], ram[source_address]
    end    
  end

  def resolve_operand(item, default = nil)
    item = default if item == :default

    if item =~ /[+\-]/
      item.to_i.clamp(-128, 127)
    elsif item.to_s.include?('register')
      send(item)
    elsif item =~ /[@$]/
      lookup(item)
    elsif item.to_i.to_s == item
      item.to_i
    else
      item
    end
  end

  def lookup(item)
    number = get_number(item)

    raise "Address out of bounds #{item} -> #{this_instruction}" if number >= ram.length

    item.include?('$') ? ram[number] : ram[ram[number]]
  end

  def address(value)
    return nil if value == :default
    return get_number(REGISTERS[value.to_sym]) if value =~ /register/

    value.include?('@') ? ram[get_number(value)] : get_number(value)
  end

  def get_number(item)
    return item if item.is_a? Integer
    item.sub(/[@$]/, '').to_i 
  end

  def next_instruction
    self.program_counter += 1 
  end
end
