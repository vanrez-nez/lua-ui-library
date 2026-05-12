std = "luajit+love"

files["**/*.lua"] = {
    globals = {
    },
}

exclude_files = {
    ".luarocks/**",
    "_test/**",
    "node_modules/**",
    "external/**",
    "lua_modules/**",
    "tmp/**",
}
