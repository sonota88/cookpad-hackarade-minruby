require "reline"
require "json"
require "pp"

require_relative "my_minruby_parser"
require_relative "my_interp"

PROMPT = ">>> "
HISTORY_FILE = "history"

File.open("debug.log", "wb") { |f| f.write "" } # clear
$log = File.open("debug.log", "a")

def debug(*args)
  $log.puts(*args)
  $log.flush
end

def add_history(text)
  File.open(HISTORY_FILE, "a") { |f| f.puts JSON.generate(text) }
end

def load_history
  return unless File.exist?(HISTORY_FILE)

  File.read(HISTORY_FILE).each_line do |json|
    Reline::HISTORY << JSON.parse(json)
  end
end

def finished?(input)
  stripped = input.strip

  return true if stripped.end_with?(";")
  return true if stripped.split("\n").last == "exit"

  begin
    debug "try parse: input: " + input.pretty_inspect
    # minruby_parse(input.strip)
    MyMinRubyParser.minruby_parse(input)
    debug "parse ... ok"
    return true
  rescue => e
    debug "#{e.class}: #{e.message}"
    debug e.backtrace
    debug "parse ... FAILED"
    return false
  end
end

def sym_to_str(tree)
  tree.map { |it|
    case it
    when Symbol then it.to_s
    when Array  then sym_to_str(it)
    else
      it
    end
  }
end

Reline.prompt_proc =
  Proc.new do |lines|
    lines.each_with_index.map do |line, i|
      i == 0 ? PROMPT : "  | "
    end
  end

load_history

$function_definitions = {
  "p" => ["builtin", "p"],
}

genv = {
  "p" => ["builtin", "p"],
}
lenv = {}

loop do
  # ** read **
  text =
    Reline.readmultiline(PROMPT, true) do |input|
      debug input.inspect

      finished = finished?(input)
      debug "finished (#{finished})"
      finished
    end

  add_history text

  # puts "input: " + text.inspect

  break if text == "exit"

  # tree = minruby_parse(text)
  tree = MyMinRubyParser.minruby_parse(text)
  tree = sym_to_str(tree)
  # puts "tree: " + tree.pretty_inspect

  begin
    # ** eval **
    # puts "env before: " + $lenv.inspect

    result = evaluate(tree, genv, lenv)

    # ** print **
    puts "=> " + result.inspect
  rescue => e
    puts "#{e.class}: #{e.message}"
    puts e.backtrace
    puts ""
  end

  # puts "env after: " + $lenv.inspect
end
