NvimLuaPathRoot = provider(
    doc = "Marks a directory as a root for LUA_PATH",
)

def _nvim_lua_path_root_impl(ctx):
    return [NvimLuaPathRoot()]

nvim_lua_path_root = rule(
    implementation = _nvim_lua_path_root_impl
)
