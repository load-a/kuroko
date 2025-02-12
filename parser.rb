# frozen_string_literal: true

class Parser

  UnaryOperationNode = Struct.new(:operation, :operand)
  BinaryOperationNode = Struct.new(:operation, :operand, :operator)
  MemoryNode = Struct.new(:operation, :source, :target)
  JumpNode = Struct.new(:check, :source, :target, :destination)
  LabelNode = Struct.new(:name, :position)
  RoutineNode = Struct.new(:call, :return)
  StackNode = Struct.new(:action, :target)
  IONode = Struct.new(:operation, :operand, :operator)

  attr_accessor :tokens, :symbol_table, :pointer, :index, :nodes
  def initialize(tokens)
    self.tokens = tokens
    self.pointer, self.index = 0, 0
    self.nodes = []
  end

  def current_token
    tokens[pointer]
  end

  def parse
    until end_of_stream? do
      send("parse_#{current_token.type}")
    end
  end

  def end_of_stream?
    pointer >= tokens.length
  end

  def parse_arithmetic_command
    operation = current_token.value.downcase
    consume(:arithmetic_command)

    op1 = parse_operand
    op2 = parse_operand(true)

    if %w[inc dec].include?(operation) && op2 == :default_operand
      op2 = 1
    end

    symbol =  case operation
              when 'add', 'inc'
                :+
              when 'sub', 'dec'
                :-
              when 'mult', 'mul'
                :*
              when 'div'
                :/
              when 'rem'
                :%
              end

    nodes << BinaryOperationNode.new(symbol, op1, op2)
  end

  def parse_logic_command
    operation = current_token.value.downcase
    consume(:logic_command)

    op1 = parse_operand

    if operation == 'not'
      return nodes << UnaryOperationNode.new('!'.to_sym, op1)
    end

    op2 = parse_operand(true)

    symbol =  case operation
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

    nodes << BinaryOperationNode.new(symbol, op1, op2)
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
      enforce(%i[subroutine_call label address])
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

    source = parse_operand

    target =  if %w[move copy save].include? operation
                parse_operand
              else # 'load' or 'swap'
                parse_operand(true)
              end

    nodes << MemoryNode.new(operation, source, target)
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
      enforce(:address)
      address = parse_operand

      enforce(:label)
      name = parse_operand

      nodes << LabelNode.new(name.downcase, address)
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
              when :unsigned_integer, :signed_integer
                if current_token.value =~ /[+\-]?0b/i
                  current_token.value.to_i(2)
                elsif current_token.value =~ /[+\-]?0x/i
                  current_token.value.to_i(16)
                else
                  current_token.value.to_i
                end
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

  def consume(*types)
    enforce(types)
    continue_stream
  end

  def enforce(*types)
    types = types[0] if types[0].is_a? Array
    unless types.include?(current_token.type)
      raise "Incorrect token. Expected: #{types.join(', ')}; received #{current_token}"
    end
  end

  def continue_stream
    self.pointer += 1
  end
end
