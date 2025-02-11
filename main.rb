# frozen_string_literal: true
require_relative 'lexer'
require_relative 'parser'
require_relative 'cpu'

lex = Tokenizer.new(ARGV[0])
lex.tokenize
lex.display

puts '---'

par = Parser.new(lex.tokens)
par.parse
puts par.nodes

val = par.nodes[0]
