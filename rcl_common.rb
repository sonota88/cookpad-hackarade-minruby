require "pp"

class Token
  attr_reader :kind, :value

  # kind:
  #   str:   string
  #   kw:    keyword
  #   int:   integer
  #   sym:   symbol
  #   ident: identifier
  def initialize(kind, value, lineno)
    @kind = kind
    @value = value
    @lineno = lineno
  end

  def to_s
    "(Token kind=#{@kind} value=(_#{@value}_) lineno=#{@lineno})"
  end

  def is(kind, str)
    @kind == kind && @value == str
  end
end

def p_e(*args)
  args.each { |arg| $stderr.puts arg.inspect }
end

def pp_e(*args)
  args.each { |arg| $stderr.puts arg.pretty_inspect }
end
