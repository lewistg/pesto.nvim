load("//tools/build-rules/private:nvim_lua_executable_common.bzl", "nvim_lua_executable_rule_impl")
load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")

def _nvim_lua_binary_impl(ctx):
    return nvim_lua_executable_rule_impl(
        ctx = ctx,
        nvim_bin = ctx.file._nvim_bin,
        entry_point = ctx.file.entry_point,
        entry_point_args = [],
        lua_path_roots = ctx.attr.lua_path_roots,
        srcs = ctx.files.srcs,
        deps = ctx.attr.deps,
        run_files_lib = ctx.attr._run_files_lib
    )

nvim_lua_binary = rule(
    implementation = _nvim_lua_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
            allow_empty = False,
        ),
        "deps": attr.label_list(providers = [NvimLuaInfo]),
        "entry_point": attr.label(
            allow_single_file = True,
        ),
        "lua_path_roots": attr.label_list(providers = [NvimLuaPathRootInfo]),
        "_nvim_bin_runner_template": attr.label(
            allow_single_file = True,
            default = "//tools/build-rules/private:nvim_lua.sh.tpl",
        ),
        "_nvim_bin": attr.label(
            allow_single_file = True,
            default = "@nvim//:bin/nvim",
        ),
        "_run_files_lib": attr.label(
            default = "@rules_shell//shell/runfiles",
        )
    },
    executable = True,
)
