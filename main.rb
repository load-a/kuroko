# frozen_string_literal: true
require_relative 'lexer'
require_relative 'parser'
require_relative 'node_processor'
require_relative 'cpu'

def display_hash(hash)
  count = hash.keys.map {|key| key.to_s.length }.max
  puts hash.map {|key, value| "#{key.to_s.ljust(count)}: #{value}"}
end

puts '--- Tokenizer'

lex = Tokenizer.new(ARGV[0])
lex.tokenize
# lex.display

puts '--- Parser'

par = Parser.new(lex.tokens)
par.parse
puts par.tokens

puts '--- Node Processor', 'NODES'

process = NodeProcessor.new(par.nodes)
process.process

process.nodes.each_with_index do |node, number|
  line = node.inspect.gsub('#<struct Parser::', '<')
  printf '%04i. %s', number, line
  puts
end

puts 'SYMBOL TABLE'
display_hash process.symbol_table

puts '--- CPU'

computer = CPU.new(process.nodes, process.symbol_table)

computer.execute

puts '^ - - output - - ^'
# computer.view_registers
# computer.view_status
# computer.view_stack
# computer.view_ram(:dec, :dec)

computer.display(:hex, :dec)
