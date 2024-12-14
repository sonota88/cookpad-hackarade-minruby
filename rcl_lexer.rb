require_relative "rcl_common"

class RclLexer
  KEYWORDS = %w[
    def end return case when if while
    break
    true false
    nil
  ]

  def tokenize(src)
    tokens = []

    pos = 0
    lineno = 1

    while pos < src.size
      rest = src[pos..]

      case rest
      when /\A( +)/
        str = $1
        pos += str.size
      when /\A(\n)/
        str = $1
        tokens << Token.new(:lf, str, lineno)
        pos += str.size
        lineno += 1
      when /\A(#.*)$/
        str = $1
        pos += str.size
      when /\A"(.*?)"/
        str = $1
        tokens << Token.new(:str, str, lineno)
        pos += str.size + 2
      when /\A(-?[0-9]+)/
        str = $1
        tokens << Token.new(:int, str.to_i, lineno)
        pos += str.size
      when /\A(==|!=|=>|<=|>=|~~|[<>(){}\[\]=;+\-*\/%,&])/
        str = $1
        tokens << Token.new(:sym, str, lineno)
        pos += str.size
      when /\A([A-Za-z_][A-Za-z0-9_]*\??)/
        str = $1
        if str == "if"
          tokens << Token.new(:kw, "case", lineno)
          tokens << Token.new(:kw, "when", lineno)
        else
          kind = KEYWORDS.include?(str) ? :kw : :ident
          tokens << Token.new(kind, str, lineno)
        end
        pos += str.size
      else
        p_e rest[0...100]
        raise "unexpected pattern (lineno=#{lineno})"
      end
    end

    tokens
  end

  def self.lex(src)
    RclLexer.new.tokenize(src)
  end
end
