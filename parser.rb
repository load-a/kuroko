# frozen_string_literal: true

class Parser

  InstructionNode = Struct.new(:operation, :op1, :op2)

  attr_accessor :tokens, :symbol_table, :pointer, :index, :nodes
  def initialize(tokens)
    self.tokens = tokens
    self.symbol_table = {

    }
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

    symbol =  case operation
              when 'add', 'inc'
                :+
              when 'sub', 'dec'
                :-
              when 'mult'
                :*
              when 'div'
                :/
              when 'rem'
                :%
              end

    nodes << InstructionNode.new(sym, op1, op2)
  end

  def operand_types
    %i[
      register index_operation
      unsigned_integer signed_integer
      subroutine_call
      identifier address string label
    ]
  end

  def parse_operand(default = false)
    return :a_register if current_token.nil?

    operand = case current_token.type
              when :register, :index_operation
                "#{current_token.value.downcase}_register"
              when :unsigned_integer, :signed_integer
                case current_token.value[..2] 
                when /[+\-]?0b/i
                  current_token.value.to_i(2)
                when /[+\-]?0x/i
                  current_token.value.to_i(16)
                else
                  current_token.value.to_i
                end
              when :subroutine_call
                current_token.value.gsub(':', '')
              when :identifier, :address, :string, :label
                current_token.value
              else
                default ? :a_register : raise("invalid token found #{current_token}")
              end
    continue_stream
    operand
  end

  def consume(*types)
    raise "Incorrect token. Expected #{types}, received #{token}" unless types.include? current_token.type
    continue_stream
  end

  def continue_stream
    self.pointer += 1
  end
end
