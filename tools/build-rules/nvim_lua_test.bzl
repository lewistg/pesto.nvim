load("//tools/build-rules/private:nvim_lua_executable_common.bzl", "get_runfile_args", "nvim_lua_executable_rule_impl")
load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")

def _nvim_lua_test_impl(ctx):
    spec_file_args = get_runfile_args(ctx, ctx.files.srcs)

    return nvim_lua_executable_rule_impl(
        ctx = ctx,
        nvim_bin = ctx.file._nvim_bin,
        entry_point = ctx.file.test_runner_entry_point,
        entry_point_args = spec_file_args,
        lua_path_roots = ctx.attr.lua_path_roots + ctx.attr.test_runner_lua_path_roots,
        srcs = ctx.files.srcs,
        deps = ctx.attr.deps + [ctx.attr.test_runner_deps],
        run_files_lib = ctx.attr._run_files_lib,
    )

nvim_lua_test = rule(
    implementation = _nvim_lua_test_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
            allow_empty = False,
        ),
        "deps": attr.label_list(providers = [NvimLuaInfo]),
        "lua_path_roots": attr.label_list(providers = [NvimLuaPathRootInfo]),
        "test_runner_entry_point": attr.label(
            allow_single_file = True,
            default = "//tools/build-rules/lua/rules_nvim_lua/test/runner:init.lua",
        ),
        "test_runner_deps": attr.label(
            allow_single_file = True,
            providers = [NvimLuaInfo],
            default = "//tools/build-rules/lua/rules_nvim_lua/test/runner",
        ),
        "test_runner_lua_path_roots": attr.label_list(
            providers = [NvimLuaPathRootInfo],
            default = ["//tools/build-rules/lua:lua"],
        ),
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
        ),
    },
    executable = True,
    test = True,
)
