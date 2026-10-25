load(":nvim_lua_info.bzl", "NvimLuaInfo")
load(":nvim_lua_path_root.bzl", "NvimLuaPathRoot")
load(":rlocation_util.bzl", "get_rlocation_path")

BASE_EXECUTABLE_RULE_ATTRS = {
    "entry_point": attr.label(
        allow_single_file = True,
        mandatory = True,
    ),
    "entry_point_args": attr.label(
        allow_single_file = True,
    ),
    "lua_path_roots": attr.label_list(
        providers = [NvimLuaPathRoot],
    ),
    "srcs": attr.label_list(
        allow_files = [".lua"],
    ),
    "deps": attr.label_list(
        providers = [NvimLuaInfo],
    ),
    "_nvim_bin_runner_template": attr.label(
        allow_single_file = True,
        default = ":nvim_lua.sh.tpl",
    ),
    "_nvim_bin": attr.label(
        allow_single_file = True,
        default = "@nvim//:bin/nvim",
    ),
    "_runfiles_lib": attr.label(
        default = "@rules_shell//shell/runfiles",
    ),
}

def _nvim_lua_executable_impl(ctx):
    entry_point_args = get_rlocation_path(ctx.file.entry_point_args) if ctx.file.entry_point_args else ""

    lua_paths = [
        target.label.repo_name or "_main" + "/" + target.label.package
        for target in ctx.attr.lua_path_roots
    ]

    runner = ctx.actions.declare_file(ctx.label.name + "_runner.sh")
    ctx.actions.expand_template(
        template = ctx.file._nvim_bin_runner_template,
        output = runner,
        substitutions = {
            "{{NVIM_BIN}}": get_rlocation_path(ctx.file._nvim_bin),
            "{{ENTRY_POINT}}": get_rlocation_path(ctx.file.entry_point),
            "{{ENTRY_POINT_ARGS}}": entry_point_args,
            "{{LUA_PATH_ROOTS}}": "\n".join(lua_paths),
        },
    )

    dep_sources = depset(None, transitive = [dep[NvimLuaInfo].sources for dep in ctx.attr.deps])
    print(dep_sources)

    files = [
        ctx.file.entry_point,
        ctx.file._nvim_bin,
    ] + ctx.files.srcs
    if ctx.file.entry_point_args:
        files.append(ctx.file.entry_point_args)

    runfiles = ctx.runfiles(files = files, transitive_files = dep_sources)
    runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles)

    print(runfiles)

    return [DefaultInfo(
        executable = runner,
        runfiles = runfiles,
    )]

def nvim_lua_executable_rule(test = False):
    return rule(
        implementation = _nvim_lua_executable_impl,
        attrs = BASE_EXECUTABLE_RULE_ATTRS,
        executable = True,
        test = test,
    )
