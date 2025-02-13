# frozen_string_literal: true

class NodeProcessor
  attr_accessor :nodes, :symbol_table
  def initialize(nodes)
    self.nodes = nodes
    self.symbol_table = {
      a_register: '$0',
      b_register: '$1',
      c_register: '$2',
      h_register: '$3',
      l_register: '$4',
      i_register: '$5',
      j_register: '$6',
      program_counter: '$7',
      stack_pointer: '$8',
      flag_register: '$9'
    }
    # The first RAM address available to the user is $10
  end

  def process
    resolve_labels
    resolve_subroutines
  end

  # Adds each label to the symbol table and gives it a proper address; removes node thereafter
  def resolve_labels
    offset = 0

    nodes.each_with_index do |node, number|
      next unless node.is_a?(Parser::LabelNode)

      raise "Duplicate Label declared: #{node} position: #{number}" if symbol_table.has_key? node.name.gsub('&', '')
      if node.position.nil?
        node.position = number - offset 
      else
        position = node.position.sub('$', '')
        case node.position
        when /0b/
          position = position.to_i(2)
        when /0x/
          position = pos.to_i(16)
        end

        node.position = "$#{position}"
      end

      if symbol_table.has_value? node.position
        conflict = symbol_table.key(node.position)
        error_message = [
          "\nAddress can only have one label:",
          "Node: #{node} in position: #{number}",
          "conflicts with: #{conflict} -> #{symbol_table[conflict]}"
        ]
        raise error_message.join("\n")
      end

      offset += 1
      symbol_table[node.name.sub(':', '')] = node.position
    end

    nodes.reject! { |node| node.is_a?(Parser::LabelNode) && symbol_table.keys.include?(node.name) }
    # If there is no address, it is the node's current position - number of (unresolved) label declarations encountered
    # Remove declaration nodes
  end

  # Replaces subroutine names with PC addresses and adds the call's return address
  def resolve_subroutines
    nodes.each_with_index do |node, number|
      next unless node.is_a? Parser::RoutineNode

      node.call = symbol_table[node.call]
      node.return = number + 1
    end
  end
end
