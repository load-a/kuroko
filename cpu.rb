# frozen_string_literal: true

class CPU 

  class Register
    attr_accessor :address, :value
    def initialize(address)
      self.address = address
      self.value = 0
    end
  end

  attr_accessor :ram, :symbol_table, :rom
  attr_accessor :a_register, :b_register, :c_register, :h_register, :l_register, :i_register, :j_register, 
              :program_counter, :stack_pointer, :flag_register

  def initialize(rom, symbol_table)
    self.rom = rom
    self.symbol_table = symbol_table

    self.ram = Array.new(256, 0)
    self.a_register = Register.new(0)
    self.b_register = Register.new(1)
    self.c_register = Register.new(2)
    self.h_register = Register.new(3)
    self.l_register = Register.new(4)
    self.i_register = Register.new(5)
    self.j_register = Register.new(6)
    self.program_counter = Register.new(7)
    self.stack_pointer = Register.new(8)
    self.flag_register = Register.new(9) 
  end

  def this_instruction
    rom[program_counter.value]
  end

  def execute
    until this_instruction.is_a? Parser::ExitNode do 

      if this_instruction.is_a? Parser::BinaryOperationNode
        perform_binary_operation
      else
        puts "Not implemented: #{this_instruction.class}}"
      end

      next_instruction
    end

    puts ram[...10]
  end

  def perform_binary_operation
    source = resolve_operand(this_instruction.source)
    destination = resolve_operand(this_instruction.destination)
    operation = this_instruction.operation

    puts "#{source} #{operation} #{destination}"
  end

  def resolve_operand(item)
    if item =~ /[+\-]/
      item.to_i.clamp(-128, 127)
    elsif item.include? 'register'
      send(item).value
    elsif item =~ /[@$]/
      resolve_address(item)
    else
      item
    end
  end

  def resolve_address(item)
    number = item.sub(/[@$]/, '').to_i

    item.include?('$') ? ram[number] : ram[ram[number]]
  end

  def next_instruction
    program_counter.value += 1
  end

  def sync_registers
    
  end
end
