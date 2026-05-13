#!/usr/bin/env sh
set -eu

rockspec="lua-ui-library-0.1-1.rockspec"

if ! git check-ignore -q "src/generated/tstl/probe.lua"; then
  echo "error: src/generated/tstl must stay ignored by git" >&2
  exit 1
fi

if [ -d "src/generated" ] && [ -n "$(find "src/generated" -type f -print -quit)" ]; then
  echo "error: src/generated contains generated files; setup must not promote TSTL output" >&2
  find "src/generated" -type f >&2
  exit 1
fi

blocked_paths='src/ts|src/types|src/generated|node_modules|lua_modules|tmp|external'
if grep -nE "\"($blocked_paths)(/|\")" "$rockspec" >/tmp/lua-ui-boundary-blocked.$$; then
  echo "error: rockspec must not package TypeScript, generated output, dependencies, or temp paths" >&2
  cat /tmp/lua-ui-boundary-blocked.$$ >&2
  rm -f /tmp/lua-ui-boundary-blocked.$$
  exit 1
fi
rm -f /tmp/lua-ui-boundary-blocked.$$

if grep -nE '= ".*\.lua"' "$rockspec" | grep -v '= "src/lua/lib/' >/tmp/lua-ui-boundary-lua.$$; then
  echo "error: rockspec Lua module paths must point at reviewed runtime Lua under src/lua/lib" >&2
  cat /tmp/lua-ui-boundary-lua.$$ >&2
  rm -f /tmp/lua-ui-boundary-lua.$$
  exit 1
fi
rm -f /tmp/lua-ui-boundary-lua.$$

echo "build and packaging boundaries ok"
