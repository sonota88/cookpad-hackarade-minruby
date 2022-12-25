require "minruby"
require "json"

require_relative "my_minruby_parser"

src_file = ARGV[0]
if src_file == "test.rb"
  $stderr.puts "skip"
  exit 0
end

# puts "================================"
puts src_file
minruby_src = File.read(src_file)

ast_e = MinRubyParser.minruby_parse(minruby_src)
ast_a = MyMinRubyParser.minruby_parse(minruby_src)
file_e = "/tmp/minruby_test_e.json"
file_a = "/tmp/minruby_test_a.json"
File.open(file_e, "wb"){ |f| f.write JSON.pretty_generate(ast_e) }
File.open(file_a, "wb"){ |f| f.write JSON.pretty_generate(ast_a) }

out = `diff -u #{file_e} #{file_a}`
status = $?
if status.success?
  # ok
else
  puts minruby_src
  puts `diff -uw #{file_e} #{file_a}`
  $stderr.puts "NG"
  exit 1
end
