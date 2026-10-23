def _get_rlocation_path(file):
    runfile_path = file.short_path
    if runfile_path.startswith("../"):
        return runfile_path[3:]
    else:
        return "_main" + "/" + runfile_path

def _nvim_lua_binary_impl(ctx):
    runner = ctx.actions.declare_file(ctx.label.name + "_runner.sh")
    ctx.actions.expand_template(
        template = ctx.file._nvim_bin_runner_template,
        output = runner,
        substitutions = {
            "{{NVIM_BIN}}": _get_rlocation_path(ctx.file._nvim_bin),
            "{{ENTRY_POINT}}": _get_rlocation_path(ctx.file.entry_point),
        },
    )

    runfiles = ctx.runfiles(files = [ctx.file.entry_point, ctx.file._nvim_bin])
    runfiles = runfiles.merge(ctx.attr._runfiles_lib[DefaultInfo].default_runfiles)

    return [DefaultInfo(
        executable = runner,
        runfiles = runfiles,
    )]

nvim_lua_binary = rule(
    implementation = _nvim_lua_binary_impl,
    attrs = {
        "entry_point": attr.label(
            allow_single_file = True,
            mandatory = True,
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
    },
    executable = True,
)
