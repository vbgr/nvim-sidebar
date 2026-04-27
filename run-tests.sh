#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if [ ! -x ./.luarocks/bin/luacov ]; then
  echo "LuaCov is not installed in .luarocks."
  echo "Run: luarocks-5.1 --tree .luarocks make --only-deps nvim-sidebar-dev-1-1.rockspec"
  exit 1
fi

mkdir -p coverage

echo "Running test suite..."
nvim --headless -u NONE -i NONE -l tests/all.lua

echo "Running coverage suite..."
nvim --headless -u NONE -i NONE -l tests/coverage.lua

echo "Generating HTML coverage report..."
./.luarocks/bin/luacov -c .luacov-html -r html

echo "Coverage reports written to coverage/"
