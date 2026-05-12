std = "luajit+love"

files["**/*.lua"] = {
    globals = {
    },
}

exclude_files = {
    ".luarocks/**",
    "_test/**",
    "external/**",
    "lua_modules/**",
    "tmp/**",
}
