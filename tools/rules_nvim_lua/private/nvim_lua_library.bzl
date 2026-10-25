load(":nvim_lua_info.bzl", "NvimLuaInfo")

def _nvim_lua_library_impl(ctx):
    sources = depset(
        ctx.files.srcs,
        transitive = [dep[NvimLuaInfo].sources for dep in ctx.attr.deps],
    )
    return [
        DefaultInfo(files = sources),
        NvimLuaInfo(sources = sources),
    ]

nvim_lua_library = rule(
    implementation = _nvim_lua_library_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
        ),
        "deps": attr.label_list(
            providers = [NvimLuaInfo],
        ),
    },
)
