# frozen_string_literal: true

# Creates and manages entries into the Symbol Table. (Modifies its instructions directly)
class Symbolizer

  attr_accessor :symbol_table, :instructions, :ram_table

  def initialize(instructions)
    self.instructions =  instructions
    self.symbol_table = REGISTERS.dup
    self.ram_table = {}
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
      next unless instruction.verb == 'list'

      index = instruction.direct_object.value

      instruction.indirect_object.value.each do |element|
        if element.type == :element
          name, value = element.value.split('=').map(&:strip)

          symbol_table[name.downcase] = "$#{index}"

          index = write_to_ram(value, index)
        else
          index = write_to_ram(element.value, index)
        end
      end
    end

    instructions.reject! {|item| item.verb == :list}
  end

  def write_to_ram(value, index)
    if value.to_s.include? '"'
      value[1..-2].each_byte do |byte| 
        ram_table["$#{index}"] = byte
        index += 1 
      end
      ram_table["$#{index}"] = 0
      index += 1
    else
      ram_table["$#{index}"] = convert_to_integer(value)
      index += 1
    end

    index
  end
end
