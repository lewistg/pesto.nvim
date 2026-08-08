load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")

def _nvim_lua_path_root_impl(ctx):
    return [
        NvimLuaPathRootInfo(),
    ]

nvim_lua_path_root = rule(
    implementation = _nvim_lua_path_root_impl,
)
