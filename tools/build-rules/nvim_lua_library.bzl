load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")

def _nvim_lua_library(ctx):
    transitive_sources = []
    for dep in ctx.attr.deps:
        print(dep)
        nvim_lua_info = dep[NvimLuaInfo]
        transitive_sources += [dep[NvimLuaInfo].sources]

    return [
        DefaultInfo(
            files = depset(ctx.files.srcs),
        ),
        NvimLuaInfo(
            sources = depset(ctx.files.srcs, transitive = transitive_sources),
        ),
    ]

nvim_lua_library = rule(
    implementation = _nvim_lua_library,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
            allow_empty = False,
        ),
        "deps": attr.label_list(
            providers = [NvimLuaInfo],
        ),
    },
)
