std = "luajit+love"

files["**/*.lua"] = {
    globals = {
        "love",
    },
}

exclude_files = {
    ".luarocks/**",
    "_test/**",
    "external/**",
    "lua_modules/**",
    "tmp/**",
}
