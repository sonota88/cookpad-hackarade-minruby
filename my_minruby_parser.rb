require_relative "rcl_common"
require_relative "rcl_lexer"
require_relative "rcl_parser"

class MyMinRubyParser
  def self.minruby_parse(src)
    tokens = RclLexer.lex(src)
    # pp_e tokens; exit
    RclParser.parse(tokens)
  end
end

if $0 == __FILE__
  src = ARGF.read
  ast = MyMinRubyParser.minruby_parse(src)
  puts ast.pretty_inspect
end
