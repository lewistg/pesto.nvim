load(":nvim_lua_executable.bzl", "nvim_lua_executable_rule")
load(":rlocation_util.bzl", "get_rlocation_path")

_internal_nvim_lua_test = nvim_lua_executable_rule(
    test = True,
)

def _lua_test_args_impl(ctx):
    args = ctx.actions.declare_file(ctx.label.name)
    srcs = [get_rlocation_path(file) for file in ctx.files.srcs]
    ctx.actions.write(output = args, content = "\n".join(srcs))
    return [DefaultInfo(files = depset([args]))]

lua_test_args = rule(
    implementation = _lua_test_args_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
        ),
    },
)

def _nvim_lua_test_impl(name, entry_point, srcs, **kwargs):
    args_name = name + "_args"

    lua_test_args(
        name = args_name,
        srcs = srcs,
    )

    _internal_nvim_lua_test(
        **(kwargs | {
            "name": name,
            "entry_point": entry_point,
            "entry_point_args": ":" + args_name,
        })
    )

nvim_lua_test = macro(
    implementation = _nvim_lua_test_impl,
    inherit_attrs = _internal_nvim_lua_test,
    attrs = {
        "entry_point": attr.label(
            allow_single_file = True,
            default = "//tools/rules_nvim_lua/lua/test/runner:init.lua",
        ),
        "srcs": attr.label_list(
            allow_files = [".lua"],
        ),
    },
)
