# frozen_string_literal: true

# Creates and manages entries into the Symbol Table. (Modifies its instructions directly)
class Symbolizer

  attr_accessor :symbol_table, :instructions

  def initialize(instructions)
    self.instructions =  instructions
    self.symbol_table = REGISTERS.dup
  end

  def process
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
end
