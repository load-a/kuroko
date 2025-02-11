# frozen_string_literal: true

class Tokenizer
  LABEL_PATTERN = /[_a-z][_a-z0-9\-]+/i
  NUMBER_PATTERN = /0b[01]+|0x[0-9a-f]+|[0-9]+/i
  ADDRESS_SYMBOL = /[@$]/

  TOKEN_PATTERNS = {
    comment: /;.*/,
    arithmetic_command: /(ADD|SUB|MUL|DIV|REM|INC|DEC)/i,
    logic_command: /(AND|OR|NOT|XOR|LEFT|RGHT)/i,
    control_flow_command: /(COMP|ZERO|POS|NEG|JUMP|JEQ|JLT|JGT|JGE|JLE)/i,
    routines_command: /(CALL|RTRN)/i,
    stack_command: /(PUSH|POP)/i,
    memory_command: /(MOVE|LOAD|SAVE|SWAP)/i,
    io_command: /(TEXT|OUT|IN|INT)/i,
    other_command: /(NAME)/i,
    subroutine_label: /#{LABEL_PATTERN}:/,
    subroutine_call: /:#{LABEL_PATTERN}/,
    identifier: /#{ADDRESS_SYMBOL}#{LABEL_PATTERN}/,
    address: /#{ADDRESS_SYMBOL}#{NUMBER_PATTERN}/,
    label: LABEL_PATTERN,
    index_operation: /[ij][+\-]|[+\-][ij]/i,
    register: /[abcdhlij]/i,
    string: /"(?:[^"\\]|\\.)*"/,
    unsigned_integer: /#{NUMBER_PATTERN}/,
    signed_integer: /[+\-]#{NUMBER_PATTERN}/,
    ignore: /,|\s+/,
  }

  attr_accessor :source, :tokens

  Token = Struct.new(:type, :value)

  def initialize(source)
    self.source = File.read source
    self.tokens = []
  end

  def tokenize
    until source.empty?
      matched = false

      TOKEN_PATTERNS.each do |type, pattern|
        if source =~ /\A(#{pattern})/
          tokens << Token.new(type, $1)
          self.source = $'
          matched = true
          break
        end
      end

      raise "Unmatched token: '#{source[0]}' \n#{source[...16]}" unless matched
    end

    tokens.reject! { |token| %i[comment ignore].include? token.type }
  end

  def display
    count = tokens.map {|token| token.value.length }.max
    puts tokens.map {|token| "#{token.value.ljust(count + 1)} #{token.type}"}
  end
end
