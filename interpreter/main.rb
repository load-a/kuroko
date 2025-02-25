# frozen_string_literal: true

NUMBER_PATTERN = /[+\-]?(0b[01]+|0x[0-9a-f]+|0o[0-7]+|[0-9]+)/i
LABEL_PATTERN = /[_a-z][_a-z0-9]+/i
STRING_PATTERN = /"(?:[^"\\]|\\.)*"/
REGISTER_PATTERN = /\b[abcdhlij]\b/i
REGISTERS = {
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

def display_hash(hash)
  count = hash.keys.map {|key| key.to_s.length }.max
  puts hash.map {|key, value| "#{key.to_s.ljust(count)}: #{value}"}
end

require_relative 'lexer'
require_relative 'tokenizer'
require_relative 'normalizer'
require_relative 'parser'
require_relative 'symbolizer'
require_relative 'cpu'

puts '--LEXER--'
source = File.read ARGV[0]
lexer = Lexer.new(source)
lexer.process
lexer.show_units

puts '--TOKENIZER--'
tokenizer = Tokenizer.new(lexer.units)
tokenizer.tokenize
tokenizer.show_tokens

puts '--NORMALIZER--'
norm = Normalizer.new(tokenizer.tokens)
norm.normalize
puts norm.log

puts '--PARSER--'
par = Parser.new(tokenizer.tokens)
par.parse
par.show_instructions

puts '--SYMBOLIZER--'
sym = Symbolizer.new(par.instructions)
sym.process
puts '- - SYMBOL TABLE - -'
display_hash sym.symbol_table
puts '- - WRITES - -'
display_hash sym.writes
puts '- - REVISIONS - -'
par.show_instructions

puts '--CENTERAL PROCESSING UNIT--'
cpu = CPU.new(par.instructions, sym.symbol_table, sym.writes)
cpu.run
puts '- - Input/Output - -'
cpu.display(:dec, :dec)
