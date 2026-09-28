load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_plugin_info.bzl", "NvimPluginInfo")

def _nvim_plugin_impl(ctx):
    lua_sources = []
    for dep in ctx.attr.lua:
        nvim_lua_info = dep[NvimLuaInfo]
        lua_sources += [nvim_lua_info.sources]

    support_sources = [dep[DefaultInfo].files for dep in ctx.attr.support_files]

    return [
        NvimPluginInfo(
            lua = depset(None, transitive = lua_sources),
            support_files = depset(None, transitive = support_sources),
        )
    ]

nvim_plugin = rule(
    implementation = _nvim_plugin_impl,
    attrs = {
        "lua": attr.label_list(
            providers = [NvimLuaInfo],
        ),
        "support_files": attr.label_list(
            allow_files = True,
        ),
    },
)
