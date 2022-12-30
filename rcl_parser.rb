require "json"
require "pp"

require_relative "rcl_common"

class RclParser
  def initialize
    @tokens = nil
    @pos = nil
  end

  def rest_head
    @tokens[@pos...@pos + 8]
      .map { |t| format("%s<%s>", t.kind, t.value) }
  end

  def peek(offset = 0)
    @tokens[@pos + offset]
  end

  def dump_state(msg = nil)
    pp_e [msg, @pos, rest_head]
  end

  def assert_value(pos, exp)
    t = peek()

    if t.value != exp
      msg = format(
        "Assertion failed: expected(%s) actual(%s)",
        exp.inspect,
        t.inspect
      )
      raise msg
    end
  end

  def consume(str)
    assert_value(@pos, str)
    @pos += 1
  end

  def end?
    @tokens.size <= @pos
  end

  def skip_lfs
    while (not end?) && peek().kind == :lf
      consume "\n"
    end
  end

  def parse_arg
    t = peek()

    unless t.kind == :ident
      raise "ident is expected"
    end

    @pos += 1
    t.value
  end

  def parse_args
    args = []

    return args if peek().value == ")"

    args << parse_arg()

    while peek().value == ","
      consume ","
      args << parse_arg()
    end

    args
  end

  def parse_exprs
    exprs = []

    return exprs if peek().value == ")"

    exprs << parse_expr()

    while peek().value == ","
      consume ","
      exprs << parse_expr()
    end

    exprs
  end

  def include_op?(ops, t)
    ops.include?(t.value)
  end

  def parse_expr_factor_int
    n = peek().value.to_i
    @pos += 1

    [:lit, n]
  end

  def parse_func_call
    func_name = peek().value
    @pos += 1

    consume "("
    args = parse_exprs()
    consume ")"

    [:func_call, func_name, *args]
  end

  def parse_expr_factor_ident
    if peek(1).value == "("
      parse_func_call()
    elsif peek(1).value == "["
      parse_expr_array_ref()
    else
      val = peek().value
      @pos += 1
      [:var_ref, val]
    end
  end

  def parse_expr_array_ref
    var_name = peek().value
    @pos += 1

    consume "["
    index = parse_expr()
    consume "]"

    [:ary_ref, [:var_ref, var_name], index]
  end

  def parse_expr_array_new
    consume "["
    xs = []

    if peek().value == "]"
      consume "]"
      return [:ary_new, *xs]
    end

    xs << parse_expr()

    while peek.value == ","
      consume ","
      xs << parse_expr()
    end
    consume "]"

    [:ary_new, *xs]
  end

  def parse_expr_hash_new_kv
    k = parse_expr()
    consume "=>"
    v = parse_expr()
    [k, v]
  end

  def parse_expr_hash_new
    consume "{"
    xs = []

    if peek().value == "}"
      consume "}"
      return [:hash_new, *xs]
    end

    xs += parse_expr_hash_new_kv()

    while peek.value == ","
      consume ","
      xs += parse_expr_hash_new_kv()
    end

    consume "}"

    [:hash_new, *xs]
  end

  def parse_expr_factor_sym
    case peek().value
    when "("
      consume "("
      cond_expr = parse_expr()
      consume ")"
      cond_expr
    when "["
      parse_expr_array_new()
    when "{"
      parse_expr_hash_new()
    else
      raise "unexpected token"
    end
  end

  def parse_expr_factor_kw
    case peek().value
    when "true"
      @pos += 1
      [:lit, true]
    when "false"
      @pos += 1
      [:lit, false]
    when "nil"
      @pos += 1
      [:lit, nil]
    else
      raise "unexpected token"
    end
  end

  def parse_expr_factor_str
    str = peek().value
    @pos += 1

    [:lit, str]
  end

  def parse_expr_factor
    case peek().kind
    when :int   then parse_expr_factor_int()
    when :ident then parse_expr_factor_ident()
    when :sym   then parse_expr_factor_sym()
    when :kw    then parse_expr_factor_kw()
    when :str   then parse_expr_factor_str()
    else
      raise "unexpected token kind"
    end
  end

  def parse_expr_prec_10
    expr = parse_expr_factor()

    while include_op?(%(* / %), peek())
      op = peek().value
      @pos += 1

      factor = parse_expr_factor()

      expr = [op.to_sym, expr, factor]
    end

    expr
  end

  def parse_expr_prec_20
    expr = parse_expr_prec_10()

    while include_op?(%(+ -), peek())
      op = peek().value
      @pos += 1

      factor = parse_expr_prec_10()

      expr = [op.to_sym, expr, factor]
    end

    expr
  end

  def parse_expr_prec_30
    expr = parse_expr_prec_20()

    while include_op?(%(< >), peek())
      op = peek().value
      @pos += 1

      factor = parse_expr_prec_20()

      expr = [op.to_sym, expr, factor]
    end

    expr
  end

  def parse_expr_prec_40
    expr = parse_expr_prec_30()

    while include_op?(%(== !=), peek())
      op = peek().value
      @pos += 1

      factor = parse_expr_prec_30()

      expr = [op.to_sym, expr, factor]
    end

    expr
  end

  def parse_expr_prec_50
    expr = parse_expr_prec_40()

    while include_op?(%(=), peek())
      op = peek().value
      @pos += 1

      factor = parse_expr_prec_40()

      expr = [op.to_sym, expr, factor]
    end

    case expr
    in [:"=", [:var_ref, var_name], rhs]
      expr = [:var_assign, var_name, rhs]
    in [:"=", [:ary_ref, var_ref, index], rhs]
      expr = [:ary_assign, var_ref, index, rhs]
    else
      ;
    end

    expr
  end

  def parse_expr
    expr = parse_expr_prec_50()
    skip_lfs()
    expr
  end

  def parse_while
    consume "while"

    cond_expr = parse_expr()

    stmts = parse_stmts()
    consume "end"

    if stmts.size == 0
      :TODO
    elsif stmts.size == 1
      [:while, cond_expr, stmts[0]]
    elsif stmts.size >= 2
      [:while, cond_expr, [:stmts, *stmts]]
    else
      raise "must not happen"
    end
  end

  def parse_when_clause
    case peek().value
    when "when"
      consume "when"
      cond_expr = parse_expr()
    when "else"
      consume "else"
      cond_expr = 1 # true
    else
      raise "unexpected token"
    end

    stmts = parse_stmts()

    [cond_expr, *stmts]
  end

  def parse_case
    consume "case"

    when_clauses = []

    skip_lfs()
    while peek().value != "end"
      when_clauses << parse_when_clause()
      skip_lfs()
    end

    consume "end"
    skip_lfs()

    stmt =
      if when_clauses.size == 2
        [
          :if,
          when_clauses[0][0],      # cond
          when_clauses[0][1..][0], # then
          when_clauses[1][1..][0]  # else
        ]
      else
        :TODO
      end

    stmt
  end

  def parse_stmt
    skip_lfs()
    return nil if end?

    case peek().value
    when "while"  then parse_while()
    when "case"   then parse_case()
    else
      parse_expr()
    end
  end

  def parse_stmts
    stmts = []

    skip_lfs()
    until (
      end? ||
      peek().value == "end" ||
      peek().value == "when" ||
      peek().value == "else"
    )
      stmt = parse_stmt()
      stmts << stmt unless stmt.nil?
      skip_lfs()
    end

    stmts
  end

  def parse_func
    consume "def"

    t = peek()
    @pos += 1
    func_name = t.value

    consume "("
    args = parse_args()
    consume ")"

    stmts = parse_stmts()

    consume "end"

    if stmts.size == 0
      :TODO
    elsif stmts.size == 1
      [:func_def, func_name, args, stmts[0]]
    elsif stmts.size >= 2
      [:func_def, func_name, args, [:stmts, *stmts]]
    else
      raise "must not happen"
    end
  end

  def parse_top_stmt
    skip_lfs()
    return nil if end?

    case peek().value
    when "def" then parse_func()
    else
      parse_stmt()
    end
  end

  def parse_top_stmts
    stmts = []

    until end?
      stmt = parse_top_stmt()
      stmts << stmt unless stmt.nil?
    end

    stmts =
      if stmts.size == 0
        :TODO
      elsif stmts.size == 1
        stmts[0]
      elsif stmts.size >= 2
        [:stmts, *stmts]
      else
        raise "must not happen"
      end

    stmts
  end

  def parse(tokens)
    @tokens = tokens
    @pos = 0

    begin
      ast = parse_top_stmts()
    rescue => e
      dump_state()
      raise e
    end

    ast
  end

  def self.parse(tokens)
    RclParser.new.parse(tokens)
  end
end