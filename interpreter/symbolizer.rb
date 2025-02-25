# frozen_string_literal: true

# Creates and manages entries into the Symbol Table. (Modifies its instructions directly)
class Symbolizer

  attr_accessor :symbol_table, :instructions, :writes

  def initialize(instructions)
    self.instructions =  instructions
    self.symbol_table = REGISTERS.dup
    self.writes = {}
  end

  def process
    resolve_lists
    make_entries
    resolve_calls
  end

  def make_entries
    offset = 0
    remove = []

    instructions.each_with_index do |instruction, place|
      if instruction.verb == 'func'
        symbol_table[instruction.direct_object.value] = place - offset
        offset += 1
        remove << instruction
      elsif instruction.verb == 'name'
        offset += 1

        name = instruction.indirect_object.value
        address = "$#{instruction.direct_object.value}"

        raise "Name Taken: \n#{name.upcase} => #{symbol_table[name]}" if symbol_table[name]
        raise "Cannot alias: #{symbol_table.key(address)}. \n#{instruction}" if instruction.direct_object.value < 10
        raise "Address #{address} can only have one label. \n#{instruction}" if symbol_table.key(address)

        # The Direct Address sign can be inserted here because the declaration must made with a direct address
        symbol_table[name] = address
        
        remove << instruction
      end
    end

    instructions.reject! { |instruction| remove.include? instruction }
  end

  def resolve_calls
    instructions.each_with_index do |instruction, place|
      next unless %w[jump jgt jge jeq jle jlt call].include? instruction.verb
      
      instruction.direct_object.value = symbol_table[instruction.direct_object.value]

      if instruction.verb == 'call'
        instruction.indirect_object = Tokenizer::Token.new(:number, :natural, place)
      end
    end
  end

  def resolve_lists
    instructions.each do |instruction|
      next unless instruction.verb == :list

      index = instruction.direct_object.value

      instruction.indirect_object.value.each do |element|
        if element.type == :element
          name, value = element.value.split('=').map(&:strip)

          symbol_table[name.downcase] = "$#{index}"

          if value.include? '"'
            value[1..-2].each_byte do |byte| 
              writes["$#{index}"] = byte
              index += 1 
            end
          else
            writes["$#{index}"] = convert_to_integer(value)
            index += 1
          end
        else
          if element.value.include? '"'
            element.value[1..-2].each_byte do |byte| 
              writes["$#{index}"] = byte
              index += 1 
            end
          else
            writes["$#{index}"] = convert_to_integer(element.value)
            index += 1
          end
        end
      end
    end

    instructions.reject! {|item| item.verb == :list}
  end

  def convert_to_integer(numeric)
    return numeric if numeric.is_a? Integer

    if  numeric =~ /[+\-]?0b/i
      numeric.to_i(2)
    elsif  numeric =~ /[+\-]?0x/i
      numeric.to_i(16)
    elsif numeric =~ /[+\-]?0o/i
      numeric.to_i(8)
    else
      numeric.to_i
    end
  end
end
