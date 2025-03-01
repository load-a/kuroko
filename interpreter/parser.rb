# frozen_string_literal: true

# Converts tokens into instruction nodes for the Symbolizer and CPU
class Parser

  BLANK_TOKEN = Tokenizer::Token.new('.'.to_sym, '.'.to_sym, '')

  class Instruction
    attr_accessor :verb, :direct_object, :indirect_object
    def initialize(verb, direct_object, indirect_object)
      self.verb = verb
      self.direct_object = direct_object
      self.indirect_object = indirect_object
    end

    def to_s(center_column = 0)
      '%s: %s : %s' % [verb.to_s.ljust(5), direct_object.to_s.ljust(center_column), indirect_object.to_s]
    end
  end

  attr_accessor :tokens, :instructions, :partitions, :mode

  def initialize(tokens)
    self.tokens = tokens
    self.partitions = []
    self.instructions = []
    self.mode = :logic
  end

  def partition_tokens
    group = []

    tokens.each do |token|
      case token.type
      when :command, :subroutine, :end_of_file, :header
        self.mode = :data if token.subtype == :data

        next group << token if token.subtype == :call

        partitions << group.dup unless group.empty?
        group.clear
        group << token
      else
        group << token
      end
    end

    partitions << group.dup
  end

  def parse
    partition_tokens
    parse_data_section if mode == :data
    parse_logic_section
  end

  def parse_data_section
    rejects = []
    expect_type(partitions[0][0], :header)
    expect_subtype(partitions[0][0], :data)
    partitions.delete_at(0)

    partitions.each do |group|
      break if group[0].type == :header

      expect_type(group[0], :list, :command, :end_of_file)

      verb = group[0].value

      case verb
      when 'text'
        parse_other(group)
      when 'list'
        parse_list(group)
      when 'name'
        parse_other(group)
      else 
        exit if group[0].type == :end_of_file
        raise "Cannot use in Data Section: #{group.map(&:to_s)}" 
      end

      rejects << group
    end

    partitions.reject! { |group| rejects.include? group }
  end

  def parse_list(group)
    expect_type(group[1], :address)
    expect_subtype(group[1], :direct)

    expect_type(group[2], :bracket)
    expect_subtype(group[2], :open)

    address = group[1]
    list = group[3...-1]

    expect_type(group.last, :bracket)
    expect_subtype(group.last, :close)

    instructions << Instruction.new('list', address, Tokenizer::Token.new(:list, :content, list))
  end

  def parse_logic_section
    if partitions[0][0].type == :header
      expect_type(partitions[0][0], :header)
      expect_subtype(partitions[0][0], :logic)
      partitions.delete_at(0)
    end
    parse_logical_groups
  end

  def parse_logical_groups
    partitions.each do |group|
      next if group[0].type == :header 
      next instructions << Instruction.new('func', group[0], BLANK_TOKEN) if group[0].type == :subroutine 
      next instructions << Instruction.new(:end, BLANK_TOKEN, BLANK_TOKEN) if group[0].type == :end_of_file 

      expect_type(group[0], :command, :end_of_file)
      send("parse_#{group[0].subtype}", group)
    end
  end

  def parse_arithmetic(group)
    default_destination = Tokenizer::Token.new(:register, :direct, :a_register)
    default_incrementor = Tokenizer::Token.new(:number, :natural, 1)

    check_component_range(group, (2..3))

    expect_type(group[1], :number, :variable, :register, :address)
    source = group[1]

    command = case group[0].value
              when 'add'
                :+
              when 'sub'
                :-
              when 'mul', 'mult'
                :*
              when 'div'
                :/
              when 'mod', 'rem'
                :%
              when 'inc'
                :inc
              when 'dec'
                :dec
              when 'rand'
                :rand
              end
    if command == :rand 
      expect_type(group[1], :variable, :register, :address)
      return instructions << Instruction.new(command, source, BLANK_TOKEN)
    end

    if group.length == 3
      if %w[inc dec].include?(group[0].value)
        expect_type(group[2], :variable, :register, :address, :number)
      else
        expect_type(group[2], :variable, :register, :address)
      end
      destination = group[2]
    else
      destination = %w[inc dec].include?(group[0].value) ? default_incrementor : default_destination
    end

    instructions << Instruction.new(command, source, destination)
  end

  def parse_logic(group)
    default_destination = Tokenizer::Token.new(:register, :direct, :a_register)
    default_shift = Tokenizer::Token.new(:number, :natural, 1)

    check_component_range(group, (2..3))

    expect_type(group[1], :number, :variable, :register, :address)
    source = group[1]

    command = case group[0].value
              when 'and'
                :&
              when 'or'
                :|
              when 'xor'
                '^'.to_sym
              when 'not'
                '!'.to_sym
              when 'left'
                :<<
              when 'rght'
                :>>
              end

    if %i[<< >>].include? command
      if group[2]
        expect_type(group[2], :number, :address, :register)
        step = group[2]
      else
        step = default_shift
      end

      return instructions << Instruction.new(command, source, step)
    end

    return instructions << Instruction.new(command, source, BLANK_TOKEN) if group[0].value == 'not'

    if group.length == 3
      expect_type(group[2], :register)
      destination = group[2]
    else
      destination = default_destination
    end

    instructions << Instruction.new(command, source, destination)
  end

  def parse_branch(group)
    command = group[0].value

    if command == 'comp'
      check_component_range(group, (3..3))
      expect_type(group[1], :register, :number, :address, :variable)
      expect_type(group[2], :register, :number, :address, :variable)

      return instructions << Instruction.new(command, group[1], group[2])
    end


    case command
    when 'pos', 'neg', 'zero'
      check_component_range(group, (2..2))

      expect_type(group[1], :number)
      offset = group[1]

      raise "Branch offset cannot be zero \n#{group.join("\n")}" if offset.value.to_i.zero?

      instructions << Instruction.new(command, offset, BLANK_TOKEN)
    when 'jump'
      check_component_range(group, (2..2))

      expect_type(group[1], :subroutine)
      expect_subtype(group[1], :call)
      subroutine = group[1]

      instructions << Instruction.new(command, subroutine, BLANK_TOKEN)
    when 'jlt', 'jle', 'jeq', 'jge', 'jgt'
      check_component_range(group, (3..3))

      expect_type(group[1], :subroutine)
      expect_subtype(group[1], :call)
      subroutine = group[1]

      expect_type(group[2], :number, :address, :variable, :register)
      comparison = group[2]

      instructions << Instruction.new(command, subroutine, comparison)
    end
  end

  def parse_stack(group)
    command = group[0].value

    case command
    when 'push', 'pop'
      check_component_range(group, 2..2)
      expect_type(group[1], :register)
      destination = group[1]
      instructions << Instruction.new(command, destination, BLANK_TOKEN)
    when 'dump', 'rstr'
      check_component_range(group, 1..1)

      instructions << Instruction.new(command, BLANK_TOKEN, BLANK_TOKEN)
    end
  end

  def parse_memory(group)
    command = group[0].value

    case command
    when 'move', 'swap'
      check_component_range(group, 3..3)
      expect_type(group[1], :register, :number, :address, :variable)
      expect_type(group[2], :register, :number, :address, :variable)

      source, destination = group[1..]
      instructions << Instruction.new(command, source, destination)
    when 'save', 'load'
      check_component_range(group, 3..3)

      expect_type(group[1], :register)
      register = group[1]

      expect_type(group[2], :address, :number, :variable, :register)
      data = group[2]

      instructions << Instruction.new(command, register, data)
    end
  end

  def parse_io(group)
    command = group[0].value

    case command
    when 'in', 'out', 'prnt', 'tlly'
      check_component_range(group, (2..3))
      expect_type(group[1], :address, :register, :variable, :string)
      location = group[1]

      if group.length == 2
        char_limit = location.type == :string ? -2 : -1
        limit = Tokenizer::Token.new(:number, :integer, char_limit)
      else
        expect_type(group[2], :number, :register, :variable, :address)
        group[2].value = group[2].value.clamp(-2, 256) if group[2].is_a? Integer
        limit = group[2]
      end

      instructions << Instruction.new(command, location, limit)
    when 'nin', 'nout', 'ncat'
      check_component_range(group, (2..2))
      expect_type(group[1], :variable, :register, :address)
      location = group[1]

      instructions << Instruction.new(command, location, BLANK_TOKEN)
    when 'nwln', 'post'
      check_component_range(group, 1..1)
      instructions << Instruction.new(command, BLANK_TOKEN, BLANK_TOKEN)
    end
  end

  def parse_subroutine(group)
    command = group[0].value
    
    case command
    when 'call'
      check_component_range(group, 2..2)
      expect_type(group[1], :subroutine)
      instructions << Instruction.new(command, group[1], BLANK_TOKEN)
    when 'rtrn'
      check_component_range(group, 1..1)
      instructions << Instruction.new(command, BLANK_TOKEN, BLANK_TOKEN)
    end
  end

  def parse_other(group)
    case group[0].value
    when 'text'
      expect_type(group[2], :string)
      text = group[2]

      expect_type(group[1], :address, :register, :variable)
      location = group[1]

      instructions << Instruction.new(group[0].value, location, text)
    when 'var', 'name'
      raise "Cannot use NAME or VAR in Logic Section" if mode == :logic

      check_component_range(group, 3..3)

      expect_type(group[1], :address)
      expect_subtype(group[1], :direct)
      address = group[1]

      expect_type(group[2], :label)
      expect_subtype(group[2], :unmarked)
      label = group[2]

      instructions << Instruction.new(group[0].value, address, label)
    when 'halt'
      check_component_range(group, 1..1)
      instructions << Instruction.new('halt', BLANK_TOKEN, BLANK_TOKEN)
    when 'pic'
      check_component_range(group, 2..2)
      expect_type(group[1], :number)
      expect_subtype(group[1], :natural)

      image = group[1]
      instructions << Instruction.new('pic', image, BLANK_TOKEN)
    when 'list'
      raise "Cannot use LIST in Logic Section" if mode == :logic

      check_component_range(group, 3..3)

      expect_type(group[1], :address)
      expect_subtype(group[1], :direct)
      address = group[1]

      expect_type(group[2], :data)
      expect_subtype(group[2], :list)
      label = group[2]

      instructions << Instruction.new(group[0].value, address, label)
    end
  end

  def check_component_range(group, range)
    return if range.include? group.length

    raise "Group does not have the correct number of components. Found #{group.length} instead of #{range}\n#{group}"
  end

  def expect_type(token, *types)
    unless types.include? token.type
      raise "Unexpected Token Type: \nExpected #{types}, found :#{token.type}\n #{token.to_s}" 
    end
  end

  def expect_subtype(token, *subtypes)
    unless subtypes.include? token.subtype
      raise "Unexpected Token Subtype: \nExpected #{subtypes}, found :#{token.subtype} \n#{token.to_s}"
    end
  end

  def show_instructions
    instructions.each_with_index do |instruction, index|
      instruction = instruction.map(&:to_s) if instruction.verb == :list

      puts '%04i. %s' % [index, instruction.to_s(45)]
    end
  end
end
