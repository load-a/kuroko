# frozen_string_literal: true

# Breaks source code into lexical units for the tokenizer
class Lexer
  LIST_ASSIGNMENT_PATTERN = /#{LABEL_PATTERN}\s?=\s?/

  COARSE_PATTERNS = {
    comment: /;.*/,
    header: /# ?(DATA|LOGIC|ROUTINES|SUBROUTINES)/i,
    bracket: /\[|\]/,
    element: /#{LIST_ASSIGNMENT_PATTERN}(#{NUMBER_PATTERN}|#{STRING_PATTERN})/,
    number: NUMBER_PATTERN,
    label: /#{LABEL_PATTERN}:|:#{LABEL_PATTERN}|#{LABEL_PATTERN}/,
    location: /[@$](#{LABEL_PATTERN}|#{NUMBER_PATTERN})|[@$]?#{REGISTER_PATTERN}/,
    string: STRING_PATTERN,
    whitespace: /\s+|,/
  }

  Unit = Struct.new(:type, :value)

  attr_accessor :source, :units

  def initialize(source)
    self.source = source
    self.units = []
  end

  def process
    until source.empty?
        matched = false

        COARSE_PATTERNS.each do |type, pattern|
          if source =~ /\A(#{pattern})/
            units << Unit.new(type, $1)
            self.source = $'
            matched = true
            break
          end
        end

        raise "Unmatched unit: '#{source[0]}' \n#{source[...16]}" unless matched
      end

      units.reject! { |unit| unit.type == :whitespace }
      units << Unit.new(:end_of_file, '')
  end

  def show_units
    units.each_with_index do |unit, index|
      printf '%04i. %s', index,  inspect_unit(unit, 11)
      puts 
    end
  end

  def inspect_unit(unit, justification = 0)
    '%s: %s' % [unit.type.to_s.ljust(justification), unit.value]
  end
end
