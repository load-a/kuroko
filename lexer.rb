# frozen_string_literal: true

class Tokenizer
  LABEL_PATTERN = /[_a-z][_a-z0-9\-]+/i
  NUMBER_PATTERN = /0b[01]+|0x[0-9a-f]+|[0-9]+/i
  ADDRESS_SYMBOL = /[@$]/

  TOKEN_PATTERNS = {
    comment: /;.*/,
    subroutine_label: /^#{LABEL_PATTERN}:$/,
    subroutine_call: /:#{LABEL_PATTERN}/,
    arithmetic_command: /\b(ADD|SUB|MUL|MULT|DIV|REM|INC|DEC)\b/i,
    logic_command: /\b(AND|OR|NOT|XOR|LEFT|RGHT)\b/i,
    control_flow_command: /\b(COMP|ZERO|POS|NEG|JUMP|JEQ|JLT|JGT|JGE|JLE)\b/i,
    routines_command: /\b(CALL|RTRN)\b/i,
    stack_command: /\b(PUSH|POP|DUMP|RSTR)\b/i,
    memory_command: /\b(MOVE|COPY|LOAD|SAVE|SWAP)\b/i,
    io_command: /\b(TEXT|OUT|IN|INT)\b/i,
    other_command: /\b(NAME|VAR|HALT)\b/i,
    address: /\$(#{NUMBER_PATTERN}|#{LABEL_PATTERN})/,
    reference: /@(#{NUMBER_PATTERN}|#{LABEL_PATTERN})/,
    label: LABEL_PATTERN,
    index_operation: /[ij][+\-]|[+\-][ij]/i,
    register: /[abcdhlij]/i,
    string: /"(?:[^"\\]|\\.)*"/,
    unsigned_integer: /#{NUMBER_PATTERN}/,
    signed_integer: /[+\-]#{NUMBER_PATTERN}/,
    ignore: /,/,
    whitespace: /\s+/
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

    tokens.reject! { |token| token.type == :whitespace }
    tokens << Token.new(:end_of_file, '')
  end

  def display
    count = tokens.map {|token| token.value.length }.max
    puts tokens.map {|token| "#{token.value.ljust(count + 1)} #{token.type}"}
  end
end
