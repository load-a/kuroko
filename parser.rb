# frozen_string_literal: true

class Parser

  UnaryOperationNode = Struct.new(:operation, :destination)
  BinaryOperationNode = Struct.new(:operation, :source, :destination)
  MemoryNode = Struct.new(:operation, :source, :destination)
  JumpNode = Struct.new(:check, :source, :target, :destination)
  LabelNode = Struct.new(:name, :position)
  RoutineNode = Struct.new(:call, :return)
  StackNode = Struct.new(:action, :target)
  IONode = Struct.new(:operation, :operand, :operator)
  ExitNode = Struct.new

  attr_accessor :tokens, :symbol_table, :pointer, :index, :nodes
  def initialize(tokens)
    self.tokens = tokens
    tokens.reject! { |token| %i[comment ignore].include? token.type }

    self.pointer, self.index = 0, 0
    self.nodes = []
  end

  def current_token
    tokens[pointer]
  end

  def parse
    until current_token.type == :end_of_file do
      send("parse_#{current_token.type}")
    end
  end

  def end_of_stream?
    current_token.type == :end_of_file
  end

  def parse_arithmetic_command
    operation = current_token.value.downcase
    consume(:arithmetic_command)

    if %w[inc dec].include? operation
      destination = parse_destination

      source = parse_source(true)
      source = 1 if source == :default

      symbol = operation == 'inc' ? :+ : :-

      return nodes << BinaryOperationNode.new(symbol, source.to_s, destination)
    end

    source = parse_source
    destination = parse_destination(true)

    symbol =  case operation
              when 'add'
                :+
              when 'sub'
                :-
              when 'mult', 'mul'
                :*
              when 'div'
                :/
              when 'rem', 'mod'
                :%
              end

    nodes << BinaryOperationNode.new(symbol, source, destination)
  end

  def parse_logic_command
    operation = current_token.value.downcase
    consume(:logic_command)

    if operation == 'not'
      return nodes << UnaryOperationNode.new('!'.to_sym, parse_destination(true))
    end

    source = parse_source
    destination = parse_destination(true)

    operation =  case operation
              when 'and'
                :&
              when 'or'
                :|
              when 'xor'
                '^'.to_sym
              when 'left'
                :<<
              when 'rght'
                :>>
              end

    nodes << BinaryOperationNode.new(operation, source, destination)
  end

  def parse_control_flow_command
    operation = current_token.value.downcase
    consume(:control_flow_command)

    if operation == 'comp'
      op1 = parse_operand
      op2 = parse_operand(true)
      symbol = :-
      nodes << BinaryOperationNode.new(symbol, op1, op2)
    else
      expect(%i[subroutine_call label address])
      destination = parse_operand.to_s.downcase

      check =   case operation
                when 'zero', 'jeq', 'jump'
                  :==
                when 'pos', 'jgt'
                  :>
                when 'neg', 'jlt'
                  :<
                when 'jge'
                  :>=
                when 'jle'
                  :<=
                end

      if %w[zero pos neg].include? operation
        source = :flag_register
        target = 0
      elsif operation == 'jump'
        source = :a_register
        target = :a_register
      else
        source = parse_operand 
        target = :a_register
      end

      nodes << JumpNode.new(check, source, target, destination)
    end
  end

  def parse_routines_command
    operation = current_token.value.downcase
    consume(:routines_command)

    call = operation == 'rtrn' ? :return_call : parse_operand.gsub(':', '')

    nodes << RoutineNode.new(call.downcase) 
  end

  def parse_subroutine_label
    subroutine = current_token.value.downcase
    consume(:subroutine_label)
    nodes << LabelNode.new(subroutine.downcase.sub(':', ''))
  end

  def parse_stack_command
    operation = current_token.value.downcase
    consume(:stack_command)

    target =  case operation
              when 'push'
                parse_operand(true)
              when 'pop'
                parse_operand
              when 'dump', 'rstr'
                :all
              end

    nodes << StackNode.new(operation, target)
  end

  def parse_memory_command
    operation = current_token.value.downcase
    consume(:memory_command)

    case operation
    when 'move', 'swap'
      source = parse_source
      destination = parse_destination(true)
    when 'load', 'save'
      expect(:register)
      destination = parse_destination
      expect(:address, :reference, :label)
      source = parse_source
    end

    nodes << MemoryNode.new(operation, source, destination)
  end

  def parse_io_command
    operation = current_token.value.downcase
    consume(:io_command)

    if operation == 'text'
      text = parse_operand
      address = parse_operand
      return nodes << IONode.new(operation, text, address)
    end

    address = parse_operand
    limit = parse_operand(true)
    limit = 0 if limit == :default_operand

    nodes << IONode.new(operation, address, limit)
  end

  def parse_other_command
    operation = current_token.value.downcase
    consume(:other_command)

    case operation
    when 'name', 'var'
      expect(:address)
      address = parse_operand

      expect(:label)
      name = parse_operand

      nodes << LabelNode.new(name.downcase, address)
    when 'halt'
      nodes << ExitNode.new()
    else
      raise "Command Not implemented #{operation}"
    end
  end

  def parse_label
    raise "Label in place of Instruction: #{current_token}"
  end

  # @note The token stream is continued only if a valid operand is found
  def parse_operand(default = false)
    if current_token.nil?
      return :default_operand if default
      raise "Unexpected end of stream" 
    end

    operand = case current_token.type
              when :register, :index_operation
                "#{current_token.value.downcase}_register"
              when :signed_integer
                sign = current_token.value[0]
                number = convert_numeric(current_token.value)
                "#{sign}#{number}"
              when :unsigned_integer
                convert_numeric(current_token.value)
              when :subroutine_call
                current_token.value.gsub(':', '')
              when :identifier, :string, :label, :address, :reference
                current_token.value
              else
                return :default_operand if default
                raise("invalid token found #{current_token}")
              end
    continue_stream
    operand
  end

  def parse_source(default = false)
    if default
      return :default if end_of_stream? || command? || current_token.type == :subroutine_label
    else
      expect(:unsigned_integer, :signed_integer, :label, :address, :reference, :register)
    end


    source =  case current_token.type
              when :register
                "#{current_token.value.downcase}_register" 
              when :value
                current_token.value
              else
                convert_numeric(current_token.value)
              end

    consume(:unsigned_integer, :signed_integer, :label, :address, :reference, :register)
    source
  end

  def parse_destination(default = false)
    if default
      return :default if end_of_stream? || command? || current_token.type == :subroutine_label
    else
      expect(:label, :address, :reference, :register)
    end

    destination = if current_token.type == :register
                    "#{current_token.value.downcase}_register" 
                  elsif current_token.type == :label
                    current_token.value
                  else
                    convert_numeric(current_token.value)
                  end

    consume(:label, :address, :reference, :register)
    destination
  end

  def convert_numeric(number)
    return number if number.is_a? Integer

    if number =~ /[$@]/
      sign = number[0]
      number = number[1..]
    elsif number =~ /[+\-]/
      sign = number[0]
    end

    if number =~ /[+\-]?0b/i
      "#{sign == '-' ? '' : sign}#{number.to_i(2)}"
    elsif number =~ /[+\-]?0x/i
      "#{sign == '-' ? '' : sign}#{number.to_i(16)}"
    else
      "#{sign == '-' ? '' : sign}#{number.to_i}"
    end
  end

  def consume(*types)
    expect(types)
    continue_stream
  end

  def expect(*types)
    types = types[0] if types[0].is_a? Array
    unless types.include?(current_token.type)
      raise "Incorrect token. Expected: #{types.join(', ')}; received #{current_token}"
    end
  end

  def command?
    %i[
      arithmetic_command
      logic_command
      control_flow_command
      routines_command
      stack_command
      memory_command
      io_command
      other_command
    ].include? current_token.type
  end

  def continue_stream
    self.pointer += 1
  end
end
