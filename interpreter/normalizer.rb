# frozen_string_literal: true

# Converts token values into a standard format
class Normalizer
  attr_accessor :tokens, :log

  def initialize(tokens)
    self.tokens = tokens
    self.log = []
  end

  def normalize
    tokens.each_with_index do |token, index|
      case token.type
      when :number
        new_value = convert_to_integer(token.value)
        if token.subtype == :integer
          new_value &= 0xFF
        else
          new_value %= 256
        end

        token.value = new_value
        log << normalized_report('Number', index, token)
      when :address
        token.value = convert_to_integer(token.value.sub(/[@$]/, ''))
        log << normalized_report('Address', index, token)
      when :subroutine
        token.value = token.value.sub(':', '').downcase
        log << normalized_report('Subroutine', index, token)
      when :register
        token.value = "#{token.value.downcase}_register".to_sym
        log << normalized_report('Register', index, token)
      when :command, :label, :variable
        type = token.type
        token.value = token.value.downcase.sub(/[@$]/, '')
        log << normalized_report(type.to_s.capitalize, index, token)
      end
    end

    unless tokens.last.type == :end_of_file
      token = Tokenizer::Token.new(:end_of_file, :final, '')
      tokens << token
      log << normalized_report('Implicit End of File', tokens.length, token)
    end
  end

  def convert_to_integer(numeric)
    return numeric if numeric.is_a? Integer

    if  numeric =~ /[+\-]?0b/i
      numeric.to_i(2)
    elsif  numeric =~ /[+\-]?0x/i
      numeric.to_i(16)
    else
      numeric.to_i
    end
  end

  def normalized_report(attribute, index, token)
    '%04i: %s -> %s' % [index, attribute.ljust(12), token.to_s.sub('#<struct Tokenizer::Token ', '<')]
  end
end
