#!/bin/bash

set -o errexit

_test() {
  local file="$1"; shift

  bundle exec ruby test.rb $file
}

if [ $# -eq 1 ]; then
  _test test${1}.rb
  exit
fi

_test test1-1.rb
_test test1-2.rb
_test test1-3.rb
_test test1-4.rb

# _test test1-5-1.rb
# _test test1-5-2.rb
# _test test1-5-3.rb
# _test test1-5-4.rb
_test test1-5.rb

# _test test2-1-1.rb
_test test2-1.rb

_test test2-2.rb
_test test2-3.rb
_test test2-4.rb
_test test2-5.rb

# _test test3-1-1.rb
_test test3-1.rb

_test test3-2.rb

# _test test3-3-1.rb
_test test3-3.rb

# _test test3-4-1.rb
# _test test3-4-2.rb
_test test3-4.rb

_test test3-5.rb
_test test4-1.rb

# _test test4-2-1.rb
_test test4-2.rb

_test test4-3.rb
_test test4-4.rb
_test test5-1.rb

# _test test5-2-1.rb
_test test5-2.rb

_test test5-3.rb

# _test test5-4-1.rb
_test test5-4.rb

# _test test6-1-1.rb
# _test test6-1-2.rb
_test test6-1.rb

# _test test6-2-1.rb
# _test test6-2-2.rb
_test test6-2.rb

# _test test6-3-1.rb
# _test test6-3-2.rb
# _test test6-3-3.rb
# _test test6-3-4.rb
_test test6-3.rb

# nil
_test test7-1.rb
# <=, >=
_test test7-2.rb
# require
_test test7-3.rb
# if/case: when句の文が複数
_test test7-4.rb
# case {expr} when ...
_test test7-5.rb
