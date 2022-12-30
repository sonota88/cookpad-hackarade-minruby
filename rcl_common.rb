require "pp"

class Token
  attr_reader :kind, :value, :lineno

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

def puts_e(*args)
  args.each { |arg| $stderr.puts arg }
end

def p_e(*args)
  args.each { |arg| puts_e arg.inspect }
end

def pp_e(*args)
  args.each { |arg| puts_e arg.pretty_inspect }
end
