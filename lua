#!/bin/sh

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

LUA_UI_LIBRARY_ROOT="$ROOT" exec luajit -e 'local root = os.getenv("LUA_UI_LIBRARY_ROOT")
package.path = root .. "/lua_modules/share/lua/5.1/?.lua;" ..
    root .. "/lua_modules/share/lua/5.1/?/init.lua;" ..
    root .. "/src/lua/?.lua;" ..
    root .. "/src/lua/?/init.lua;" ..
    root .. "/?.lua;" ..
    root .. "/?/init.lua;" ..
    package.path
package.cpath = root .. "/lua_modules/lib/lua/5.1/?.so;" .. package.cpath' \
  $([ "$*" ] || echo -i) "$@"
