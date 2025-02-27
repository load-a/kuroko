# frozen_string_literal: true

# Converts Lexical Units into tokens for the Normalizer and Parser
class Tokenizer
  COMMANDS = {
    arithmetic: %w[add sub mul mult div rem mod inc dec rand],
    logic: %w[and or not xor left rght],
    branch: %w[comp zero pos neg jump jeq jlt jgt jge jle],
    subroutine: %w[call rtrn],
    stack: %w[push pop dump rstr],
    memory: %w[move copy load save swap],
    io: %w[in nin out nout nwln prnt tlly post],
    other: %w[text name var halt pic list]
  }

  class Token
    attr_accessor :type, :subtype, :value
    def initialize(type, subtype, value)
      self.type = type
      self.subtype = subtype
      self.value = value
    end

    def to_s
      '<%s.%s.%s>' % [type, subtype, value]
    end
  end

  attr_accessor :units, :tokens

  def initialize(units)
    self.units = units
    self.tokens = []
  end

  def tokenize
    units.each do |unit|
      next if unit.type == :comment

      if unit.type == :list
        unit.value.map! { |element| generate_token(element) }
      end

      tokens << generate_token(unit)
    end
  end

  def generate_token(unit)
    case unit.type
    when :string
      Token.new(:string, :literal, unit.value)
    when :number
      disambiguate_number(unit)
    when :label
      disambiguate_label(unit)
    when :location
      disambiguate_location(unit)
    when :header
      Token.new(:header, unit.value.downcase.sub('#', '').strip.to_sym, unit.value)
    when :list
      Token.new(:data, :list, unit.value)
    when :bracket
      unit.value == '[' ? Token.new(:bracket, :open, unit.value) : Token.new(:bracket, :close, unit.value)
    when :element
      Token.new(:element, :list, unit.value)
    when :end_of_file
      Token.new(:end_of_file, :final, '')
    end
  end

  def disambiguate_label(unit)
    if unit.value.include? ':'
      type = :subroutine
      subtype = unit.value.start_with?(':') ? :call : :label
    elsif COMMANDS.values.flatten.include? unit.value.downcase
      type = :command
      subtype = command_type(unit.value)
    else
      type = :label
      subtype = :unmarked
    end

    Token.new(type, subtype, unit.value)
  end

  def command_type(command)
    COMMANDS.each { |type, keywords| return type if keywords.include? command.downcase }
  end

  def disambiguate_number(unit)
    subtype = unit.value.start_with?('+', '-') ? :integer : :natural

    Token.new(:number, subtype, unit.value)
  end

  def disambiguate_location(unit)
    subtype = unit.value.start_with?('@') ? :indirect : :direct
    type = if unit.value =~ REGISTER_PATTERN
             unit.value = unit.value.sub(/[@$]/, '')
             :register
           elsif unit.value =~ NUMBER_PATTERN
             :address
           else
             :variable
           end

    Token.new(type, subtype, unit.value)
  end

  def show_tokens
    tokens.each_with_index do |token, index|
      puts '%04i. %s' % [index, inspect_token(token)]
    end
  end

  def inspect_token(token)
    '%s %s: %s' % [token.subtype.to_s.ljust(10), token.type.to_s.ljust(11), token.value]
  end
end
