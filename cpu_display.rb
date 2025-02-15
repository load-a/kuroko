# frozen_string_literal: true

require 'rainbow'

module CPUDisplay
  REGISTERS = {
    a_register: 0,
    b_register: 1,
    c_register: 2,
    h_register: 3,
    l_register: 4,
    i_register: 5,
    j_register: 6,
    program_counter: 7,
    stack_pointer: 8,
    flag_register: 9,
  }
  
  def view_registers
    puts '* REGISTERS *'
    REGISTERS.each do |name, address|
      line =  if name == :flag_register 
                '%-15s: %08b' % [name.to_s, ram[address]]
              else 
                "#{name.to_s.ljust(15)}: #{ram[address]}"
              end
      puts line
    end
  end

  def view_status
    status = %w|
      [Z]ero
      [N]egative
      [C]arry
      [O]verflow
      co[M]parison
      co[N]dition
      [P]arity
      reserved
    |
    flags = ('%08b' % flag_register).reverse

    puts '* STATUS FLAGS *'
    status.each_with_index do |stat, index|
      puts '%-12s: %s' % [stat, flags[index]]
    end
  end

  def view_stack
    puts "* STACK *"
    ram[-16..].reverse.each_with_index do |element, index|
      puts '%02i. %i' % [index, element]
    end
  end

  def view_ram(address_base = :decimal, value_base = :decimal)
    formats = {
      binary: '%08b',
      decimal: '%03i',
      hex: '%02x'
    }

    def ascii_row(data)
      print '|  '
      data.each do |datum|
        character = if datum.between?(32, 126)
                      datum.chr
                    else
                      '.'
                    end
        print character
        print ' '
      end
    end

    address_format = formats.fetch(address_base, '%03i')
    value_format = formats.fetch(value_base, '%03i')
    
    puts "* RAM *"

    ram.each_with_index do |value, index|
      if index % 8 == 0
        puts unless index.zero?
        printf Rainbow(address_format % index).italic
        print '. '
      end

      case index
      when ...7
        print Rainbow(value_format % value).blue
      when 7...9
        print Rainbow(value_format % value).red
      when 9
        print Rainbow(value_format % value).magenta
      when 10...240
        # string =
        print value.zero? ? Rainbow(value_format % value).faint : Rainbow(value_format % value)
      when 240...256
        stack_element = Rainbow(value_format % value).yellow
        stack_element = stack_element.underline if index == stack_pointer
        print stack_element
      end
      print ' '
      ascii_row(ram[index - 7..index]) if index % 8 == 7
    end

    puts
  end

  def display(address_base = :decimal, value_base = :decimal)
    view_registers
    view_status
    view_stack
    view_ram(address_base, value_base)
  end
end
