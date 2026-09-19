load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")

def _nvim_lua_library(ctx):
    transitive_lua_path_roots = []
    transitive_sources = []
    for dep in ctx.attr.deps:
        nvim_lua_info = dep[NvimLuaInfo]
        transitive_sources += [nvim_lua_info.sources]
        transitive_lua_path_roots += [nvim_lua_info.lua_path_roots]

    runfiles = ctx.runfiles(ctx.attr.data)
    runfiles = runfiles.merge_all([dep[DefaultInfo].default_runfiles for dep in ctx.attr.deps])

    lua_path_roots = depset([ctx.attr.lua_path_root], transitive = transitive_lua_path_roots)

    return [
        DefaultInfo(
            files = depset(ctx.files.srcs),
            runfiles = runfiles,
        ),
        NvimLuaInfo(
            sources = depset(ctx.files.srcs, transitive = transitive_sources),
            lua_path_roots = lua_path_roots
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
        "data": attr.label_list(
            allow_files = True,
        ),
        "lua_path_root": attr.label(
            providers = [NvimLuaPathRootInfo],
            mandatory = True
        )
    },
)
