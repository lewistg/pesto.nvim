load("@bazel_skylib//lib:paths.bzl", "paths")
load("//tools/build-rules/private:nvim_lua_executable_common.bzl", "get_runfile_args", "nvim_lua_executable_rule_impl")
load("//tools/build-rules/private:nvim_lua_info.bzl", "NvimLuaInfo")
load("//tools/build-rules/private:nvim_lua_path_root_info.bzl", "NvimLuaPathRootInfo")
load("//tools/build-rules/private:nvim_plugin_info.bzl", "NvimPluginInfo")

XDG_CONFIG_HOME = "xdg/local/config"
XDG_DATA_HOME = "xdg/local/share"
XDG_STATE_HOME = "xdg/local/state"

def _nvim_plugin_e2e_test_impl(ctx):
    spec_file_args = get_runfile_args(ctx, ctx.files.srcs)

    xdg_symlinks = {}
    for plugin in ctx.attr.plugins:
        plugin_files = depset(transitive = [plugin[NvimPluginInfo].lua, plugin[NvimPluginInfo].support_files])
        xdg_symlinks |= _create_plugin_symlinks(plugin, plugin_files)

    return nvim_lua_executable_rule_impl(
        ctx = ctx,
        nvim_bin = ctx.file._nvim_bin,
        entry_point = ctx.file.test_runner_entry_point,
        entry_point_args = spec_file_args,
        srcs = ctx.files.srcs,
        deps = ctx.attr.deps + [ctx.attr.test_runner_deps],
        run_files_lib = ctx.attr._run_files_lib,
        data = ctx.attr.data,
        base_runfiles = ctx.runfiles(root_symlinks = xdg_symlinks),
    )

def _create_plugin_symlinks(plugin, files):
    symlinks = {}
    for file in files.to_list():
        relative_path = paths.relativize(file.path, plugin.label.package)
        symlink_path = paths.join(
            XDG_DATA_HOME,
            "nvim/site/pack/plugins/start",
            plugin.label.name,
            relative_path,
        )
        symlinks[symlink_path] = file
    return symlinks

nvim_plugin_e2e_test = rule(
    implementation = _nvim_plugin_e2e_test_impl,
    executable = True,
    test = True,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".lua"],
            allow_empty = False,
        ),
        "plugins": attr.label_list(
            allow_empty = False,
            providers = [NvimPluginInfo],
        ),
        "deps": attr.label_list(providers = [NvimLuaInfo]),
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
        "data": attr.label_list(
            allow_files = True,
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
)
